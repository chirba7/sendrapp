<?php

namespace App\Support;

use App\Models\CarPosition;
use Carbon\Carbon;

/**
 * Avancement d'un signalement exprimé avec les cinq états affichés partout
 * (applications et back-office) : Signalé → En cours → Résolu, ou une des
 * deux autres issues, Non résolu ou Rejeté.
 *
 * Calculé ici une seule fois pour que les deux applications affichent
 * exactement les mêmes étapes, avec les mêmes dates.
 */
class AvancementSignalement
{
    public const LIBELLES = [
        'SIGNALE' => 'Signalé',
        'EN COURS' => 'En cours',
        'ENLEVE' => 'Résolu',
        'NON RESOLU' => 'Non résolu',
        'REJETE' => 'Rejeté',
    ];

    /**
     * État affiché (filtre de l'accueil, badges) :
     *  - « NON RESOLU » est déduit du constat de non-enlèvement ;
     *  - un signalement dont la constatation est envoyée pour approbation est
     *    « EN COURS », même si l'autorité n'a pas encore statué.
     */
    public static function etatAffiche(CarPosition $s): string
    {
        if ($s->non_removed_at && !in_array($s->etat, ['ENLEVE', 'REJETE'], true)) {
            return 'NON RESOLU';
        }
        if (($s->etat ?: 'SIGNALE') === 'SIGNALE' && ($s->soumis_approbation_at || !empty($s->dommage_image))) {
            return 'EN COURS';
        }

        return $s->etat ?: 'SIGNALE';
    }

    /**
     * Parcours complet, toujours en cinq étapes, du signalement à l'issue :
     *   1. Signalé
     *   2. Constaté par l'agent
     *   3. Approbation de l'autorité   (rouge + motif si rejeté : fin du parcours)
     *   4. Enlèvement                  (rouge + motif si non enlevé)
     *   5. Résolu / Non résolu
     *
     * Statut de chaque étape : `fait`, `actuel` (là où en est le dossier),
     * `echec` (rouge, avec motif), `a_venir` ou `saute` (non applicable).
     *
     * @param  array<int, array<string, mixed>>  $historique  sortie de HistoriqueSignalement::pour()
     */
    public static function pour(CarPosition $s, array $historique = []): array
    {
        $etat = self::etatAffiche($s);
        $date = function (string $event) use ($historique) {
            foreach (array_reverse($historique) as $ligne) {
                if (($ligne['event'] ?? null) === $event) {
                    return self::iso($ligne['date'] ?? null);
                }
            }

            return null;
        };

        $rejete = $etat === 'REJETE';
        $nonResolu = $etat === 'NON RESOLU';
        $enleve = $etat === 'ENLEVE';
        $approuve = (bool) $s->is_approve || $enleve || $nonResolu;
        $constate = (bool) ($s->soumis_approbation_at || !empty($s->dommage_image)) || $approuve || $rejete;

        $etapes = [];

        $etapes[] = [
            'etape' => 'signale',
            'libelle' => 'Signalé',
            'statut' => 'fait',
            'detail' => 'Signalement reçu',
            'date' => $date('cree') ?? self::iso($s->created_at),
        ];

        $etapes[] = [
            'etape' => 'constate',
            'libelle' => 'Constaté par l’agent',
            'statut' => $constate ? 'fait' : ($s->agent_id ? 'actuel' : 'a_venir'),
            'detail' => $constate
                ? 'Constatation transmise pour approbation'
                : ($s->agent_id ? 'Pris en charge, constatation en cours' : 'En attente d’un agent'),
            'date' => $constate ? ($date('constat_soumis') ?? self::iso($s->soumis_approbation_at)) : null,
        ];

        if ($rejete) {
            $approbation = ['libelle' => 'Rejeté par l’autorité', 'statut' => 'echec',
                'detail' => 'Motif : '.($s->motife_approbation ?: 'non précisé'),
                'date' => $date('rejete') ?? self::iso($s->updated_at)];
        } elseif ($approuve) {
            $approbation = ['libelle' => 'Approuvé par l’autorité', 'statut' => 'fait',
                'detail' => $s->motife_approbation ?: null, 'date' => $date('approuve')];
        } elseif ($constate) {
            $approbation = ['libelle' => 'En attente d’approbation de l’autorité', 'statut' => 'actuel',
                'detail' => 'La constatation est en cours d’examen', 'date' => null];
        } else {
            $approbation = ['libelle' => 'Approbation de l’autorité', 'statut' => 'a_venir', 'detail' => null, 'date' => null];
        }
        $etapes[] = ['etape' => 'approbation'] + $approbation;

        if ($enleve) {
            $enlevement = ['libelle' => 'Véhicule enlevé', 'statut' => 'fait', 'detail' => null,
                'date' => $date('enleve') ?? self::iso($s->date_enlevement) ?? self::iso($s->updated_at)];
        } elseif ($nonResolu) {
            $enlevement = ['libelle' => 'Véhicule non enlevé', 'statut' => 'echec',
                'detail' => 'Motif : '.($s->non_removal_reason ?: 'non précisé'), 'date' => self::iso($s->non_removed_at)];
        } elseif ($rejete) {
            $enlevement = ['libelle' => 'Enlèvement', 'statut' => 'saute', 'detail' => 'Sans objet après le rejet', 'date' => null];
        } elseif ($approuve) {
            $enlevement = ['libelle' => 'En attente d’enlèvement', 'statut' => 'actuel', 'detail' => 'Enlèvement programmé par une mission', 'date' => null];
        } else {
            $enlevement = ['libelle' => 'Enlèvement', 'statut' => 'a_venir', 'detail' => null, 'date' => null];
        }
        $etapes[] = ['etape' => 'enlevement'] + $enlevement;

        if ($enleve) {
            $issue = ['libelle' => 'Résolu', 'statut' => 'fait', 'detail' => 'Dossier clôturé', 'date' => $enlevement['date']];
        } elseif ($nonResolu) {
            $issue = ['libelle' => 'Non résolu', 'statut' => 'echec', 'detail' => 'Dossier clôturé sans enlèvement', 'date' => self::iso($s->non_removed_at)];
        } elseif ($rejete) {
            $issue = ['libelle' => 'Résolu', 'statut' => 'saute', 'detail' => 'Dossier clôturé par le rejet', 'date' => null];
        } else {
            $issue = ['libelle' => 'Résolu', 'statut' => 'a_venir', 'detail' => null, 'date' => null];
        }
        $etapes[] = ['etape' => 'issue'] + $issue;

        return $etapes;
    }

    private static function iso($valeur): ?string
    {
        if (empty($valeur)) {
            return null;
        }
        try {
            return Carbon::parse($valeur)->format('d/m/Y à H\hi');
        } catch (\Throwable) {
            return null;
        }
    }
}
