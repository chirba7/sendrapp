<?php

namespace App\Http\Controllers;

use App\Models\CarPhoto;
use App\Models\CarPosition;
use App\Support\HistoriqueSignalement;
use App\Support\PriseEnCharge;
use App\Support\ProcesVerbal;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Str;

/**
 * Actions de l'agent sur un signalement (23/10/2026) :
 * prise en charge exclusive, photos de constatation, procès-verbal signé.
 */
class SignalementAgentController extends Controller
{
    /** Nombre maximal de photos de constatation prises par l'agent. */
    public const PHOTOS_AGENT_MAX = 4;

    /**
     * Prise en charge : l'agent devient le seul à pouvoir saisir la
     * constatation. Verrou posé en transaction (lockForUpdate) pour que deux
     * agents qui ouvrent le dossier à la même seconde ne l'obtiennent pas tous
     * les deux.
     */
    public function prendreEnCharge(CarPosition $carPosition)
    {
        $moi = auth()->id();

        $resultat = DB::transaction(function () use ($carPosition, $moi) {
            $s = CarPosition::whereKey($carPosition->id)->lockForUpdate()->first();

            if (in_array($s->etat, ['ENLEVE', 'REJETE'], true)) {
                return ['code' => 409, 'message' => 'Ce signalement est déjà clôturé.'];
            }
            if ($s->agent_id && (int) $s->agent_id !== (int) $moi) {
                return ['code' => 409, 'message' => 'Ce signalement est déjà pris en charge par '.PriseEnCharge::nomAgent($s).'.'];
            }
            if ((int) $s->agent_id === (int) $moi && $s->pris_en_charge_at) {
                return ['code' => 200, 'signalement' => $s, 'nouveau' => false];
            }

            $s->agent_id = $moi;
            $s->pris_en_charge_at = now();
            $s->save();

            return ['code' => 200, 'signalement' => $s, 'nouveau' => true];
        });

        if ($resultat['code'] !== 200) {
            return response()->json([
                'success' => false,
                'message' => $resultat['message'],
                'pris_en_charge_par' => PriseEnCharge::nomAgent($carPosition->fresh()),
            ], $resultat['code']);
        }

        if ($resultat['nouveau']) {
            HistoriqueSignalement::enregistrer($resultat['signalement'], 'pris_en_charge');
        }

        return response()->json($this->etatPriseEnCharge($resultat['signalement']));
    }

    /** L'agent rend le signalement (tant que la constatation n'est pas transmise). */
    public function liberer(CarPosition $carPosition)
    {
        if ((int) $carPosition->agent_id !== (int) auth()->id()) {
            return response()->json(['success' => false, 'message' => 'Vous ne détenez pas ce signalement.'], 409);
        }
        if ($carPosition->soumis_approbation_at) {
            return response()->json(['success' => false, 'message' => 'Constatation déjà transmise : le signalement ne peut plus être libéré.'], 423);
        }

        $carPosition->agent_id = null;
        $carPosition->pris_en_charge_at = null;
        $carPosition->save();
        HistoriqueSignalement::enregistrer($carPosition, 'libere');

        return response()->json($this->etatPriseEnCharge($carPosition));
    }

    private function etatPriseEnCharge(CarPosition $s): array
    {
        return [
            'success' => true,
            'agent_id' => $s->agent_id,
            'pris_en_charge_par' => $s->agent_id ? PriseEnCharge::nomAgent($s) : null,
            'pris_en_charge_par_moi' => $s->agent_id && (int) $s->agent_id === (int) auth()->id(),
            'pris_en_charge_at' => $s->pris_en_charge_at,
        ];
    }

    /** Supprime une photo de constatation (avant transmission). */
    public function supprimerPhoto(CarPosition $carPosition, CarPhoto $photo)
    {
        abort_unless((int) $photo->card_id === (int) $carPosition->id && $photo->position === 'agent_constat', 404);
        if ($refus = PriseEnCharge::refusSiAutreAgent($carPosition)) {
            return $refus;
        }
        abort_if(!empty($carPosition->dommage_image) || $carPosition->soumis_approbation_at, 423, 'Constatation déjà transmise.');

        Storage::disk('public')->delete($photo->filepath);
        $photo->delete();

        return response()->json(['success' => true]);
    }

