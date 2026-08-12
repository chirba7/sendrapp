<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

/**
 * Correction API-C-3 : jusqu'ici aucune route "métier" (véhicule,
 * infraction, approbation, enlèvement, dommages, suppression de
 * signalement, listing global) ne vérifiait le rôle de l'utilisateur —
 * seul `jwt.auth` prouvait qu'il était connecté, pas ce qu'il avait le
 * droit de faire. N'importe quel citoyen auto-inscrit (role_id=5) pouvait
 * donc approuver une saisie ou supprimer le signalement d'un autre.
 *
 * Usage : ->middleware('role:1,2,3,4')  (Admin, Agent, Autorité commune,
 * Autorité préfecture — tout sauf le rôle citoyen 5).
 */
class EnsureUserHasRole
{
    public function handle(Request $request, Closure $next, string ...$roles)
    {
        $user = $request->user();

        if (!$user || !in_array((string) $user->role_id, $roles, true)) {
            return response()->json([
                'success' => false,
                'message' => "Vous n'avez pas les droits nécessaires pour effectuer cette action.",
            ], 403);
        }

        return $next($request);
    }
}
