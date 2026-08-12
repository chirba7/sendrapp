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
        return [
            'signalementId' => $this->id,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'titre' => $this->title,
            'commune' => $this->commune,
            'etat' => $this->etat,
            'formatted_date' => $this->created_at->format('d/m/Y \à H\hi'),
            'image_url' => $this->photo ? 'https://sendra.mouhamadoufaye.tech/storage/' . $this->photo[0]->filepath : null,
            'image' => $this->photo ? $this->photo[0]->filepath : null,
        ];
    }
}
