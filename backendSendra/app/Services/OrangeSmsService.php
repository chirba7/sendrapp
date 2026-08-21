<?php

namespace App\Services;

use Exception;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use App\Models\UserVerificationCode;

class OrangeSmsService
{
    protected $login;
    protected $apiAccessKey;
    protected $token;
    protected $baseUri;

    public function __construct()
    {
        $this->login = env('ORANGE_SMS_LOGIN', '');
        $this->apiAccessKey = env('ORANGE_SMS_API_KEY', '');
        $this->token = env('ORANGE_SMS_TOKEN', '');
        $this->baseUri = env('ORANGE_SMS_BASE_URI', 'https://api.orangesmspro.sn:8443/api');

        // Correction (découverte en testant les autres correctifs) :
        // valider les identifiants ici faisait planter (500) TOUTE route
        // qui instancie AuthControllerApi — y compris celles qui n'envoient
        // aucun SMS (ex. checkPhone) — dès que ORANGE_SMS_* n'est pas
        // configuré. La validation est déplacée dans sendSms(), au moment
        // où elle est réellement nécessaire.
    }

    /**
     * Send an SMS using Orange SMS API.
     *
     * @param string $subject
     * @param string $signature
     * @param string $recipient
     * @param string $content
     * @return array
     */
    public function sendSms(string $subject, string $signature, string $recipient, string $content): array
    {
        if (empty($this->login) || empty($this->token) || empty($this->apiAccessKey)) {
            return [
                'success' => false,
                'message' => 'Les identifiants Orange SMS ne sont pas configurés.',
            ];
        }

        try {
            // Generate timestamp
            $timestamp = time();

            // Create the HMAC key for authentication
            $msgToEncrypt = $this->token . $subject . $signature . $recipient . $content . $timestamp;
            $key = hash_hmac('sha1', $msgToEncrypt, $this->apiAccessKey);

            // Prepare request parameters
            $params = [
                'token' => $this->token,
                'subject' => $subject,
                'signature' => $signature,
                'recipient' => $recipient,
                'content' => $content,
                'timestamp' => $timestamp,
                'key' => $key,
            ];

            // Send the request using Laravel's Http client
            $response = Http::asForm()
                ->withBasicAuth($this->login, $this->token)
                ->post($this->baseUri, $params);

                // Correction API-M-5 : logué en debug (pas info) pour ne pas
                // s'activer par défaut en prod (LOG_LEVEL=info désormais).
            Log::debug('SMS API Response', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);


            if ($response->successful()) {
                return [
                    'success' => true,
                    'message' => 'SMS sent successfully!',
                    'data' => $response->json(),
                ];
            }

            return [
                'success' => false,
                'message' => 'Failed to send SMS.',
                'error' => $response->json(),
            ];
        } catch (Exception $e) {
            // Correction API-M-5 : $params contenait 'token' et 'key'
            // (identifiants d'authentification Orange SMS) journalisés en
            // clair sur toute erreur.
            Log::error('SMS sending failed', [
                'error' => $e->getMessage(),
                'recipient' => $params['recipient'] ?? null,
            ]);

            return [
                'success' => false,
                'message' => 'An error occurred while sending SMS.',
                'error' => $e->getMessage(),
            ];
        }
    }

}
