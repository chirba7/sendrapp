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
        $carPosition = CarPosition::whereNotNull('adresse_precise')->get();
        return response()->json(InfractionResource::collection($carPosition));
    }


    public function show(CarPosition $carPosition)
    {
        return response()->json(new InfractionResource($carPosition));
    }

    /*public function update(InfractionRequest $request, CarPosition $carPosition)
    {
        $carPosition->adresse_precise = $request->input('adresse_precise');
        $carPosition->motif_infraction = $request->input('motif_infraction');
        $carPosition->lieu = $request->input('lieu');
        $carPosition->nuit = $request->has('meteo') && in_array('nuit', $request->input('meteo', []));
        $carPosition->pluie = $request->has('meteo') && in_array('pluie', $request->input('meteo', []));

        $carPosition->update();

        return response()->json($carPosition);
    }
     */



   public function update(InfractionRequest $request, CarPosition $carPosition)
 {
    // Mise à jour des champs simples
    $carPosition->adresse_precise = $request->input('adresse_precise');
    $carPosition->motif_infraction = $request->input('motif_infraction');
    $carPosition->lieu = $request->input('lieu');

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
