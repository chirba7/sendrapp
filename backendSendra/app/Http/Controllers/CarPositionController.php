<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreCarPositionRequest;
use App\Http\Resources\SignalementPublicRessource;
use App\Http\Resources\SignalementRessource;
use App\Models\CarPhoto;
use App\Models\CarPosition;
use App\Support\HistoriqueSignalement;
use App\Support\ImageOptimizer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
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
            $carPosition = DB::transaction(function () use ($request, $uuid, $images, &$fichiersEcrits) {
                $carPosition = new CarPosition();
                $carPosition->latitude = $request->latitude;
                $carPosition->longitude = $request->longitude;
                $carPosition->title = $request->filled('titre') ? $request->titre : $request->vehicle_kind;
                $carPosition->vehicle_kind = $request->vehicle_kind;
                $carPosition->description = $request->description;
                $carPosition->adresse_precise = $request->adresse_precise;
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
                    // Photos jointes au signalement par le citoyen ; celles
                    // prises par l'agent pendant la constatation portent
                    // 'agent' (compte rendu de direction, § 03).
                    $carPhoto->source = 'citoyen';
                    $carPhoto->save();
                }

                return $carPosition;
            });
        } catch (\Throwable $e) {
            // La transaction annule la base, pas le disque : on retire les
            // fichiers déjà écrits pour ne pas laisser d'orphelins.
            Storage::disk('public')->delete($fichiersEcrits);

            return response()->json(['message' => 'Erreur lors de la signalisation'], 500);
        }

        HistoriqueSignalement::enregistrer($carPosition, 'cree');
        self::oublierCacheCommunaute();

        return response()->json(['message' => 'Signalisation effectuée avec succès'], 200);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(CarPosition $carPosition)
    {
        $carPosition->is_deleted = true;
        $carPosition->update();
        self::oublierCacheCommunaute();

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
        // Correction perf (29/10/2026) : 'agent' chargé d'avance (nom de
        // l'agent pour le personnel) et historique préchargé en une requête,
        // au lieu d'une requête par signalement (jusqu'à 201 par appel).
        $signalement = CarPosition::where([['user_id', Auth::user()->id], ['is_deleted', false]])
            ->with(['photo', 'agent'])
            ->orderBy('created_at', 'desc')
            ->limit(200)
            ->get();
        HistoriqueSignalement::precharger($signalement);
        // return response()->json($signalement);
        return response()->json(SignalementRessource::collection($signalement));
    }

    public function listerSignalements()
    {

        $signalement = CarPosition::where('is_deleted', false)
            ->with(['photo', 'agent'])
            ->orderBy('created_at', 'desc')
            ->paginate(10);
        HistoriqueSignalement::precharger($signalement->getCollection());
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
                // « En cours » dès l'envoi pour approbation (23/10/2026).
                'signales' => CarPosition::where('etat', 'SIGNALE')->whereNull('non_removed_at')
                    ->whereNull('soumis_approbation_at')->count(),
                'enleves' => $parEtat->get('ENLEVE', 0),
                'encours' => CarPosition::whereNull('non_removed_at')
                    ->where(fn ($q) => $q->where('etat', 'EN COURS')
                        ->orWhere(fn ($q) => $q->where('etat', 'SIGNALE')->whereNotNull('soumis_approbation_at')))
                    ->count(),
                'non_resolus' => CarPosition::whereIn('etat', ['SIGNALE', 'EN COURS'])->whereNotNull('non_removed_at')->count(),
            ]
        );
    }

    /**
     * Signalements de tous les citoyens, pour la liste « Autres » et la carte
     * de l'application citoyen. Données réduites : ni description, ni adresse
     * précise, ni historique, ni identité de l'auteur — seulement de quoi
     * savoir qu'un véhicule est déjà signalé et où en est son traitement.
     */
    public function signalementsCommunaute(Request $request)
    {
        // Correction perf (29/10/2026) : la liste est la même pour tous les
        // citoyens et l'app la relit à chaque ouverture de l'onglet « Autres »
        // ou de la carte. Elle est mise en cache 60 s (vidée à chaque nouveau
        // signalement) ; seul `est_mien` dépend de l'appelant, il est calculé
        // après le cache à partir de l'auteur, qui n'est jamais renvoyé.
        // La clé porte l'hôte appelé (image_url en dépend) et un numéro de
        // version, incrémenté pour invalider sans connaître tous les hôtes.
        $cle = self::CLE_CACHE_COMMUNAUTE.':v'.(int) Cache::get(self::CLE_CACHE_COMMUNAUTE.':version', 0)
            .':'.$request->getSchemeAndHttpHost();
        $lignes = Cache::remember($cle, self::DUREE_CACHE_COMMUNAUTE, function () use ($request) {
            $signalements = CarPosition::where('is_deleted', false)
                ->with('photo')
                ->orderBy('created_at', 'desc')
                ->limit(300)
                ->get();

            return $signalements->map(fn ($s) => [
                'auteur' => (int) $s->user_id,
                'donnees' => (new SignalementPublicRessource($s))->toArray($request),
            ])->all();
        });

        $moi = (int) Auth::id();

        return response()->json(array_map(
            fn ($l) => array_merge($l['donnees'], ['est_mien' => $l['auteur'] === $moi]),
            $lignes
        ));
    }

    public const CLE_CACHE_COMMUNAUTE = 'signalements-communaute';
    private const DUREE_CACHE_COMMUNAUTE = 60;

    /** Invalide la liste publique en cache (nouvelle version de clé). */
    public static function oublierCacheCommunaute(): void
    {
        $cle = self::CLE_CACHE_COMMUNAUTE.':version';
        Cache::forever($cle, (int) Cache::get($cle, 0) + 1);
    }

    public function listerSignalement(CarPosition $carPosition)
    {
        $signalement = CarPosition::where('id', $carPosition->id)->with(['photo', 'agent'])->get();
        return SignalementRessource::collection($signalement);
    }
}
