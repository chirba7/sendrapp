<?php

namespace App\Exceptions;

use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Auth\AuthenticationException;
use Symfony\Component\HttpKernel\Exception\MethodNotAllowedHttpException;
use Throwable;

use Tymon\JWTAuth\Exceptions\TokenExpiredException;
use Tymon\JWTAuth\Exceptions\TokenInvalidException;
use Tymon\JWTAuth\Exceptions\JWTException;

class Handler extends ExceptionHandler
{
    /**
     * The list of the inputs that are never flashed to the session on validation exceptions.
     *
     * @var array<int, string>
     */
    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    /**
     * Register the exception handling callbacks for the application.
     */
    public function register(): void
    {
        // Handle MethodNotAllowedHttpException
        $this->renderable(function (MethodNotAllowedHttpException $e, $request) {
            if (config('app.debug') === false) {
                return response()->view('errors.500', [], 500);
            }

            if ($request->expectsJson()) {
                return response()->json([
                    'message' => 'Method Not Allowed. Please check the HTTP method for this route.',
                ], 405); // 405 Method Not Allowed
            }
        });

        $this->reportable(function (Throwable $e) {
            //
        });
    }

    /**
     * Render an exception into an HTTP response.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Throwable  $exception
     * @return \Illuminate\Http\Response
     */
    public function render($request, Throwable $exception)
    {
        // Handle JWT exceptions and provide a JSON response
        if ($exception instanceof TokenExpiredException) {
            return response()->json([
                'success' => false,
                'message' => 'Token has expired.'
            ], 401);
        }

        if ($exception instanceof TokenInvalidException) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid token.'
            ], 401);
        }

        if ($exception instanceof JWTException) {
            return response()->json([
                'success' => false,
                'message' => 'Token is required.'
            ], 401);
        }

        // Default behavior for other exceptions
        return parent::render($request, $exception);
    }
    /**
     * Handle unauthenticated exceptions.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Illuminate\Auth\AuthenticationException  $exception
     * @return \Illuminate\Http\Response
     */
    /**
     * Handle unauthenticated exceptions.
     */
    /**
     * Convert unauthorized exceptions into JSON responses.
     */
    protected function unauthenticated($request, AuthenticationException $exception)
    {
        return $request->expectsJson()
            ? response()->json(['success' => false, 'message' => 'Non autorisé.'], 401)
            : response()->json(['success' => false, 'message' => 'Non autorisé.'], 401);
    }
    
}
