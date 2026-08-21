<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CarPosition extends Model
{
    use HasFactory;

    // Correction WEB-M-2 : $guarded = [] autorisait l'assignation en masse
    // de N'IMPORTE QUELLE colonne (y compris is_approve, is_deleted...).
    // Non exploité aujourd'hui (aucun create()/fill() piloté par la requête
    // brute), mais dangereux dès qu'un futur endpoint l'utiliserait. Liste
    // exhaustive des colonnes réelles de `car_positions` (voir migrations).
    protected $fillable = [
        'description', 'latitude', 'longitude', 'title', 'uuid',
        'user_id', 'agent_id', 'numero_vehicule', 'secteur',
        'date_pv_enelevement', 'date_enlevement', 'adresse_precise',
        'statut', 'qrcode', 'qrcode_file', 'pv_enlevement', 'commune',
        'etat', 'lieu', 'pays_etranger', 'step', 'model', 'type_car',
        'entretien', 'categorie', 'couleur', 'motif_enlevement',
        'motif_infraction', 'lieu_enlevement', 'nom_responsable_mef',
        'enleve', 'marque', 'motife_approbation', 'is_approve',
        'is_deleted', 'defaut_controle_technique', 'pneumatiques_manquantes',
        'vehicule_immerge', 'defauts_techniques_irreversibles',
        'vehicule_non_identifiable', 'vehicule_brule', 'chassis_non_reparable',
        'sticker', 'nuit', 'pluie', 'dommage_image',
    ];

    public function photo()
    {
        return $this->hasMany(CarPhoto::class, 'card_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
    public function agent()
    {
        return $this->belongsTo(User::class, 'agent_id');
    }
}
