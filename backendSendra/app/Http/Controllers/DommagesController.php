<?php

namespace App\Http\Controllers;

use App\Models\CarPosition;
use App\Models\User;
use App\Support\ImageOptimizer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;

class DommagesController extends Controller
{
    public function enregistrerDommages(Request $request, CarPosition $carPosition)
    {
        // Correction perf : aucune limite de taille sur le payload base64
        // entrant (vecteur de gonflement du stockage / requêtes lentes).
        // ~15M caractères ≈ 11 Mo décodés, largement suffisant pour une
        // signature/composite dessiné(e) sur une image de constatation.
        $request->validate([
            'signature' => 'required|string|max:15000000',
        ]);


        // Extraction des données de l'image en base64
        $dataUrl = $request->input('signature');
        list($type, $data) = explode(';', $dataUrl);
        list(, $data) = explode(',', $data);

        // Décodage de l'image base64
        $imageBinary = base64_decode($data);

        // Redimensionnement défensif : le canvas mobile/web est déjà borné
        // en taille, mais on cappe quand même pour éviter qu'une image
        // anormalement grande ne parte telle quelle sur le disque (JPEG si
        // le build GD le supporte, sinon PNG).
        $optimized = ImageOptimizer::resize($imageBinary, 1600, 88);
        $imageBinary = $optimized['binary'];

        // Génération d'un nom de fichier unique pour l'image
        $filename = uniqid('dommages') . '.' . $optimized['extension'];

        // Sauvegarde de l'image dans le stockage Laravel (dossier public/storage/dommages)
        Storage::disk('public')->put('dommages/' . $filename, $imageBinary);

        // Mise à jour de l'enregistrement du signalement avec le nom de fichier de l'image
        $carPosition->dommage_image = $filename;
        $carPosition->update();

        // Tant que l'administration n'a pas statué, chaque validation des
        // dommages représente une demande (ou une nouvelle version) à
        // examiner. Se baser sur la seule présence d'une ancienne image
        // empêchait toute notification lors d'une correction ultérieure.
        //
        // Correction : l'envoi (Mail::send, SMTP Brevo) se faisait de façon
        // synchrone dans la requête — le temps de connexion/handshake SMTP
        // pouvait dépasser le timeout HTTP de l'app mobile, qui affichait
        // alors à tort "Impossible de joindre le serveur" alors que les
        // dommages étaient bien enregistrés. dispatch()->afterResponse()
        // renvoie la réponse au client immédiatement ; l'e-mail part juste
        // après, sans bloquer la requête (fonctionne sans worker de file
        // d'attente dédié, contrairement à ->queue()).
        $demandeApprobation = !$carPosition->is_approve;
        if ($demandeApprobation) {
            dispatch(function () use ($carPosition) {
                $this->notifierAdministrateurs($carPosition);
            })->afterResponse();
        }

        return response()->json([
            'message' => $demandeApprobation
                ? 'Les dommages ont été enregistrés. Une demande d’approbation a été envoyée à l’administration.'
                : 'Les dommages ont été enregistrés avec succès.',
            'dommage_image' => $filename,
            'signalement' => $carPosition,
        ], 200);
    }

    private function notifierAdministrateurs(CarPosition $carPosition): bool
    {
        $emails = User::query()
            ->where('role_id', 1)
            ->whereNotNull('email')
            ->pluck('email')
            ->filter()
            ->unique();

        if ($emails->isEmpty()) {
            Log::warning('Demande d’approbation non envoyée : aucun administrateur avec e-mail.', [
                'signalement_id' => $carPosition->id,
            ]);
            return false;
        }

        try {
            $backofficeUrl = rtrim(config('services.sendra.backoffice_url'), '/');
            $detailsUrl = "{$backofficeUrl}/dashboard/signalement/{$carPosition->id}";

            Mail::send(
                [
                    'html' => 'emails.approval-request',
                    'text' => 'emails.approval-request-text',
                ],
                [
                    'signalement' => $carPosition,
                    'detailsUrl' => $detailsUrl,
                ],
                function ($message) use ($emails, $carPosition) {
                    $message->to($emails->all())
                        ->subject("Sendra — demande d’approbation n° {$carPosition->id}");
                }
            );
            return true;
        } catch (\Throwable $exception) {
            // La saisie des dommages reste enregistrée même si le serveur
            // mail est momentanément indisponible.
            Log::error('Échec de l’envoi de la demande d’approbation.', [
                'signalement_id' => $carPosition->id,
                'exception' => $exception->getMessage(),
            ]);
            return false;
        }
    }

     // Méthode pour voir les détails d'un signalement
     public function voirDommages(Request $request, $vehicleId)
     {

         // Rechercher le signalement associé à l'ID du véhicule
         $carPosition = CarPosition::where('id', $vehicleId)->first();

         if (!$carPosition) {
             // Retourner une erreur si le signalement n'est pas trouvé
             return response()->json([
                 'message' => 'Aucun signalement trouvé pour ce véhicule.',
             ], 404);
         }
         // Correction : config('app.url') vaut 'localhost' côté serveur,
         // injoignable depuis un téléphone — même bug déjà corrigé pour les
         // photos de signalement dans SignalementRessource. On utilise
         // l'hôte réellement appelé par le client (ex. l'IP LAN du backend
         // Docker, ou le domaine public en prod).
         $dommage_url = $request->getSchemeAndHttpHost() . '/storage/dommages/';
         // Vérifier si le champ dommages existe et le retourner
         $dommages = $carPosition->dommage_image; // Assurez-vous que le champ s'appelle bien 'dommage_image'
         $dommages = $dommage_url.$dommages;

         return response()->json([
             'message' => 'Détails des dommages récupérés avec succès.',
             'dommages' => $dommages,
         ], 200);
     }
     

   

}
