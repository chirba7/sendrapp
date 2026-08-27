<?php

use App\Http\Controllers\ApprobationController;
use App\Http\Controllers\AuthControllerApi;
use App\Http\Controllers\CarPositionController;
use App\Http\Controllers\DommagesController;
use App\Http\Controllers\EnlevementController;
use App\Http\Controllers\InfractionController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\VehiculeController;
use App\Http\Controllers\SMSController;

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

// Public routes (No authentication required)
Route::group([
    'middleware' => 'api',
], function () {
    // Endpoint de découverte réseau : l'app mobile scanne le sous-réseau
    // local pour retrouver l'IP du backend Docker (qui change à chaque bail
    // DHCP) — cette signature lui permet de distinguer ce serveur d'un
    // autre appareil qui répondrait par hasard sur le port 8000.
    Route::get('/ping', fn () => response()->json(['app' => 'sendra-backend']));

    // Authentication
    Route::post('/login', [AuthControllerApi::class, 'login'])->name('login');
    Route::post('/verify-code', [AuthControllerApi::class, 'verifyCode']);
    Route::post('/register', [AuthControllerApi::class, 'register']);

    // Correction API-C-5 : ces deux routes n'ont plus de clé statique en
    // entrée (extractible de l'app mobile, donc sans valeur de protection
    // réelle) — le rate-limiting protège maintenant contre l'énumération.
    Route::middleware('throttle:10,1')->group(function () {
        Route::post('/send-verification-code', [AuthControllerApi::class, 'sendVerificationCode']);
        Route::post('/check-phone', [AuthControllerApi::class, 'checkPhone']);
    });
});

// Protected routes (Authentication required with JWT)
Route::middleware('jwt.auth')->group(function () {
    // Authentication-related routes
    Route::post('/logout', [AuthControllerApi::class, 'logout']);
    Route::post('/refresh', [AuthControllerApi::class, 'refresh']);
    Route::post('/me', [AuthControllerApi::class, 'me']);
    Route::post('/delete-user', [AuthControllerApi::class, 'deleteUser']);

    // Signalement routes ouvertes à tout citoyen connecté (auto-scopées à
    // son propre compte côté contrôleur : store()/voirSignalements()).
    Route::get('/voirSignalements', [CarPositionController::class, 'voirSignalements']);
    Route::post('/faireSignalement', [CarPositionController::class, 'store']);

    // Ajustement (2026-08-27) : listerSignalements/listerSignalement sont un
    // fil public (accueil + carto de l'app mobile, cf. home_screen.dart et
    // cartography_screen.dart) — voulu accessible à tout citoyen connecté,
    // pas seulement au personnel. Sorti du groupe role:1,2,3,4 ci-dessous
    // suite à un test en environnement de staging qui a montré que ça
    // cassait l'écran d'accueil pour le rôle citoyen (role_id=5).
    Route::get('/listerSignalements', [CarPositionController::class, 'listerSignalements']);
    Route::get('/listerSignalement/{carPosition}', [CarPositionController::class, 'listerSignalement']);

    // Correction API-C-3 : routes "métier" réservées au personnel
    // (Admin=1, Agent=2, Autorité commune=3, Autorité préfecture=4).
    // Auparavant accessibles à n'importe quel citoyen auto-inscrit (role_id=5).
    Route::middleware('role:1,2,3,4')->group(function () {
        Route::delete('/supprimerSignalement/{carPosition}', [CarPositionController::class, 'destroy']);

        // Vehicule routes
        Route::put('/vehicule/{carPosition}', [VehiculeController::class, 'update']);
        Route::get('/vehicule/{carPosition}', [VehiculeController::class, 'show']);
        Route::get('/vehicule', [VehiculeController::class, 'index']);

        // Infraction routes
        Route::get('/infraction', [InfractionController::class, 'index']);
        Route::get('/infraction/{carPosition}', [InfractionController::class, 'show']);
        Route::put('/infraction/{carPosition}', [InfractionController::class, 'update']);

        // Enlevement routes
        Route::put('/enlevement/{carPosition}', [EnlevementController::class, 'ajouterEnlevement']);
        Route::get('/enlevement/{carPosition}', [EnlevementController::class, 'obtenirEnlevement']);

        // Dommages routes
        Route::put('/enregistrerDommages/{carPosition}', [DommagesController::class, 'enregistrerDommages']);
        Route::get('/voirDommages/{vehicleId}', [DommagesController::class, 'voirDommages']);

        // Statistiques
        Route::get('/statistiques', [CarPositionController::class, 'statistiques']);
    });

    // Correction ACL : l'approbation est réservée à Admin/Autorité commune/
    // Autorité préfecture — le spec fonctionnel (AUDIT_SENDRA.md §1.1)
    // exclut explicitement l'Agent ("traite les signalements, pas d'accès
    // à l'approbation"), qui pouvait pourtant approuver comme n'importe
    // quel autre rôle staff avant ce correctif.
    Route::middleware('role:1,3,4')->group(function () {
        Route::put('/soumettreApprobation/{carPosition}', [ApprobationController::class, 'soumettreApprobation']);
        Route::get('/motifsApprobation/{carPosition}', [ApprobationController::class, 'motifsApprobation']);
    });
});
