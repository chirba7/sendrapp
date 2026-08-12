<?php

namespace App\Http\Middleware;

use Illuminate\Auth\Middleware\Authenticate as Middleware;
use Closure;
use Illuminate\Http\JsonResponse;

class Authenticate extends Middleware
{
    /**
     * Handle an unauthorized user.
     *
     * @param \Illuminate\Http\Request $request
     * @param array $guards
     * @return void
     */
    protected function unauthenticated($request, array $guards)
    {
        throw new \Illuminate\Auth\AuthenticationException(
            'Unauthorized.', $guards, $this->redirectTo($request)
        );
    }

    /**
     * Redirect unauthorized users.
     *
     * @param \Illuminate\Http\Request $request
     * @return string|null
     */
    protected function redirectTo($request)
    {
        if (!$request->expectsJson()) {
            return route('login'); // Adjust the route if needed
        }
    }

    /**
     * Handle the request and return a custom unauthorized response.
     */
    public function handle($request, Closure $next, ...$guards)
    {
        if ($this->auth->guard('api')->guest()) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized: Invalid or missing token.',
            ], 401);
        }

        return $next($request);
    }
}
