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
    /**
     * Le numéro est saisi de bien des façons : « +221 76 621 25 81 »,
     * « 00221766212581 », « 76-621-25-81 ». On ne garde que les chiffres et on
     * retire l'indicatif sénégalais, pour que la validation à 9 chiffres ne
     * refuse plus une saisie correcte mais formatée.
     */
    protected function prepareForValidation(): void
    {
        $tel = $this->input('telephone');
        if (!is_string($tel) && !is_numeric($tel)) {
            return;
        }
        $chiffres = preg_replace('/\\D+/', '', (string) $tel);
        if (preg_match('/^(00221|221)(\\d{9})$/', $chiffres, $m)) {
            $chiffres = $m[2];
        }
        $this->merge(['telephone' => $chiffres]);
    }

    public function rules(): array
    {
        $user = $this->route('user');
        $isCitizen = $user?->role_id == 5;
        return [
            'prenom' => 'required|string|min:3',
            'nom' => 'required|string|min:2',
            'email' => [
                $isCitizen ? 'nullable' : 'required',
                'email',
                Rule::unique('users', 'email')->ignore($user),
            ],
            // Correction WEB-C-1 : sans whitelist, un role_id arbitraire
            // (ex. hors des 4 rôles staff valides) pouvait être assigné.
            'role' => $isCitizen ? 'prohibited' : 'required|in:1,2,3,4,7',
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
            'email.unique' => 'Cette adresse e-mail est déjà utilisée par un autre compte.',
        ];
    }
}
