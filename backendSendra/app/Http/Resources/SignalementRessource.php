<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SignalementRessource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        // Correction API-H-1 : $this->photo est une Collection hasMany,
        // toujours "truthy" même vide — accéder à [0] plantait (500) sur
        // tout signalement sans photo. Correction API-M-4/WEB-H-3 (URL) :
        // domaine personnel tiers en dur remplacé par APP_URL de cette app.
        $firstPhoto = $this->photo && $this->photo->isNotEmpty() ? $this->photo[0] : null;

        return [
            'signalementId' => $this->id,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'titre' => $this->title,
            'commune' => $this->commune,
            'etat' => $this->etat,
            'is_approve' => (bool) $this->is_approve,
            'dommages_saisis' => !empty($this->dommage_image),
            'formatted_date' => $this->created_at->format('d/m/Y \à H\hi'),
            // Utilise l'hôte réellement appelé par le téléphone (par exemple
            // 192.168.x.x:8000), au lieu de APP_URL=localhost qui n'est
            // joignable que depuis la machine du backend.
            'image_url' => $firstPhoto
                ? $request->getSchemeAndHttpHost() . '/storage/' . $firstPhoto->filepath
                : null,
            'image' => $firstPhoto ? $firstPhoto->filepath : null,
            // Toutes les photos (une par angle), dans l'ordre d'enregistrement
            // — la vue d'ensemble d'abord. image_url/image restent pour les
            // écrans et versions de l'app qui n'affichent qu'une photo.
            'images' => $this->photo
                ? $this->photo->sortBy('id')->values()->map(fn ($p) => [
                    'url' => $request->getSchemeAndHttpHost() . '/storage/' . $p->filepath,
                    'position' => $p->position,
                ])->all()
                : [],
        ];
    }
}
