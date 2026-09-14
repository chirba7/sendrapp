<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Redirect;
use Symfony\Component\HttpFoundation\Response;

/**
 * Un compte archivé (colonne `users.deleted`) n'est plus affilié à SENDRA :
 * il ne doit plus pouvoir ouvrir le back-office, y compris avec une session
 * déjà ouverte au moment de l'archivage.
 *
 * Placé sur tous les groupes de routes authentifiés — y compris celui de
 * /modifier/motDePasse, que `isActived` ne peut pas protéger puisque c'est
 * sa propre cible de redirection.
 */
class EnsureAccountIsNotArchived
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = Auth::user();

        if ($user && $user->deleted) {
            Auth::guard('web')->logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return Redirect::route('login')->withErrors([
                'email' => "Ce compte n'est plus actif. Contactez un administrateur.",
            ]);
        }

        return $next($request);
    }
}
