<?php
/**
 * Comptes de test pour k6 — PREPRODUCTION UNIQUEMENT.
 *
 * Pourquoi : le limiteur `api` est de 60 requêtes/min PAR UTILISATEUR. Si tous
 * les utilisateurs virtuels k6 partagent un seul compte, on mesure le limiteur
 * (429), pas le serveur. On crée donc 200 citoyens + 10 agents, sans SMS.
 *
 * Lancer (dans le dossier du backend de PREPROD, en tant qu'apache) :
 *   sudo -u apache php artisan tinker --execute="require '/root/k6/comptes-test.php';"
 * Nettoyer après les tests :
 *   sudo -u apache php artisan tinker --execute="\$nettoyer=true; require '/root/k6/comptes-test.php';"
 *
 * Téléphones : 700000001..700000200 (citoyens), 700000901..700000910 (agents).
 * Mot de passe commun : K6-Epavie-2026
 */

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

if (app()->environment('production') && !str_contains(config('app.url'), 'preprod')) {
    echo "REFUS : APP_ENV=production et APP_URL sans 'preprod'. Ce script est pour la préprod.\n";
    return;
}

$telephones = array_merge(
    array_map(fn ($i) => sprintf('700000%03d', $i), range(1, 200)),
    array_map(fn ($i) => sprintf('700000%03d', $i), range(901, 910)),
);

if (!empty($nettoyer)) {
    $ids = DB::table('users')->whereIn('telephone', $telephones)->pluck('id');
    $sigs = DB::table('car_positions')->whereIn('user_id', $ids)->pluck('id');
    $fichiers = DB::table('car_photos')->whereIn('card_id', $sigs)->pluck('filepath')->all();
    Storage::disk('public')->delete($fichiers);
    DB::table('signalement_status_history')->whereIn('car_position_id', $sigs)->delete();
    DB::table('car_photos')->whereIn('card_id', $sigs)->delete();
    DB::table('car_positions')->whereIn('id', $sigs)->delete();
    DB::table('users')->whereIn('id', $ids)->delete();
    echo "Nettoyé : {$ids->count()} comptes, {$sigs->count()} signalements, ".count($fichiers)." fichiers.\n";
    return;
}

$hash = Hash::make('K6-Epavie-2026'); // un seul bcrypt pour tous : rapide
$crees = 0;
foreach ($telephones as $tel) {
    $agent = (int) substr($tel, -3) >= 901;
    $crees += DB::table('users')->insertOrIgnore([
        'first_name' => 'K6',
        'last_name' => $agent ? 'Agent '.$tel : 'Citoyen '.$tel,
        'telephone' => $tel,
        'password' => $hash,
        'role_id' => $agent ? 2 : 5,
        'is_enabled' => 1,
        'created_at' => now(),
        'updated_at' => now(),
    ]);
}
echo "Comptes créés : $crees (déjà présents ignorés).\n";

// Jetons JWT générés directement (sans passer par /api/login) : le login non
// authentifié est limité à 60/min PAR IP, k6 ne pourrait pas connecter 210
// comptes depuis un seul poste. Le scénario « login » teste ce point à part.
$jetons = ['citoyens' => [], 'agents' => []];
foreach (\App\Models\User::whereIn('telephone', $telephones)->get() as $u) {
    $jetons[$u->role_id == 2 ? 'agents' : 'citoyens'][] = \Tymon\JWTAuth\Facades\JWTAuth::fromUser($u);
}
file_put_contents('/tmp/k6-jetons.json', json_encode($jetons));
echo "Jetons écrits dans /tmp/k6-jetons.json (".count($jetons['citoyens'])." citoyens, ".count($jetons['agents'])." agents).\n";
echo "Récupérer : scp root@<serveur>:/tmp/k6-jetons.json C:\\Projets\\sendrapp\\sendra\\audit-perf\\k6\\\n";
