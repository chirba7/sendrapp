<?php

namespace App\Http\Requests;


use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

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
            'defaut_controle_technique' => 'nullable|boolean',
            'pneumatiques_manquantes' => 'nullable|boolean',
            'vehicule_immerge' => 'nullable|boolean',
            'defauts_techniques_irreversibles' => 'nullable|boolean',
            'vehicule_non_identifiable' => 'nullable|boolean',
            'vehicule_brule' => 'nullable|boolean',
            'chassis_non_reparable' => 'nullable|boolean',
	    
        ];
    }
    public function failedValidation(Validator $validator)
    {
        throw new HttpResponseException(response()->json([
            'success' => false,
            'status_code' => 422,
            'error' => true,
            'message' => 'erreur de validation',
            'errorList' => $validator->errors()
        ]));
    }
}
