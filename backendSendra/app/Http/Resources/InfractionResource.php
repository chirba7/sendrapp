<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class InfractionResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'adresse_precise' => $this->adresse_precise,
            'motif_infraction' => $this->motif_infraction,
            'lieu' => $this->lieu,
            'nuit' => $this->nuit,
            'pluie' => $this->pluie,
        ];
    }
}
