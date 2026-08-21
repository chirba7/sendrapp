<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Redirect;
use Symfony\Component\HttpFoundation\Response;

class IsActiveMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Correction WEB-L-2 : la ligne après le if/else était morte (les
        // deux branches retournent déjà), et Auth::user() n'était jamais
        // gardé contre un utilisateur non authentifié.
        if (!Auth::user()) {
            return Redirect::route('login');
        }

        if (Auth::user()->is_enabled == true) {
            return $next($request);
        }

        return Redirect::to('/modifier/motDePasse');
    }
}
