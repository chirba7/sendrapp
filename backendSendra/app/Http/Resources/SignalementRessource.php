<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use App\Support\HistoriqueSignalement;
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
        $citizenPhotos = $this->photo ? $this->photo->where('position', '!=', 'agent_constat') : collect();
        $agentPhotos = $this->photo ? $this->photo->where('position', 'agent_constat') : collect();
        $firstPhoto = $citizenPhotos->first();

        return [
            'signalementId' => $this->id,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'titre' => $this->title,
            'description' => $this->description,
            'commune' => $this->commune,
            'etat' => $this->non_removed_at && !in_array($this->etat, ['ENLEVE', 'REJETE'], true) ? 'NON RESOLU' : $this->etat,
            'non_removal_reason' => $this->non_removal_reason,
            'non_removed_at' => $this->non_removed_at,
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
            'images' => $citizenPhotos
                ? $citizenPhotos->sortBy('id')->values()->map(fn ($p) => [
                    'url' => $request->getSchemeAndHttpHost() . '/storage/' . $p->filepath,
                    'position' => $p->position,
                    // 'citoyen' (jointe au signalement) ou 'agent' (prise
                    // pendant la constatation).
                    'source' => $p->source,
                ])->all()
                : [],
            // Photos prises par l'agent pendant la constatation, séparées de
            // celles du citoyen (compte rendu de direction, § 03).
            'photos_agent' => $agentPhotos->sortBy('id')->values()->map(fn ($p) => [
                'url' => $request->getSchemeAndHttpHost().'/storage/'.$p->filepath,
                'position' => $p->position,
            ])->all(),
            'pieces_manquantes' => $this->pieces_manquantes,
            'motif_approbation' => $this->motife_approbation,
            'numero_vehicule' => $this->numero_vehicule,
            'marque' => $this->marque,
            'model' => $this->model,
            'type' => $this->type_car,
            'vehicle_kind' => $this->vehicle_kind,
            'categorie' => $this->categorie,
            'entretien' => $this->entretien,
            'adresse_precise' => $this->adresse_precise,
            'motif_infraction' => $this->motif_infraction,
            'explication_infraction' => $this->explication_infraction,
            // Envoyé pour approbation : l'agent ne peut plus le modifier.
            'verrouille' => (bool) $this->soumis_approbation_at,
            'soumis_approbation_at' => $this->soumis_approbation_at,
            // Avancement complet, pour l'affichage du suivi au citoyen.
            'historique' => HistoriqueSignalement::pour($this->resource),
        ];
    }
}
