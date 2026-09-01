<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateAgentRequest extends FormRequest
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
            // Correction : même souci qu'à la création (StoreAgentRequest) —
            // ignore() exclut le compte en cours de modification lui-même.
            'telephone' => [
                'required', 'numeric', 'regex:/^[0-9]{9}$/',
                Rule::unique('users', 'telephone')->ignore($this->route('user')),
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'telephone.unique' => 'Ce numéro de téléphone est déjà utilisé par un autre compte.',
        ];
    }
}
