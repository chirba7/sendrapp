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
    /**
     * Un signalement envoyé pour approbation n'est plus modifiable par l'agent
     * (compte rendu de direction, § 04). Le refus est renvoyé AVANT la
     * validation des champs : sinon l'agent reçoit « erreur de validation »
     * au lieu de la vraie raison.
     */
    protected function prepareForValidation(): void
    {
        $carPosition = $this->route('carPosition');
        if ($carPosition && $carPosition->soumis_approbation_at) {
            throw new HttpResponseException(response()->json([
                'success' => false,
                'message' => "Ce signalement a été envoyé pour approbation : il n'est plus modifiable.",
                'soumis_le' => $carPosition->soumis_approbation_at,
            ], 423));
        }
    }

    public function rules(): array
    {
        return [
            // Adresse en lecture seule côté agent (23/10/2026) : facultative.
            'adresse_precise' => 'nullable|string|max:255',
            'motif_infraction' => 'required|string|max:255',
            // Justification du motif choisi (zone de texte libre).
            'explication_infraction' => 'nullable|string|max:2000',
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
