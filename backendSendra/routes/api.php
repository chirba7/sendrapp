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
    // Authentication
    Route::post('/login', [AuthControllerApi::class, 'login'])->name('login');
    Route::post('/send-verification-code', [AuthControllerApi::class, 'sendVerificationCode']);
    Route::post('/check-phone', [AuthControllerApi::class, 'checkPhone']);
    Route::post('/verify-code', [AuthControllerApi::class, 'verifyCode']);
    Route::post('/register', [AuthControllerApi::class, 'register']);
});

// Protected routes (Authentication required with JWT)
Route::middleware('jwt.auth')->group(function () {
    // Authentication-related routes
    Route::post('/logout', [AuthControllerApi::class, 'logout']);
    Route::post('/refresh', [AuthControllerApi::class, 'refresh']);
    Route::post('/me', [AuthControllerApi::class, 'me']);
    Route::post('/delete-user', [AuthControllerApi::class, 'deleteUser']);
    // Signalement routes
    Route::get('/listerSignalements', [CarPositionController::class, 'listerSignalements']);
    Route::get('/listerSignalement/{carPosition}', [CarPositionController::class, 'listerSignalement']);
    Route::get('/voirSignalements', [CarPositionController::class, 'voirSignalements']);
    Route::post('/faireSignalement', [CarPositionController::class, 'store']);
    Route::delete('/supprimerSignalement/{carPosition}', [CarPositionController::class, 'destroy']);

    // Vehicule routes
    Route::put('/vehicule/{carPosition}', [VehiculeController::class, 'update']);
    Route::get('/vehicule/{carPosition}', [VehiculeController::class, 'show']);
    Route::get('/vehicule', [VehiculeController::class, 'index']);

    // Infraction routes
    Route::get('/infraction', [InfractionController::class, 'index']);
    Route::get('/infraction/{carPosition}', [InfractionController::class, 'show']);
    Route::put('/infraction/{carPosition}', [InfractionController::class, 'update']);

    // Approbation routes
    Route::put('/soumettreApprobation/{carPosition}', [ApprobationController::class, 'soumettreApprobation']);
    Route::get('/motifsApprobation/{carPosition}', [ApprobationController::class, 'motifsApprobation']);

    // Enlevement routes
    Route::put('/enlevement/{carPosition}', [EnlevementController::class, 'ajouterEnlevement']);
    Route::get('/enlevement/{carPosition}', [EnlevementController::class, 'obtenirEnlevement']);

    // Dommages routes
    Route::put('/enregistrerDommages/{carPosition}', [DommagesController::class, 'enregistrerDommages']);
    Route::get('/voirDommages/{vehicleId}', [DommagesController::class, 'voirDommages']);

    // Statistiques
    Route::get('/statistiques', [CarPositionController::class, 'statistiques']);
});
