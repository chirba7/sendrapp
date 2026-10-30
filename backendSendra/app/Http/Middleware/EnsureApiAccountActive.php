<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Tymon\JWTAuth\Facades\JWTAuth;

/**
 * Correction sécurité (audit du 29/10/2026), à placer après `jwt.auth`.
 *
 * 1. Compte archivé : `login()` refusait déjà un compte supprimé depuis le
 *    back-office (`users.deleted`), mais un jeton obtenu AVANT l'archivage
 *    restait accepté sur toutes les routes — et les jetons n'expiraient pas.
 *    Un ancien collaborateur gardait donc l'accès à l'API. Le jeton est
 *    maintenant refusé (403, comme le module de pointage le faisait déjà)
 *    et mis sur liste noire.
 *
 * 2. Jetons émis avant une date (JWT_REFUSER_JETONS_EMIS_AVANT, AAAA-MM-JJ) :
 *    refusés. Sert d'abord à la transition — les jetons émis avant JWT_TTL
 *    n'ont pas d'expiration et restent acceptés tant que la date est vide,
 *    pour ne pas déconnecter d'un coup les utilisateurs des apps actuelles
 *    (qui ne renvoient pas vers l'écran de connexion sur un 401) ; on la
 *    renseigne une fois les apps mises à jour. Sert ensuite de coupe-circuit
 *    (fuite de JWT_SECRET, vol de jetons) : tout le monde se reconnecte.
 *    La date d'émission (`iat`) est le seul critère fiable : au décodage,
 *    tymon/jwt-auth ajoute une expiration aux jetons qui n'en ont pas.
 *
 * Aucune requête SQL en plus : l'utilisateur est déjà chargé par jwt.auth.
 */
class EnsureApiAccountActive
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();

        if ($user && $user->deleted) {
            return $this->refuser('Ce compte a été désactivé.', 403);
        }

        $limite = config('jwt.refuser_jetons_emis_avant');
        if ($limite) {
            $iat = (int) JWTAuth::parseToken()->getPayload()->get('iat');
            if ($iat < strtotime($limite)) {
                return $this->refuser('Session expirée, veuillez vous reconnecter.', 401);
            }
        }

        return $next($request);
    }

    private function refuser(string $message, int $statut)
    {
        try {
            auth('api')->logout(); // liste noire du jeton présenté
        } catch (\Throwable $e) {
            // jeton déjà invalide : rien à faire
        }

        return response()->json(['success' => false, 'message' => $message], $statut);
    }
}
