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
        // Correction (copie de SignalementRessource dupliquée depuis
        // backendSendra, jamais alignée — cf AUDIT_SENDRA.md Partie 3) :
        // même bug qu'API-H-1 ($this->photo[0] sur collection vide) et
        // même domaine personnel tiers en dur qu'API-M-4/WEB-H-3.
        $firstPhoto = $this->photo && $this->photo->isNotEmpty() ? $this->photo[0] : null;

        return [
            'signalementId' => $this->id,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'titre' => $this->title,
            'commune' => $this->commune,
            'etat' => $this->etat,
            'formatted_date' => $this->created_at->format('d/m/Y \à H\hi'),
            'image_url' => $firstPhoto ? config('services.backend.storage_url') . '/' . $firstPhoto->filepath : null,
            'image' => $firstPhoto ? $firstPhoto->filepath : null,
        ];
    }
}
