<?php

namespace App\Http\Controllers;

use App\Models\CarPosition;
use Illuminate\Http\Request;

class ApprobationController extends Controller
{
    public function soumettreApprobation(Request $request, CarPosition $carPosition)
    {
        $request->validate([
            'approbation' => 'required|string|in:OUI,NON',
            'motifApprobation' => 'nullable|string|max:225',
        ]);

        // Correction API-M-1 : l'état était forcé à "EN COURS" même en cas
        // de refus, ce qui ne laissait aucune trace distincte d'un rejet.
        if ($request->approbation == "OUI") {
            $carPosition->is_approve = true;
            $carPosition->etat = "EN COURS";
        } elseif ($request->approbation == "NON") {
            $carPosition->is_approve = false;
            $carPosition->etat = "REJETE";
        }

        $carPosition->motife_approbation = $request->motifApprobation;

        $carPosition->save();

        return response()->json([
            'message' => 'L\'approbation a été soumise avec succès.',
            'signalement' => $carPosition
        ], 200);
    }

    public function motifsApprobation(CarPosition $carPosition)
    {
        return response()->json([
            'id' => $carPosition->id,
            'approbation' => $carPosition->is_approve,
            'motifApprobation' => $carPosition->motife_approbation,
            'etat' => $carPosition->etat,
        ]);
    }
}
