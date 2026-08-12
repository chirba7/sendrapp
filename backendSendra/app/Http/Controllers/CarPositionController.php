<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreCarPositionRequest;
use App\Http\Resources\SignalementRessource;
use App\Models\CarPhoto;
use App\Models\CarPosition;
use Carbon\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;

class CarPositionController extends Controller
{

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreCarPositionRequest $request)
    {
        $carPosition = new CarPosition();
        $carPosition->latitude = $request->latitude;
        $carPosition->longitude = $request->longitude;
        $carPosition->title = $request->titre;
        $carPosition->commune = $request->commune;
        $carPosition->user_id = Auth::user()->id;

        if ($carPosition->save()) {
            // Décodez l'image base64 en binaire
            $imageBinary = base64_decode($request->input('image'));

            // Générez un nom de fichier unique
            $filename = uniqid('car_photo') . '.png';

            // Enregistrez l'image dans le stockage Laravel (dans ce cas, public/storage)
            Storage::disk('public')->put('signalement/photo/' . $filename, $imageBinary);

            // Enregistrez le chemin de l'image dans la base de données
            $carPhoto = new CarPhoto();
            $carPhoto->card_id = $carPosition->id;
            $carPhoto->filepath = 'signalement/photo/' . $filename;
            $carPhoto->save();

            // Réponse JSON en cas de succès
            return response()->json(['message' => 'Signalisation effectuée avec succès'], 200);
        } else {
            // Réponse JSON en cas d'échec
            return response()->json(['message' => 'Erreur lors de la signalisation'], 500);
        }
    }

    // public function store(Request $request)
    // {
    //     // Validation des données de la requête
    //     $request->validate([
    //         'titre' => 'required|string',
    //         'commune' => 'required|string',
    //         'latitude' => 'required|numeric',
    //         'longitude' => 'required|numeric',
    //         'image' => 'required|string', // Assurez-vous que l'image est envoyée en tant que chaîne base64
    //     ]);

    //     // Création d'une nouvelle position de voiture
    //     $carPosition = new CarPosition();
    //     $carPosition->latitude = $request->latitude;
    //     $carPosition->longitude = $request->longitude;
    //     $carPosition->title = $request->titre;
    //     $carPosition->commune = $request->commune;
    //     $carPosition->userid = Auth::user()->id;

    //     // Sauvegarde de la position de la voiture
    //     if ($carPosition->save()) {
    //         // Décodez l'image base64 en binaire
    //         $imageBinary = base64_decode($request->input('image'));

    //         // Générez un nom de fichier unique
    //         $filename = uniqid('car_photo') . '.png';

    //         // Enregistrez l'image dans le stockage Laravel (dans ce cas, public/storage)
    //         Storage::disk('public')->put('signalement/photo/' . $filename, $imageBinary);

    //         // Enregistrez le chemin de l'image dans la base de données
    //         $carPhoto = new CarPhoto();
    //         $carPhoto->card_id = $carPosition->id;
    //         $carPhoto->filepath = 'signalement/photo/' . $filename;
    //         $carPhoto->save();

    //         // Réponse JSON en cas de succès
    //         return response()->json(['message' => 'Signalisation effectuée avec succès'], 200);
    //     } else {
    //         // Réponse JSON en cas d'échec
    //         return response()->json(['message' => 'Erreur lors de la signalisation'], 500);
    //     }
    // }
    /**
     * Remove the specified resource from storage.
     */
    public function destroy(CarPosition $carPosition)
    {
        $carPosition->is_deleted = true;
        $carPosition->update();

        return response()->json(['Signalisation supprimée avec success']);
    }

    public function voirSignalements()
    {
        $signalement = CarPosition::where([['user_id', Auth::user()->id], ['is_deleted', false]])
            ->with('photo')
            ->orderBy('created_at', 'desc')
            ->get();
        // return response()->json($signalement);
        return response()->json(SignalementRessource::collection($signalement));
    }

    public function listerSignalements()
    {

        $dateActuelle = Carbon::now();
        $dateLimite = $dateActuelle->subDays(10)->toDateString();

        $signalement = CarPosition::where('is_deleted', false)
            ->whereDate('created_at', '>=', $dateLimite)
            ->with('photo')
            ->orderBy('created_at', 'desc')
            ->paginate(10);
        // dd($signalement);
        // return response()->json($signalement);
        return SignalementRessource::collection($signalement);
    }

    public function statistiques()
    {
        return response()->json(
            [
                'signalements' => count(CarPosition::all()),
                'signales' => count(CarPosition::where('etat', 'SIGNALE')->get()),
                'enleves' => count(CarPosition::where('etat', 'ENLEVE')->get()),
                'encours' => count(CarPosition::where('etat', 'EN COURS')->get())
            ]
        );
    }

    public function listerSignalement(CarPosition $carPosition)
    {
        $signalement = CarPosition::where('id', $carPosition->id)->with('photo')->get();
        return SignalementRessource::collection($signalement);
    }
}
