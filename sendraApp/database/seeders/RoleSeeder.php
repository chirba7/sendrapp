<?php

namespace Database\Seeders;

use App\Models\Role;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class RoleSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * Jamais implémenté jusqu'ici — les 5 rôles (voir DatabaseSeeder) sont
     * repris ici pour pouvoir seeder uniquement les rôles (ex. en test,
     * sans créer l'utilisateur admin de DatabaseSeeder).
     */
    public function run(): void
    {
        foreach (['Admin', 'Agent', 'Autorite commune', 'Autorite prefecture', 'user'] as $nomRole) {
            Role::firstOrCreate(['nomRole' => $nomRole]);
        }
    }
}
