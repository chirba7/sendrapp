<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class VehiculeResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'numero' => $this->numero_vehicule ? $this->numero_vehicule : null,
            'marque' => $this->marque ? $this->marque : null,
            'type' => $this->type_car ? $this->type_car : null,
            'model' => $this->model ? $this->model : null,
            'categorie' => $this->categorie ? $this->categorie : null,
            'couleur' => $this->couleur ? $this->couleur : null,
            'entretien' => $this->entretien ? $this->entretien : null,
            'pays_etranger' => $this->pays_etranger,
            'defaut_controle_technique' => $this->defaut_controle_technique,
            'pneumatiques_manquantes' => $this->pneumatiques_manquantes,
            'vehicule_immerge' => $this->vehicule_immerge,
            'defauts_techniques_irreversibles' => $this->defauts_techniques_irreversibles,
            'vehicule_non_identifiable' => $this->vehicule_non_identifiable,
            'vehicule_brule' => $this->vehicule_brule,
            'chassis_non_reparable' => $this->chassis_non_reparable,
        ];
    }
}
