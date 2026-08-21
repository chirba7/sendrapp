<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreCarPositionRequest;
use App\Http\Resources\SignalementRessource;
use App\Models\CarPhoto;
use App\Models\CarPosition;
use Carbon\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class CarPositionController extends Controller
{

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreCarPositionRequest $request)
    {
        // Correction API-H-3 : le base64 n'était jamais vérifié comme étant
        // une image réelle avant écriture disque, et CarPosition/CarPhoto
        // étaient sauvegardés en deux temps sans transaction (un signalement
        // sans photo pouvait rester en base si l'écriture du fichier échouait).
        $imageBinary = base64_decode($request->input('image'), true);

        if ($imageBinary === false || @getimagesizefromstring($imageBinary) === false) {
            return response()->json(['message' => 'Le fichier fourni n\'est pas une image valide'], 422);
        }

        try {
            $carPhoto = DB::transaction(function () use ($request, $imageBinary) {
                $carPosition = new CarPosition();
                $carPosition->latitude = $request->latitude;
                $carPosition->longitude = $request->longitude;
                $carPosition->title = $request->titre;
                $carPosition->commune = $request->commune;
                $carPosition->user_id = Auth::user()->id;
                $carPosition->save();

                $filename = uniqid('car_photo') . '.png';
                Storage::disk('public')->put('signalement/photo/' . $filename, $imageBinary);

                $carPhoto = new CarPhoto();
                $carPhoto->card_id = $carPosition->id;
                $carPhoto->filepath = 'signalement/photo/' . $filename;
                $carPhoto->save();

                return $carPhoto;
            });
        } catch (\Throwable $e) {
            return response()->json(['message' => 'Erreur lors de la signalisation'], 500);
        }

        return response()->json(['message' => 'Signalisation effectuée avec succès'], 200);
    }

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
        // Correction API-M-3 : count(->get()) charge toute la collection en
        // mémoire juste pour la compter — ->count() fait l'agrégation en SQL.
        return response()->json(
            [
                'signalements' => CarPosition::count(),
                'signales' => CarPosition::where('etat', 'SIGNALE')->count(),
                'enleves' => CarPosition::where('etat', 'ENLEVE')->count(),
                'encours' => CarPosition::where('etat', 'EN COURS')->count()
            ]
        );
    }

    public function listerSignalement(CarPosition $carPosition)
    {
        $signalement = CarPosition::where('id', $carPosition->id)->with('photo')->get();
        return SignalementRessource::collection($signalement);
    }
}
