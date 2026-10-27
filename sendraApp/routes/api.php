<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

// Formulaire de contact du site web SENDRA. Appelé uniquement par le serveur
// du site (jamais par le navigateur), avec l'en-tête X-Sendra-Site-Key.
// Limité à 20 envois par minute et par adresse appelante.
Route::post('/site/contact', [\App\Http\Controllers\ContactMessageController::class, 'storeFromSite'])
    ->middleware('throttle:20,1')
    ->name('site.contact.store');
