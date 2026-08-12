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

        // Validate credentials
        if (empty($this->login) || empty($this->token) || empty($this->apiAccessKey)) {
            throw new \InvalidArgumentException('Orange SMS credentials are not properly set in the .env file.');
        }
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

                // Log the response
            Log::info('SMS API Response', [
                'status' => $response->status(),
                'body' => $response->body(),
                'json' => $response->json(),
                'headers' => $response->headers(),
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
            // Log the error
            Log::error('SMS sending failed', [
                'error' => $e->getMessage(),
                'params' => $params,
            ]);

            return [
                'success' => false,
                'message' => 'An error occurred while sending SMS.',
                'error' => $e->getMessage(),
            ];
        }
    }

}
