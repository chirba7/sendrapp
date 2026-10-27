<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Message reçu via le formulaire de contact du site web SENDRA.
 */
class ContactMessage extends Model
{
    public const STATUTS = [
        'nouveau' => 'Nouveau',
        'en_cours' => 'En cours',
        'traite' => 'Traité',
    ];

    protected $fillable = [
        'nom', 'email', 'telephone', 'objet', 'message',
        'statut', 'note_interne', 'lu_le', 'traite_le', 'traite_par',
        'ip', 'user_agent',
    ];

    protected $casts = [
        'lu_le' => 'datetime',
        'traite_le' => 'datetime',
    ];

    public function traitePar()
    {
        return $this->belongsTo(User::class, 'traite_par');
    }

    public function getStatutLibelleAttribute(): string
    {
        return self::STATUTS[$this->statut] ?? $this->statut;
    }
}
