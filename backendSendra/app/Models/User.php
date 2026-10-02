<?php

namespace App\Models;

use Tymon\JWTAuth\Contracts\JWTSubject;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Notifications\Notifiable;
use Illuminate\Foundation\Auth\User as Authenticatable;

class User extends Authenticatable implements JWTSubject
{
    use HasFactory, Notifiable;

    public function attendanceEnrollment()
    {
        return $this->hasOne(AttendanceEnrollment::class);
    }

    // Correction API-C-4 : empêche /me (et toute sérialisation JSON de
    // User) de renvoyer le hash du mot de passe et les secrets 2FA.
    protected $hidden = [
        'password',
        'remember_token',
        'two_factor_secret',
        'two_factor_recovery_codes',
    ];

    // Rest omitted for brevity

    /**
     * Get the identifier that will be stored in the subject claim of the JWT.
     *
     * @return mixed
     */
    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

    /**
     * Return a key value array, containing any custom claims to be added to the JWT.
     *
     * @return array
     */
    public function getJWTCustomClaims()
    {
        return [];
    }

    /**
     * Comptes encore affiliés à SENDRA.
     *
     * La colonne `deleted` est posée par le back-office quand un compte est
     * supprimé. Elle vaut NULL sur tous les comptes historiques : la
     * condition doit couvrir NULL explicitement, `deleted != 1` les
     * exclurait aussi.
     */
    public function scopeNonArchives($query)
    {
        return $query->where(function ($requete) {
            $requete->whereNull('deleted')->orWhere('deleted', false);
        });
    }
}
