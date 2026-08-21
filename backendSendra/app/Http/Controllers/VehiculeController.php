<?php

namespace App\Http\Controllers;

use App\Http\Requests\UpdateCarPositionRequest;
use App\Http\Resources\VehiculeResource;
use App\Models\CarPosition;
use Illuminate\Http\Request;

class VehiculeController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        // Correction API-M-3 : pas de pagination.
        $carPositions = CarPosition::whereNotNull('numero_vehicule')->paginate(20);
        return response()->json(VehiculeResource::collection($carPositions));
    }

    /**
     * Display the specified resource.
     */
    public function show(CarPosition $carPosition)
    {
        return response()->json(new VehiculeResource($carPosition));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateCarPositionRequest $request, CarPosition $carPosition)
{
    // Validation incluse dans UpdateCarPositionRequest

    // Mise à jour des champs principaux
    $fieldsToUpdate = [
        'numero_vehicule' => $request->numero_vehicule ?? $carPosition->numero_vehicule,
        'marque' => $request->marque ?? $carPosition->marque,
        'type_car' => $request->type ?? $carPosition->type_car,
        'model' => $request->model ?? $carPosition->model,
        'categorie' => $request->categorie ?? $carPosition->categorie,
        'couleur' => $request->couleur ?? $carPosition->couleur,
        'entretien' => $request->entretien ?? $carPosition->entretien,
    ];

    // Gestion des champs booléens avec $request->boolean()
    $booleanFields = [
        'defaut_controle_technique',
        'pneumatiques_manquantes',
        'vehicule_immerge',
        'defauts_techniques_irreversibles',
        'vehicule_non_identifiable',
        'vehicule_brule',
        'chassis_non_reparable',
    ];

    foreach ($booleanFields as $field) {
        $fieldsToUpdate[$field] = (bool) $request->input($field, false); // Conversion explicite
    }

    // Mise à jour du modèle
    $carPosition->update($fieldsToUpdate);

    return response()->json([
        'success' => true,
        'data' => new VehiculeResource($carPosition),
    ], 200);
}




    /**
     * Remove the specified resource from storage.
     */
    public function destroy(CarPosition $carPosition)
    {
        $carPosition->delete();

        return response()->json(null, 204);
    }
}
