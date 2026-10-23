<?php

namespace App\Support;

use App\Models\CarPhoto;
use App\Models\CarPosition;
use Carbon\Carbon;
use Illuminate\Support\Facades\Storage;

/**
 * Procès-verbal de constatation d'un signalement, signé par l'agent.
 *
 * Généré après l'envoi pour approbation : il reprend la constatation telle
 * qu'elle a été transmise (verrouillée), avec la signature de l'agent.
 */
class ProcesVerbal
{
    private const VERT = [7, 92, 50];
    private const GRIS = [95, 107, 101];
    private const BORD = [225, 232, 228];
    private const MARGE = 40;

    private PdfSimple $pdf;
    private float $y = 0;

    public static function numero(CarPosition $s): string
    {
        $annee = Carbon::parse($s->soumis_approbation_at ?: $s->created_at)->format('Y');

        return sprintf('PV-%s-%06d', $annee, $s->id);
    }

    /** Construit le PDF. $signature : image binaire (PNG ou JPEG). */
    public static function generer(CarPosition $s, string $signature, Carbon $signeLe): string
    {
        return (new self())->construire($s, $signature, $signeLe);
    }

    private function construire(CarPosition $s, string $signature, Carbon $signeLe): string
    {
        $this->pdf = new PdfSimple();
        $this->nouvellePage();

        // En-tête
        $this->pdf->rectangle(0, 0, PdfSimple::LARGEUR, 92, self::VERT);
        $this->pdf->texte(self::MARGE, 24, 'PROCÈS-VERBAL DE CONSTATATION', 18, true, [255, 255, 255]);
        $this->pdf->texte(self::MARGE, 50, 'SENDRA · epaVie — véhicule abandonné ou encombrant sur la voie publique', 10, false, [225, 240, 230]);
        $this->pdf->texte(self::MARGE, 66, 'N° '.($s->pv_numero ?: self::numero($s)).'   ·   Signalement n° '.$s->id, 10, true, [255, 255, 255]);
        $this->y = 112;

        $agent = $s->agent()->first();
        $nomAgent = trim(($agent->first_name ?? '').' '.($agent->last_name ?? '')) ?: 'Agent non renseigné';

        $this->section('Signalement', [
            'Date du signalement' => $this->date($s->created_at),
            'Commune' => $s->commune,
            'Adresse précise' => $s->adresse_precise,
            'Coordonnées GPS' => ($s->latitude && $s->longitude) ? $s->latitude.', '.$s->longitude : null,
            'Description du citoyen' => $s->description,
        ]);

        $details = collect([
            $s->defaut_controle_technique ? 'Défaut de contrôle technique' : null,
            $s->pneumatiques_manquantes ? 'Pneumatiques manquants' : null,
            $s->vehicule_immerge ? 'Véhicule immergé' : null,
            $s->defauts_techniques_irreversibles ? 'Défauts techniques irréversibles' : null,
            $s->vehicule_non_identifiable ? 'Véhicule non identifiable' : null,
            $s->vehicule_brule ? 'Véhicule brûlé' : null,
            $s->chassis_non_reparable ? 'Châssis non réparable' : null,
        ])->filter()->join(', ');

        $this->section('Véhicule', [
            'Type' => $s->vehicle_kind,
            'Immatriculation' => $s->numero_vehicule,
            'Marque / modèle' => trim(($s->marque ?? '').' '.($s->model ?? '')),
            'Catégorie' => $s->categorie,
            'Couleur' => $s->couleur,
            'État général' => $s->entretien,
            'Immatriculé à l’étranger' => $s->pays_etranger,
            'Constats' => $details ?: null,
            'Autre situation' => $s->autre_situation,
        ]);

        $this->section('Infraction', [
            'Motif' => $s->motif_infraction,
            'Explication' => $s->explication_infraction,
            'Lieu' => $s->lieu === 'PRIVE' ? 'Privé' : ($s->lieu === 'PUBLIC' ? 'Public' : $s->lieu),
            'Moment du constat' => $s->pluie ? 'Pluie' : ($s->nuit ? 'Nuit' : 'Jour'),
        ]);

        $this->section('Dommages', [
            'Pièces manquantes' => $s->pieces_manquantes,
        ]);
        if ($s->dommage_image) {
            $this->imageDepuisDisque('dommages/'.$s->dommage_image, 'Relevé des dommages', 150);
        }

        $photos = CarPhoto::where('card_id', $s->id)->where('position', 'agent_constat')->orderBy('id')->limit(4)->get();
        if ($photos->isNotEmpty()) {
            $this->vignettes($photos->pluck('filepath')->all());
        }

        // Signature
        $this->besoin(150);
        $this->titre('Signature de l’agent');
        $this->ligne('Agent', $nomAgent);
        $this->ligne('Constatation transmise le', $this->date($s->soumis_approbation_at));
        $this->ligne('Signé le', $signeLe->format('d/m/Y à H\hi'));
        $image = $this->pdf->chargerImage($signature, 600);
        if ($image) {
            $this->pdf->rectangle(self::MARGE, $this->y + 4, 220, 90, null, self::BORD);
            $this->pdf->image($image, self::MARGE + 8, $this->y + 10, 204, 78);
            $this->y += 104;
        }

        // Pied de page sur chaque page déjà écrite : simple mention.
        $this->pdf->texte(self::MARGE, PdfSimple::HAUTEUR - 34,
            'Document généré par epaVie le '.now()->format('d/m/Y à H\hi').' — signé électroniquement par l’agent verbalisateur.',
            8, false, self::GRIS);

        return $this->pdf->rendu();
    }

