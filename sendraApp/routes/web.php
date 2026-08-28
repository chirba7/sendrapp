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



// Correction WEB-H-1 : le middleware 'verified' ne faisait rien (User
// n'implémente pas MustVerifyEmail, et ce back-office n'a aucun flux
// d'e-mail de vérification — les comptes sont créés par un Admin). Retiré
// des groupes ci-dessous plutôt que de simuler une vérification qui n'a
// pas de sens dans ce produit.
//
// Correction (ACL) : rien n'empêchait un compte citoyen (role_id=5, créé
// depuis l'app mobile, même table `users` que ce back-office) de se
// connecter ici — Fortify ne vérifie que l'email/mot de passe, aucun rôle.
// 'role:1,2,3,4' est donc ajouté sur tous les groupes authentifiés
// ci-dessous pour réserver le back-office au personnel (Admin/Agent/
// Autorité commune/Autorité préfecture).
Route::middleware([
    'auth:sanctum', 'isActived',
    config('jetstream.auth_session'),
    'role:1,2,3,4',
])->group(function () {
    Route::get('/dashboard', [CarPositionController::class, 'infos'])->name('dashboard');
});

Route::middleware([
    'auth:sanctum', 'isActived',
    config('jetstream.auth_session'),
    'role:1,2,3,4',
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
    Route::patch('/dashboard/infraction/{carPosition}', [CarPositionController::class, 'infraction'])->name('infraction');
    Route::get('/signalements/{carPosition}/pdf', [CarPositionController::class, 'pdf'])->name('pdf');
    Route::get('/signalements/{carPosition}/pdf_constation', [CarPositionController::class, 'pdf_constation'])->name('pdf_constation');
    // Route::get('/modifier/motDePasse', [UserController::class, 'modifierMotDePasse']);


    // Correction WEB-L-4 : /signature (page autonome, jamais liée depuis
    // aucun menu/vue) supprimée — dupliquait l'onglet signature déjà
    // intégré dans show.blade.php, qui utilise signature.store ci-dessous.
    Route::post('/signature/store/{carPosition}', [CarPositionController::class, 'signaturestore'])->name('signature.store');
});

// Correction ACL : l'approbation est réservée à Admin/Autorité commune/
// Autorité préfecture — le spec fonctionnel (AUDIT_SENDRA.md §1.1) exclut
// explicitement l'Agent ("traite les signalements, pas d'accès à
// l'approbation"), qui pouvait pourtant approuver comme n'importe quel
// autre rôle staff avant ce correctif.
Route::middleware([
    'auth:sanctum', 'isActived',
    config('jetstream.auth_session'),
    'role:1,3,4',
])->group(function () {
    Route::patch('/dashboard/approbation/{carPosition}', [CarPositionController::class, 'approbation'])->name('approbation');
});

// Correction WEB-C-1 : ajout de 'role:1' (Admin uniquement) — auparavant
// n'importe quel compte actif (Agent, Autorité...) pouvait créer ou
// promouvoir un compte Admin en atteignant ces routes directement.
Route::middleware([
    'auth:sanctum', 'isActived',
    config('jetstream.auth_session'),
    'role:1',
])->group(function () {
    Route::get('/dashboard/comptes/ajouter', [UserController::class, 'ajouter'])->name('ajouter');
    Route::get('/dashboard/comptes/admin', [UserController::class, 'admin'])->name('admin');
    Route::get('/dashboard/comptes/agents', [UserController::class, 'agents'])->name('agents');
    Route::get('/dashboard/comptes/autorites', [UserController::class, 'autorites'])->name('autorites');
    Route::get('/dashboard/comptes/utilisateurs', [UserController::class, 'utilisateurs'])->name('utilisateurs');
    // Correction WEB-M-1 : route déclarée avant le wildcard {user} ci-dessous,
    // sinon "citoyens" serait interprété comme un id de compte.
    Route::get('/dashboard/comptes/citoyens', [UserController::class, 'citoyens'])->name('citoyens');
    Route::post('/ajouter', [UserController::class, 'store'])->name('ajouter.compte');

    Route::get('/dashboard/comptes/{user}', [UserController::class, 'show'])->name('modifier');
    Route::patch('/dashboard/comptes/{user}', [UserController::class, 'modifier'])->name('modifier.compte');

    // Correction WEB-H-2 : save_agents/save_admin/save_autorites pointaient
    // vers des méthodes UserController inexistantes (500 au moindre appel),
    // et aucun formulaire ne les utilisait — store()/modifier() gèrent déjà
    // la création/modification pour les 4 rôles staff via le champ 'role'.
    // Correction WEB-M-5 : route /test retirée (fuite du hash de mot de
    // passe de l'utilisateur connecté par e-mail vers une adresse en dur).
});

Route::middleware([
    'auth:sanctum',
    config('jetstream.auth_session'),
    'role:1,2,3,4',
])->group(function () {
    Route::get('/modifier/motDePasse', [UserController::class, 'modifierMotDePasse']);
    Route::patch('/motDePasse', [UserController::class, 'modifierMotDePasse2'])->name('motDePasse');
});

// mame.bousso@sendra.sn
