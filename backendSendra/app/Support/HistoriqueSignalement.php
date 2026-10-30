<?php

namespace App\Support;

use App\Models\CarPosition;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

/**
 * Journal daté des changements d'état d'un signalement.
 *
 * `car_positions` ne porte que l'état courant : sans ce journal, le citoyen ne
 * peut pas voir l'avancement de son signalement, seulement sa situation à
 * l'instant T. Chaque étape du circuit y écrit une ligne.
 *
 * Les libellés affichés restent dans l'application (traduisibles) ; la base ne
 * stocke que le code de l'évènement.
 */
class HistoriqueSignalement
{
    public const LIBELLES = [
        'cree' => 'Signalement reçu',
        'constat_soumis' => 'Constatation envoyée pour approbation',
        'approuve' => 'Signalement approuvé',
        'rejete' => 'Signalement rejeté',
        'enleve' => 'Véhicule enlevé',
        'pris_en_charge' => 'Pris en charge par un agent',
        'libere' => 'Prise en charge libérée',
        'pv_signe' => 'Procès-verbal signé par l’agent',
    ];

    /**
     * Écrit une étape. Ne lève jamais d'exception : un journal en échec ne doit
     * pas faire échouer l'action métier qu'il décrit.
     */
    public static function enregistrer(
        CarPosition $carPosition,
        string $event,
        ?string $motif = null,
        ?int $userId = null
    ): void {
        try {
            DB::table('signalement_status_history')->insert([
                'car_position_id' => $carPosition->id,
                'event' => $event,
                'etat' => $carPosition->etat,
                'is_approve' => $carPosition->is_approve === null ? null : (bool) $carPosition->is_approve,
                'motif' => $motif,
                'user_id' => $userId ?? Auth::id(),
                'created_at' => now(),
            ]);
        } catch (\Throwable $e) {
            report($e);
        }
    }

    /**
     * L'historique d'un signalement, du plus ancien au plus récent, prêt à être
     * renvoyé à l'application mobile.
     */
    public static function pour(CarPosition $carPosition): array
    {
        // Préchargé par precharger() : aucune requête de plus.
        if ($carPosition->relationLoaded(self::RELATION)) {
            return $carPosition->getRelation(self::RELATION);
        }

        return DB::table('signalement_status_history')
            ->where('car_position_id', $carPosition->id)
            ->orderBy('created_at')
            ->orderBy('id')
            ->get(['event', 'etat', 'is_approve', 'motif', 'created_at'])
            ->map(fn ($l) => self::ligne($l))
            ->all();
    }

    /**
     * Correction perf (audit du 29/10/2026) : SignalementRessource appelait
     * pour() une fois par signalement — jusqu'à 201 requêtes pour un
     * citoyen qui ouvre l'app (voirSignalements, 200 lignes). Une seule
     * requête pour toute la liste ; le résultat est rangé sur chaque modèle
     * et pour() le relit. Même contenu, même ordre qu'avant.
     *
     * @param  iterable<CarPosition>  $signalements
     */
    public static function precharger(iterable $signalements): void
    {
        $parId = [];
        foreach ($signalements as $s) {
            $parId[$s->id] = $s;
        }
        if (!$parId) {
            return;
        }

        $lignes = [];
        foreach (array_chunk(array_keys($parId), 500) as $ids) {
            DB::table('signalement_status_history')
                ->whereIn('car_position_id', $ids)
                ->orderBy('created_at')
                ->orderBy('id')
                ->get(['car_position_id', 'event', 'etat', 'is_approve', 'motif', 'created_at'])
                ->each(function ($l) use (&$lignes) {
                    $lignes[$l->car_position_id][] = self::ligne($l);
                });
        }

        foreach ($parId as $id => $s) {
            $s->setRelation(self::RELATION, $lignes[$id] ?? []);
        }
    }

    private const RELATION = 'historique_precharge';

    private static function ligne(object $l): array
    {
        return [
            'event' => $l->event,
            'libelle' => self::LIBELLES[$l->event] ?? $l->event,
            'etat' => $l->etat,
            'motif' => $l->motif,
            'date' => $l->created_at,
        ];
    }
}
