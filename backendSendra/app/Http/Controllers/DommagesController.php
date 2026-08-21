<?php

namespace App\Http\Controllers;

use App\Models\CarPosition;
use Illuminate\Http\Request;
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

        // Mise à jour de l'enregistrement du signalement avec le nom de fichier de l'image
        $carPosition->dommage_image = $filename;
        $carPosition->update();

        return response()->json([
            'message' => 'Les dommages ont été enregistrés avec succès.',
            'dommage_image' => $filename,
            'signalement' => $carPosition,
        ], 200);
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
