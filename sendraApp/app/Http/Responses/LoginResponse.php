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

        // `intended()` rejoue l'adresse demandée avant la connexion. Or un
        // visiteur non connecté est systématiquement renvoyé depuis /dashboard
        // (ou /), qui se retrouve mémorisé : la page propre au rôle était donc
        // toujours écrasée par le tableau de bord. On n'honore que les liens
        // profonds, c'est-à-dire tout sauf ces adresses génériques.
        $memorisee = $request->session()?->pull('url.intended');
        $generiques = array_map(
            fn ($u) => rtrim($u, '/'),
            [url('/'), url('/dashboard'), url('/login'), Fortify::redirects('login')]
        );

        $profonde = $memorisee && !in_array(rtrim($memorisee, '/'), $generiques, true);

        return redirect()->to(
            $profonde && $this->accessible($memorisee, (int) $request->user()->role_id)
                ? $memorisee
                : $home
        );
    }

    /**
     * Le rôle connecté a-t-il le droit d'ouvrir cette adresse ?
     *
     * Sans ce contrôle, un lien profond mémorisé avant la connexion renvoie
     * l'utilisateur sur une page interdite : il se connecte et reçoit un 403,
     * sans comprendre pourquoi.
     */
    private function accessible(string $url, int $roleId): bool
    {
        try {
            $chemin = parse_url($url, PHP_URL_PATH) ?: '/';
            $route = app('router')->getRoutes()
                ->match(\Illuminate\Http\Request::create($chemin, 'GET'));

            foreach ($route->gatherMiddleware() as $middleware) {
                if (is_string($middleware) && str_starts_with($middleware, 'role:')) {
                    return in_array((string) $roleId, explode(',', substr($middleware, 5)), true);
                }
            }

            return true;
        } catch (\Throwable $e) {
            // Adresse inconnue ou non résolue : on retombe sur la page du rôle.
            return false;
        }
    }
}
