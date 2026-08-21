<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

class InfractionRequest extends FormRequest
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
            'adresse_precise' => 'required|string|max:255',
            'motif_infraction' => 'required|string|max:255',
            // Correction API-H-4 : la colonne DB est NOT NULL (avec défaut
            // 'PUBLIC') — 'nullable' autorisait un `null` explicite envoyé
            // par le client et faisait planter l'insertion SQL. 'sometimes'
            // permet toujours d'omettre le champ (le défaut DB s'applique)
            // sans jamais accepter une valeur null explicite.
            'lieu' => 'sometimes|in:PUBLIC,PRIVE',
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
