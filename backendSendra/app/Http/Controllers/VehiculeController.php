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
        // Un signalement envoyé pour approbation n'est plus modifiable par
        // l'agent (compte rendu de direction, § 04). Restreint au rôle Agent :
        // un superviseur doit pouvoir corriger une donnée après coup.
        if ((int) auth()->user()->role_id === 2 && $carPosition->soumis_approbation_at) {
            return response()->json([
                'success' => false,
                'message' => 'Ce signalement a été envoyé pour approbation : il n\'est plus modifiable.',
                'soumis_le' => $carPosition->soumis_approbation_at,
            ], 423);
        }

    // Validation incluse dans UpdateCarPositionRequest

    // Mise à jour des champs principaux
    $fieldsToUpdate = [
        'numero_vehicule' => $request->numero_vehicule ?? $carPosition->numero_vehicule,
        'marque' => $request->marque ?? $carPosition->marque,
        'type_car' => $request->type ?? $carPosition->type_car,
        'vehicle_kind' => $request->input('vehicle_kind', $carPosition->vehicle_kind),
        'model' => $request->model ?? $carPosition->model,
        'categorie' => $request->categorie ?? $carPosition->categorie,
        'couleur' => $request->couleur ?? $carPosition->couleur,
        'entretien' => $request->entretien ?? $carPosition->entretien,
        'pays_etranger' => $request->pays_etranger ?? $carPosition->pays_etranger,
        'autre_situation' => $request->input('autre_situation', $carPosition->autre_situation),
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
    if ((int) auth()->user()->role_id === 2 && !$carPosition->agent_id) {
        $fieldsToUpdate['agent_id'] = auth()->id();
    }
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
