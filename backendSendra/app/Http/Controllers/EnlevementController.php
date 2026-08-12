<?php

namespace App\Http\Controllers;

use App\Models\CarPosition;
use Illuminate\Http\Request;

class EnlevementController extends Controller
{
    public function ajouterEnlevement(Request $request, CarPosition $carPosition)
    {
        $request->validate([
            'motif' => 'required|string|max:255',
            'date' => 'required|date_format:Y-m-d',
            'lieu' => 'required|string|max:255',
            'nom_responsable' => 'required|string|max:255',
        ]);

        $carPosition->motif_enlevement = $request->input('motif');
        $carPosition->date_enlevement = $request->input('date');
        $carPosition->lieu_enlevement = $request->input('lieu');
        $carPosition->nom_responsable_mef = $request->input('nom_responsable');
        $carPosition->etat = "ENLEVE";
        $carPosition->save();

        return response()->json(['message' => 'Enlèvement ajouté avec succès'], 201);
    }

    public function obtenirEnlevement(CarPosition $carPosition)
    {

        return response()->json([
            'id' => $carPosition->id,
            'motif_enlevement' => $carPosition->motif_enlevement,
            'date_enlevement' => $carPosition->date_enlevement,
            'lieu_enlevement' => $carPosition->lieu_enlevement,
            'nom_responsable_mef' => $carPosition->nom_responsable_mef,
            'etat' => $carPosition->etat,
        ]);
    }
}
