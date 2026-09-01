<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreAgentRequest extends FormRequest
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
            'prenom' => 'required|string|min:3',
            'nom' => 'required|string|min:2',
            'email' => 'required|email',
            // Correction WEB-C-1 : sans whitelist, un role_id arbitraire
            // (ex. hors des 4 rôles staff valides) pouvait être assigné.
            'role' => 'required|in:1,2,3,4',
            // Correction : le numéro est unique en base (contrainte SQL),
            // mais rien ne le vérifiait avant l'enregistrement — un doublon
            // provoquait une erreur 500 (SQLSTATE 23000) au lieu d'un
            // message clair.
            'telephone' => 'required|numeric|regex:/^[0-9]{9}$/|unique:users,telephone',
        ];
    }

    public function messages(): array
    {
        return [
            'telephone.unique' => 'Ce numéro de téléphone est déjà utilisé par un autre compte.',
        ];
    }
}