    /**
     * Signature du procès-verbal par l'agent, après l'envoi pour approbation.
     * Le PDF est généré à ce moment-là et rangé sur le disque privé.
     */
    public function signerPv(Request $request, CarPosition $carPosition)
    {
        $request->validate(['signature' => 'required|string|max:5000000']);

        if (!$carPosition->soumis_approbation_at) {
            return response()->json(['success' => false, 'message' => 'La constatation doit d’abord être envoyée pour approbation.'], 422);
        }
        if ((int) auth()->user()->role_id === 2 && (int) $carPosition->agent_id !== (int) auth()->id()) {
            return response()->json(['success' => false, 'message' => 'Seul l’agent qui a fait la constatation peut signer le procès-verbal.'], 403);
        }
        if ($carPosition->pv_signe_at) {
            return response()->json(['success' => false, 'message' => 'Le procès-verbal est déjà signé.'] + $this->etatPv($request, $carPosition), 409);
        }

        $donnees = $request->input('signature');
        if (str_contains($donnees, ',')) {
            $donnees = substr($donnees, strpos($donnees, ',') + 1);
        }
        $signature = base64_decode($donnees, true);
        if ($signature === false || @getimagesizefromstring($signature) === false) {
            return response()->json(['success' => false, 'message' => 'Signature illisible.'], 422);
        }

        $signeLe = now();
        $jeton = Str::random(24);
        $cheminSignature = "pv/signatures/pv_{$carPosition->id}_{$jeton}.png";
        $cheminPdf = "pv/pv_{$carPosition->id}_{$jeton}.pdf";

        $carPosition->pv_numero = $carPosition->pv_numero ?: ProcesVerbal::numero($carPosition);
        $pdf = ProcesVerbal::generer($carPosition, $signature, $signeLe);

        Storage::disk('local')->put($cheminSignature, $signature);
        Storage::disk('local')->put($cheminPdf, $pdf);

        $carPosition->pv_signature = $cheminSignature;
        $carPosition->pv_path = $cheminPdf;
        $carPosition->pv_signe_at = $signeLe;
        $carPosition->save();

        HistoriqueSignalement::enregistrer($carPosition, 'pv_signe');

        return response()->json(['success' => true, 'message' => 'Procès-verbal signé.'] + $this->etatPv($request, $carPosition));
    }

    /** Lien temporaire (30 min) pour consulter / télécharger le PV. */
    public function lienPv(Request $request, CarPosition $carPosition)
    {
        if (!$carPosition->pv_path) {
            return response()->json(['success' => false, 'message' => 'Procès-verbal pas encore signé.'], 404);
        }

        return response()->json(['success' => true] + $this->etatPv($request, $carPosition));
    }

    /** Téléchargement par lien signé (le navigateur du téléphone n'a pas le jeton JWT). */
    public function telechargerPv(Request $request, CarPosition $carPosition)
    {
        abort_unless($carPosition->pv_path && Storage::disk('local')->exists($carPosition->pv_path), 404);
        $nom = ($carPosition->pv_numero ?: 'PV-'.$carPosition->id).'.pdf';

        return response(Storage::disk('local')->get($carPosition->pv_path), 200, [
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => ($request->boolean('telecharger') ? 'attachment' : 'inline').'; filename="'.$nom.'"',
            'Cache-Control' => 'private, no-store',
        ]);
    }

    private function etatPv(Request $request, CarPosition $s): array
    {
        $lien = function (bool $telecharger) use ($request, $s) {
            // Lien relatif signé puis préfixé par l'hôte réellement appelé par
            // le téléphone (APP_URL vaut localhost sur certains serveurs).
            $params = ['carPosition' => $s->id] + ($telecharger ? ['telecharger' => 1] : []);

            return $request->getSchemeAndHttpHost()
                .URL::temporarySignedRoute('pv.telecharger', now()->addMinutes(30), $params, false);
        };

        return [
            'pv_numero' => $s->pv_numero,
            'pv_signe' => (bool) $s->pv_signe_at,
            'pv_signe_at' => $s->pv_signe_at ? \Carbon\Carbon::parse($s->pv_signe_at)->format('d/m/Y à H\hi') : null,
            'pv_url' => $s->pv_path ? $lien(false) : null,
            'pv_url_telechargement' => $s->pv_path ? $lien(true) : null,
        ];
    }
}
