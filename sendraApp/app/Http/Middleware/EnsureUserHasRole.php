<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

/**
 * Correction WEB-C-1 : la gestion des comptes (création, modification,
 * changement de rôle) n'était protégée que par `auth:sanctum` + `isActived`
 * + `verified` — aucune vérification que l'appelant est lui-même Admin.
 * Le menu "Comptes" était bien masqué côté Blade pour les non-Admins, mais
 * c'était purement cosmétique : n'importe quel compte actif pouvait
 * atteindre /ajouter ou /dashboard/comptes/{user} directement et se créer
 * ou se promouvoir un compte Admin.
 *
 * Usage : ->middleware('role:1')  (1 = Admin, seul rôle autorisé à gérer
 * les comptes).
 */
class EnsureUserHasRole
{
    public function handle(Request $request, Closure $next, string ...$roles)
    {
        $user = $request->user();

        if (!$user || !in_array((string) $user->role_id, $roles, true)) {
            abort(403, "Vous n'avez pas les droits nécessaires pour accéder à cette page.");
        }

        return $next($request);
    }
}
