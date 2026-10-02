<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreCarPositionRequest;
use App\Http\Resources\SignalementRessource;
use App\Models\CarPhoto;
use App\Models\CarPosition;
use App\Support\ImageOptimizer;
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
        $uuid = $request->input('uuid');

        // Envoi rejoué (synchro hors ligne après une coupure en plein envoi) :
        // le signalement existe déjà, on confirme sans créer de doublon.
        if ($uuid && CarPosition::where('uuid', $uuid)->where('user_id', Auth::user()->id)->exists()) {
            return response()->json(['message' => 'Signalisation effectuée avec succès'], 200);
        }

        // Nouvelle app : une photo par angle. Ancienne app : un seul `image`.
        // La vue d'ensemble passe en premier : image_url (SignalementRessource)
        // affiche la première photo.
        $photos = $request->filled('photos')
            ? collect($request->input('photos'))
                ->sortBy(fn ($p) => $p['position'] === 'vue_ensemble' ? 0 : 1)
                ->values()
                ->all()
            : [['position' => null, 'image' => $request->input('image')]];

        $images = [];
        foreach ($photos as $photo) {
            $imageBinary = base64_decode($photo['image'], true);

            if ($imageBinary === false || @getimagesizefromstring($imageBinary) === false) {
                return response()->json(['message' => 'Le fichier fourni n\'est pas une image valide'], 422);
            }

            // Correction perf : les photos envoyées telles quelles par un
            // appareil photo (souvent 3000px+ de large) gonflaient inutilement
            // le stockage et les réponses de listerSignalements/voirSignalements
            // (image_url pointe sur l'original). Redimensionnée à 1600px max
            // avant écriture disque (JPEG si le build GD le supporte, sinon PNG).
            $optimized = ImageOptimizer::resize($imageBinary);
            unset($imageBinary);

            $images[] = [
                'position' => $photo['position'],
                'binary' => $optimized['binary'],
                'extension' => $optimized['extension'],
            ];
        }

        $fichiersEcrits = [];

        try {
            DB::transaction(function () use ($request, $uuid, $images, &$fichiersEcrits) {
                $carPosition = new CarPosition();
                $carPosition->latitude = $request->latitude;
                $carPosition->longitude = $request->longitude;
                $carPosition->title = $request->titre;
                $carPosition->commune = $request->commune;
                $carPosition->uuid = $uuid;
                $carPosition->user_id = Auth::user()->id;
                $carPosition->save();

                foreach ($images as $image) {
                    $chemin = 'signalement/photo/' . uniqid('car_photo') . '.' . $image['extension'];
                    Storage::disk('public')->put($chemin, $image['binary']);
                    $fichiersEcrits[] = $chemin;

                    $carPhoto = new CarPhoto();
                    $carPhoto->card_id = $carPosition->id;
                    $carPhoto->filepath = $chemin;
                    $carPhoto->position = $image['position'];
                    $carPhoto->save();
                }
            });
        } catch (\Throwable $e) {
            // La transaction annule la base, pas le disque : on retire les
            // fichiers déjà écrits pour ne pas laisser d'orphelins.
            Storage::disk('public')->delete($fichiersEcrits);

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
        // Correction perf : aucune limite — l'historique complet d'un
        // citoyen part en une seule réponse, qui grossit sans borne avec le
        // temps. Un citoyen n'a normalement besoin de voir que ses
        // signalements les plus récents ; 200 laisse une large marge sans
        // changer le format de réponse (pas de pagination ici, pour rester
        // compatible avec l'app mobile qui traite ce endpoint comme un
        // tableau brut, contrairement à listerSignalements).
        $signalement = CarPosition::where([['user_id', Auth::user()->id], ['is_deleted', false]])
            ->with('photo')
            ->orderBy('created_at', 'desc')
            ->limit(200)
            ->get();
        // return response()->json($signalement);
        return response()->json(SignalementRessource::collection($signalement));
    }

    public function listerSignalements()
    {

        $signalement = CarPosition::where('is_deleted', false)
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
        // Correction perf : 4 requêtes count() séparées → 1 seule requête
        // groupée pour la répartition par état, plus le total.
        $parEtat = CarPosition::selectRaw('etat, count(*) as total')
            ->groupBy('etat')
            ->pluck('total', 'etat');

        return response()->json(
            [
                'signalements' => CarPosition::count(),
                'signales' => $parEtat->get('SIGNALE', 0),
                'enleves' => $parEtat->get('ENLEVE', 0),
                'encours' => $parEtat->get('EN COURS', 0),
            ]
        );
    }

    public function listerSignalement(CarPosition $carPosition)
    {
        $signalement = CarPosition::where('id', $carPosition->id)->with('photo')->get();
        return SignalementRessource::collection($signalement);
    }
}
