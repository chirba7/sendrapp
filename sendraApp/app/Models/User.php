<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Fortify\TwoFactorAuthenticatable;
use Laravel\Jetstream\HasProfilePhoto;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;
    use HasFactory;
    use HasProfilePhoto;
    use Notifiable;
    use TwoFactorAuthenticatable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
        'two_factor_recovery_codes',
        'two_factor_secret',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
    ];

    /**
     * The accessors to append to the model's array form.
     *
     * @var array<int, string>
     */
    protected $appends = [
        'profile_photo_url',
    ];
    public function role()
    {
        return $this->belongsTo(Role::class);
    }

    /**
     * Comptes encore affiliés à SENDRA.
     *
     * La colonne `deleted` existe depuis la migration d'origine des `users`
     * mais n'était lue nulle part : elle sert désormais d'archivage. Un vrai
     * DELETE est exclu — `car_positions.user_id` et `car_positions.agent_id`
     * sont en ON DELETE CASCADE, supprimer la ligne effacerait donc tous les
     * signalements du compte, leurs photos et leurs dommages.
     *
     * `deleted` vaut NULL sur tous les comptes existants : la condition doit
     * couvrir NULL explicitement (`deleted != 1` exclurait les NULL en SQL).
     */
    public function scopeNonArchives($query)
    {
        return $query->where(function ($requete) {
            $requete->whereNull('deleted')->orWhere('deleted', false);
        });
    }

    public function scopeArchives($query)
    {
        return $query->where('deleted', true);
    }

    public function estArchive(): bool
    {
        return (bool) $this->deleted;
    }
}
