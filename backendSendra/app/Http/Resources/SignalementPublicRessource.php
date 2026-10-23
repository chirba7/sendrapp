<?php

namespace App\Http\Resources;

use App\Support\AvancementSignalement;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Auth;

/**
 * Vue publique d'un signalement (liste « Autres signalements » et carte de
 * l'application citoyen) : aucune donnée personnelle ni de constatation.
 */
class SignalementPublicRessource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $photo = $this->photo
            ? $this->photo->where('position', '!=', 'agent_constat')->sortBy('id')->first()
            : null;

        return [
            'signalementId' => $this->id,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'titre' => $this->vehicle_kind ?: $this->title,
            'vehicle_kind' => $this->vehicle_kind,
            'commune' => $this->commune,
            'etat' => AvancementSignalement::etatAffiche($this->resource),
            'formatted_date' => $this->created_at?->format('d/m/Y \à H\hi'),
            'image_url' => $photo ? $request->getSchemeAndHttpHost().'/storage/'.$photo->filepath : null,
            'est_mien' => (int) $this->user_id === (int) Auth::id(),
            'public' => true,
            'avancement' => AvancementSignalement::pour($this->resource),
        ];
    }
}
