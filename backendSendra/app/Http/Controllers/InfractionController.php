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
        // Un signalement envoyé pour approbation n'est plus modifiable par
        // l'agent (§ 04 du compte rendu). Restreint au rôle Agent : un
        // superviseur doit pouvoir corriger après coup.
        if ((int) auth()->user()->role_id === 2 && $carPosition->soumis_approbation_at) {
            return response()->json([
                'success' => false,
                'message' => 'Ce signalement a été envoyé pour approbation : il n\'est plus modifiable.',
                'soumis_le' => $carPosition->soumis_approbation_at,
            ], 423);
        }

    // Mise à jour des champs simples
    $carPosition->adresse_precise = $request->input('adresse_precise');
    $carPosition->motif_infraction = $request->input('motif_infraction');
    // Zone de texte justifiant le motif choisi : on conserve la valeur
    // existante si le client ne l'envoie pas, pour ne pas l'effacer.
    $carPosition->explication_infraction = $request->input('explication_infraction', $carPosition->explication_infraction);
    if ((int) auth()->user()->role_id === 2 && !$carPosition->agent_id) {
        $carPosition->agent_id = auth()->id();
    }

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
