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
 * 3. Mot de passe changé ou réinitialisé (30/10/2026) : les jetons portent une
 *    empreinte du mot de passe (`pwd`, User::getJWTCustomClaims). Si elle ne
 *    correspond plus, le jeton date d'avant le changement : refusé. Les jetons
 *    émis avant cette correction n'ont pas d'empreinte et restent acceptés
 *    (voir point 2 pour les retirer).
 *
 * Chaque refus porte un `code` (`compte_desactive`, `session_expiree`) que
 * les apps lisent pour renvoyer vers l'écran de connexion.
 *
 * Aucune requête SQL en plus : l'utilisateur est déjà chargé par jwt.auth.
 */
class EnsureApiAccountActive
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();

        if ($user && $user->deleted) {
            return $this->refuser('Ce compte a été désactivé.', 403, 'compte_desactive');
        }

        $payload = JWTAuth::parseToken()->getPayload();

        $limite = config('jwt.refuser_jetons_emis_avant');
        if ($limite && (int) $payload->get('iat') < strtotime($limite)) {
            return $this->refuser('Session expirée, veuillez vous reconnecter.', 401, 'session_expiree');
        }

        $empreinte = $payload->get('pwd');
        if ($user && $empreinte !== null && !hash_equals($user->empreinteMotDePasse(), (string) $empreinte)) {
            return $this->refuser('Votre mot de passe a changé, veuillez vous reconnecter.', 401, 'session_expiree');
        }

        return $next($request);
    }

    private function refuser(string $message, int $statut, string $code)
    {
        try {
            auth('api')->logout(); // liste noire du jeton présenté
        } catch (\Throwable $e) {
            // jeton déjà invalide : rien à faire
        }

        return response()->json(['success' => false, 'code' => $code, 'message' => $message], $statut);
    }
}
