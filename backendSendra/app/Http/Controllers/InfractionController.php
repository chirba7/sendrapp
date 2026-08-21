<?php

namespace App\Http\Controllers;

use App\Http\Requests\InfractionRequest;
use App\Http\Resources\InfractionResource;
use App\Models\CarPosition;
use Illuminate\Http\Request;

class InfractionController extends Controller
{
    public function index()
    {
        // Correction API-M-3 : pas de pagination, tout le jeu de résultats
        // était chargé et sérialisé d'un coup.
        $carPosition = CarPosition::whereNotNull('adresse_precise')->paginate(20);
        return response()->json(InfractionResource::collection($carPosition));
    }


    public function show(CarPosition $carPosition)
    {
        return response()->json(new InfractionResource($carPosition));
    }

   public function update(InfractionRequest $request, CarPosition $carPosition)
 {
    // Mise à jour des champs simples
    $carPosition->adresse_precise = $request->input('adresse_precise');
    $carPosition->motif_infraction = $request->input('motif_infraction');

    // Correction API-H-4 : la colonne `lieu` est NOT NULL en base ; ne
    // l'assigner que si le client l'a réellement envoyé, sinon `input()`
    // renvoie null et fait planter la mise à jour SQL même sur une requête
    // valide selon le FormRequest (qui autorise l'omission du champ).
    if ($request->filled('lieu')) {
        $carPosition->lieu = $request->input('lieu');
    }

     // Gestion explicite des champs booléens
    $carPosition->nuit = $request->boolean('nuit', false); // Par défaut false si absent
    $carPosition->pluie = $request->boolean('pluie', false); // Par défaut false si absent


    // Mise à jour dans la base de données
    $carPosition->update();

    // Retourner la réponse
    return response()->json([
        'success' => true,
        'data' => $carPosition,
    ]);
  }





    public function destroy(CarPosition $carPosition)
    {
        $carPosition->delete();
        return response()->json(null, 204);
    }
}
