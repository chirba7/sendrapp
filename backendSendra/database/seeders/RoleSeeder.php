<?php

namespace Database\Seeders;

use App\Models\Role;
use Illuminate\Database\Seeder;

/**
 * Aucun seeder de rôles n'existait dans cette app (contrairement à
 * sendraApp) — les 5 rôles ne sont documentés que par convention dans le
 * code (EnsureUserHasRole, routes/api.php, AuthControllerApi::register()).
 * Nécessaire pour les tests : `users.role_id` est une FK NOT NULL vers
 * `roles.id`.
 */
class RoleSeeder extends Seeder
{
    public function run(): void
    {
        foreach (['Admin', 'Agent', 'Autorite commune', 'Autorite prefecture', 'user'] as $nomRole) {
            Role::firstOrCreate(['nomRole' => $nomRole]);
        }
    }
}
