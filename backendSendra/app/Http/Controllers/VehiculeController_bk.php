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
        $carPositions = CarPosition::whereNotNull('numero_vehicule')->get();
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
     * Show the form for editing the specified resource.
     */

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateCarPositionRequest $request, CarPosition $carPosition)
    {
        $carPosition->numero_vehicule = $request->numero_vehicule ?? $carPosition->numero_vehicule;
        $carPosition->marque = $request->marque ?? $carPosition->marque;
        $carPosition->type_car = $request->type ?? $carPosition->type_car;
        $carPosition->model = $request->model ?? $carPosition->model;
        $carPosition->categorie = $request->categorie ?? $carPosition->categorie;
        $carPosition->couleur = $request->couleur ?? $carPosition->couleur;
        $carPosition->entretien = $request->entretien ?? $carPosition->entretien;

	$carPosition->defaut_controle_technique = $request->has('defaut_controle_technique');
	//$carPosition->defaut_controle_technique = 0;

        $carPosition->pneumatiques_manquantes = $request->has('pneumatiques_manquantes');
        $carPosition->vehicule_immerge = $request->has('vehicule_immerge');
        $carPosition->defauts_techniques_irreversibles = $request->has('defauts_techniques_irreversibles');
        $carPosition->vehicule_non_identifiable = $request->has('vehicule_non_identifiable');
        $carPosition->vehicule_brule = $request->has('vehicule_brule');
        $carPosition->chassis_non_reparable = $request->has('chassis_non_reparable');

        $carPosition->update();

        return response()->json([200, new VehiculeResource($carPosition)]);
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
