<?php

namespace App\Http\Responses;

use Laravel\Fortify\Contracts\LoginResponse as LoginResponseContract;
use Laravel\Fortify\Fortify;

/**
 * Page d'arrivée après connexion, selon le rôle :
 *  - Opérateur (7)                       -> Missions
 *  - Autorité communale (3) / préfecture (4) -> Approbations
 *  - les autres rôles                    -> tableau de bord (comportement d'origine)
 *
 * Si l'utilisateur avait demandé une page précise avant d'être renvoyé vers
 * la connexion (lien direct), il y est ramené en priorité.
 */
class LoginResponse implements LoginResponseContract
{
    public function toResponse($request)
    {
        if ($request->wantsJson()) {
            return response()->json(['two_factor' => false]);
        }

        $home = match ((int) $request->user()?->role_id) {
            7 => route('missions.index'),
            3, 4 => route('approbations.index'),
            default => Fortify::redirects('login'),
        };

        return redirect()->intended($home);
    }
}