    private function nouvellePage(): void
    {
        $this->pdf->ajouterPage();
        $this->y = 40;
    }

    private function besoin(float $hauteur): void
    {
        if ($this->y + $hauteur > PdfSimple::HAUTEUR - 50) {
            $this->nouvellePage();
        }
    }

    private function titre(string $titre): void
    {
        $this->besoin(40);
        $this->pdf->texte(self::MARGE, $this->y, mb_strtoupper($titre), 11, true, self::VERT);
        $this->y += 17;
        $this->pdf->trait(self::MARGE, $this->y, PdfSimple::LARGEUR - self::MARGE, $this->y, self::BORD);
        $this->y += 8;
    }

    private function section(string $titre, array $champs): void
    {
        $champs = array_filter($champs, fn ($v) => $v !== null && trim((string) $v) !== '');
        $this->titre($titre);
        if (!$champs) {
            $this->pdf->texte(self::MARGE, $this->y, 'Non renseigné', 9.5, false, self::GRIS);
            $this->y += 20;

            return;
        }
        foreach ($champs as $libelle => $valeur) {
            $this->ligne($libelle, (string) $valeur);
        }
        $this->y += 8;
    }

    private function ligne(string $libelle, ?string $valeur): void
    {
        $colonne = 170;
        $largeur = PdfSimple::LARGEUR - 2 * self::MARGE - $colonne;
        $lignes = $this->pdf->couperTexte($valeur ?: '—', 9.5, $largeur);
        $this->besoin(13 * count($lignes) + 4);
        $this->pdf->texte(self::MARGE, $this->y, $libelle, 9.5, false, self::GRIS);
        foreach ($lignes as $i => $texte) {
            $this->pdf->texte(self::MARGE + $colonne, $this->y + 13 * $i, $texte, 9.5, true);
        }
        $this->y += 13 * count($lignes) + 4;
    }

    private function imageDepuisDisque(string $chemin, string $legende, float $hauteurMax): void
    {
        $binaire = $this->lire($chemin);
        $image = $binaire ? $this->pdf->chargerImage($binaire) : null;
        if (!$image) {
            return;
        }
        $this->besoin($hauteurMax + 24);
        $this->pdf->texte(self::MARGE, $this->y, $legende, 9, false, self::GRIS);
        $this->y += 14;
        $h = $this->pdf->image($image, self::MARGE, $this->y, PdfSimple::LARGEUR - 2 * self::MARGE, $hauteurMax);
        $this->y += $h + 12;
    }

    private function vignettes(array $chemins): void
    {
        $this->besoin(150);
        $this->pdf->texte(self::MARGE, $this->y, 'Photos de l’agent', 9, false, self::GRIS);
        $this->y += 14;
        $largeur = (PdfSimple::LARGEUR - 2 * self::MARGE - 3 * 8) / 4;
        $hauteurMax = 0;
        foreach (array_values($chemins) as $i => $chemin) {
            $binaire = $this->lire($chemin);
            $image = $binaire ? $this->pdf->chargerImage($binaire, 700) : null;
            if ($image) {
                $hauteurMax = max($hauteurMax, $this->pdf->image($image, self::MARGE + $i * ($largeur + 8), $this->y, $largeur, 110));
            }
        }
        $this->y += $hauteurMax + 14;
    }

    private function lire(string $chemin): ?string
    {
        try {
            return Storage::disk('public')->exists($chemin) ? Storage::disk('public')->get($chemin) : null;
        } catch (\Throwable) {
            return null;
        }
    }

    private function date($valeur): ?string
    {
        if (!$valeur) {
            return null;
        }
        try {
            return Carbon::parse($valeur)->format('d/m/Y à H\hi');
        } catch (\Throwable) {
            return null;
        }
    }
}
