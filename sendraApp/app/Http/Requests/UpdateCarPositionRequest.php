<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCarPositionRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'numero_vehicule' => 'required|string|max:255',
            'marque' => 'required|string|max:255',
            'type' => 'required|string|max:255',
            'model' => 'required|string|max:255',
            'categorie' => 'required|string|max:255',
            'couleur' => 'required|string|max:255',
            'entretien' => 'required|string|in:BON,MOYEN,DEGRADE',
            'pays_etranger' => 'required|string|in:OUI,NON',
            'defaut_controle_technique' => 'nullable',
            'pneumatiques_manquantes' => 'nullable',
            'vehicule_immerge' => 'nullable',
            'defauts_techniques_irreversibles' => 'nullable',
            'vehicule_non_identifiable' => 'nullable',
            'vehicule_brule' => 'nullable',
            'chassis_non_reparable' => 'nullable',
        ];
    }
}
