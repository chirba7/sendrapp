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
            // Nouvelle app : le type de véhicule (bulles Voiture / Moto /
            // Camion) remplace le titre libre. Anciennes versions : titre.
            'titre' => 'required_without:vehicle_kind|nullable|string|max:254',
            'vehicle_kind' => 'nullable|string|in:Voiture,Moto,Camion',
            'description' => 'nullable|string|max:254',
            'adresse_precise' => 'nullable|string|max:255',
            // Hors ligne, la commune (géocodage inverse, qui exige le réseau)
            // peut manquer : un signalement valide ne doit pas être refusé
            // pour autant. L'app tente de la compléter avant la synchro.
            'commune' => 'nullable|string',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            // Correction perf : aucune limite de taille sur le payload
            // base64 entrant. Abaissée le 29/10/2026 de 15M à 5,6M caractères
            // (≈ 4 Mo décodés) : une photo de 1600 px redimensionnée par l'app
            // pèse moins de 1 Mo, et chaque Mo accepté coûte plusieurs Mo de
            // RAM côté PHP (texte, binaire, image décompressée par GD).
            // `image` (une seule photo) : anciennes versions de l'app.
            // `photos` (une par angle) : app avec mode hors ligne.
            'image' => 'required_without:photos|string|max:5600000',
            'photos' => (int) auth()->user()->role_id === 5
                ? 'required_without:image|array|size:1'
                : 'required_without:image|array|min:1|max:5',
            'photos.*.position' => (int) auth()->user()->role_id === 5
                ? 'required|string|in:vue_ensemble'
                : 'required|string|in:vue_ensemble,devant,derriere,cote_gauche,cote_droit|distinct',
            'photos.*.image' => 'required|string|max:5600000',
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
