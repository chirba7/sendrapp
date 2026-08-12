<?php

use App\Http\Controllers\CarPositionController;
use App\Http\Controllers\UserController;
use App\Models\CarPosition;
use App\Models\User;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/



Route::middleware([
    'auth:sanctum', 'isActived',
    config('jetstream.auth_session'),
    'verified',
])->group(function () {
    Route::get('/dashboard', [CarPositionController::class, 'infos'])->name('dashboard');
});

Route::middleware([
    'auth:sanctum', 'isActived',
    config('jetstream.auth_session'),
    'verified',
])->group(function () {
    Route::get('/',  [CarPositionController::class, 'infos']);

    Route::patch('/update/profil', [UserController::class, 'update'])->name('update.profil');
    Route::patch('/update/pass', [UserController::class, 'updatepass'])->name('update.pass');

    Route::get('/dashboard/signalement/signales', [CarPositionController::class, 'index'])->name('signales');
    Route::get('/dashboard/signalement/enleves', [CarPositionController::class, 'index2'])->name('enleves');
    Route::get('/dashboard/signalement/encours', [CarPositionController::class, 'index3'])->name('encours');
    Route::get('/dashboard/cartographie', [CarPositionController::class, 'maps'])->name('maps');
    Route::get('/dashboard/signalement/{carPosition}', [CarPositionController::class, 'show'])->name('details');
    Route::patch('/dashboard/vehicule/{carPosition}', [CarPositionController::class, 'vehicule'])->name('vehicule');
    Route::patch('/dashboard/enlevement/{carPosition}', [CarPositionController::class, 'enlevement'])->name('enlevement');
    Route::get('/dashboard/locatlisation/{carPosition}', [CarPositionController::class, 'locatlisation'])->name('locatlisation');
    Route::patch('/dashboard/approbation/{carPosition}', [CarPositionController::class, 'approbation'])->name('approbation');
    Route::patch('/dashboard/infraction/{carPosition}', [CarPositionController::class, 'infraction'])->name('infraction');
    Route::get('/signalements/{carPosition}/pdf', [CarPositionController::class, 'pdf'])->name('pdf');
    Route::get('/signalements/{carPosition}/pdf_constation', [CarPositionController::class, 'pdf_constation'])->name('pdf_constation');
    // Route::get('/modifier/motDePasse', [UserController::class, 'modifierMotDePasse']);


    Route::get('/signature', [CarPositionController::class, 'signatureshow'])->name('signature.show');
    Route::post('/signature/store/{carPosition}', [CarPositionController::class, 'signaturestore'])->name('signature.store');
});

Route::middleware([
    'auth:sanctum', 'isActived',
    config('jetstream.auth_session'),
    'verified',
])->group(function () {
    Route::get('/dashboard/comptes/ajouter', [UserController::class, 'ajouter'])->name('ajouter');
    Route::get('/dashboard/comptes/admin', [UserController::class, 'admin'])->name('admin');
    Route::get('/dashboard/comptes/agents', [UserController::class, 'agents'])->name('agents');
    Route::get('/dashboard/comptes/autorites', [UserController::class, 'autorites'])->name('autorites');
    Route::get('/dashboard/comptes/utilisateurs', [UserController::class, 'utilisateurs'])->name('utilisateurs');
    Route::post('/ajouter', [UserController::class, 'store'])->name('ajouter.compte');
    Route::get('/test', [UserController::class, 'test']);

    Route::get('/dashboard/comptes/{user}', [UserController::class, 'show'])->name('modifier');
    Route::patch('/dashboard/comptes/{user}', [UserController::class, 'modifier'])->name('modifier.compte');

    Route::post('/dashboard/comptes/agents', [UserController::class, 'save_agents'])->name('save_agents');
    Route::post('/dashboard/comptes/admin', [UserController::class, 'save_admin'])->name('save_admin');
    Route::post('/dashboard/comptes/autorites', [UserController::class, 'save_autorites'])->name('save_autorites');
});

Route::middleware([
    'auth:sanctum',
    config('jetstream.auth_session'),
    'verified',
])->group(function () {
    Route::get('/modifier/motDePasse', [UserController::class, 'modifierMotDePasse']);
    Route::patch('/motDePasse', [UserController::class, 'modifierMotDePasse2'])->name('motDePasse');
});

// mame.bousso@sendra.sn
