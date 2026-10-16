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
        return [
            'prenom' => 'required|string|min:3',
            'nom' => 'required|string|min:2',
            'email' => 'required|email',
            // Correction WEB-C-1 : sans whitelist, un role_id arbitraire
            // (ex. hors des 4 rôles staff valides) pouvait être assigné.
            'role' => 'required|in:1,2,3,4,7',
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
