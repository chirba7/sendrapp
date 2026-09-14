<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\Exceptions\HttpResponseException;

class StoreCarPositionRequest extends FormRequest
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
            'titre' => 'required|string',
            'commune' => 'required|string',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            // Correction perf : aucune limite de taille sur le payload
            // base64 entrant. ~15M caractères ≈ 11 Mo décodés.
            // `image` (une seule photo) : anciennes versions de l'app.
            // `photos` (une par angle) : app avec mode hors ligne.
            'image' => 'required_without:photos|string|max:15000000',
            'photos' => 'required_without:image|array|min:1|max:5',
            'photos.*.position' => 'required|string|in:vue_ensemble,devant,derriere,cote_gauche,cote_droit|distinct',
            'photos.*.image' => 'required|string|max:15000000',
            // Clé de déduplication : un envoi rejoué (synchro hors ligne,
            // réseau instable) ne doit pas créer de doublon.
            'uuid' => 'nullable|string|max:254',
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
