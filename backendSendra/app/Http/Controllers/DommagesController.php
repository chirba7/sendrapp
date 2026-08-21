<?php

namespace App\Http\Controllers;

use App\Models\CarPosition;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;

class DommagesController extends Controller
{
    public function enregistrerDommages(Request $request, CarPosition $carPosition)
    {
        $request->validate([
            'signature' => 'required|string',
        ]);


        // Extraction des données de l'image en base64
        $dataUrl = $request->input('signature');
        list($type, $data) = explode(';', $dataUrl);
        list(, $data) = explode(',', $data);

        // Décodage de l'image base64
        $imageBinary = base64_decode($data);

        // Génération d'un nom de fichier unique pour l'image
        $filename = uniqid('dommages') . '.png';

        // Sauvegarde de l'image dans le stockage Laravel (dossier public/storage/dommages)
        Storage::disk('public')->put('dommages/' . $filename, $imageBinary);

        // Une nouvelle saisie déclenche une seule demande d'approbation. Une
        // correction ultérieure du dessin ne doit pas inonder les admins.
        $premiereSoumission = empty($carPosition->dommage_image);

        // Mise à jour de l'enregistrement du signalement avec le nom de fichier de l'image
        $carPosition->dommage_image = $filename;
        $carPosition->update();

        if ($premiereSoumission) {
            $this->notifierAdministrateurs($carPosition);
        }

        return response()->json([
            'message' => $premiereSoumission
                ? 'Les dommages ont été enregistrés. Une demande d’approbation a été envoyée à l’administration.'
                : 'Les dommages ont été mis à jour avec succès.',
            'dommage_image' => $filename,
            'signalement' => $carPosition,
        ], 200);
    }

    private function notifierAdministrateurs(CarPosition $carPosition): void
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
            return;
        }

        try {
            Mail::raw(
                "Une nouvelle constatation est en attente d’approbation.\n\n"
                . "Signalement n° {$carPosition->id}\n"
                . "Titre : {$carPosition->title}\n"
                . "Commune : {$carPosition->commune}\n\n"
                . "Connectez-vous au back-office Sendra pour examiner les dommages et valider ou rejeter la demande.",
                function ($message) use ($emails, $carPosition) {
                    $message->to($emails->all())
                        ->subject("Sendra — demande d’approbation n° {$carPosition->id}");
                }
            );
        } catch (\Throwable $exception) {
            // La saisie des dommages reste enregistrée même si le serveur
            // mail est momentanément indisponible.
            Log::error('Échec de l’envoi de la demande d’approbation.', [
                'signalement_id' => $carPosition->id,
                'exception' => $exception->getMessage(),
            ]);
        }
    }

     // Méthode pour voir les détails d'un signalement
     public function voirDommages($vehicleId)
     {
      
         // Rechercher le signalement associé à l'ID du véhicule
         $carPosition = CarPosition::where('id', $vehicleId)->first();
     
         if (!$carPosition) {
             // Retourner une erreur si le signalement n'est pas trouvé
             return response()->json([
                 'message' => 'Aucun signalement trouvé pour ce véhicule.',
             ], 404);
         }
         // Correction API-M-4 : URL de production codée en dur.
         $dommage_url = config('app.url') . '/storage/dommages/';
         // Vérifier si le champ dommages existe et le retourner
         $dommages = $carPosition->dommage_image; // Assurez-vous que le champ s'appelle bien 'dommage_image'
         $dommages = $dommage_url.$dommages;
     
         return response()->json([
             'message' => 'Détails des dommages récupérés avec succès.',
             'dommages' => $dommages,
         ], 200);
     }
     

   

}
