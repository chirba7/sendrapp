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
            'role' => 'required',
            'telephone' => 'required|numeric|regex:/^[0-9]{9}$/',
        ];
    }
}
