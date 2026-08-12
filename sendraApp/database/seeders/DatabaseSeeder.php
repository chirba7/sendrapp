<?php

namespace Database\Seeders;

// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // \App\Models\User::factory(10)->create();
        \App\Models\Role::factory()->create([
            'nomRole' => 'Admin'
        ]);
        \App\Models\Role::factory()->create([
            'nomRole' => 'Agent'
        ]);
        \App\Models\Role::factory()->create([
            'nomRole' => 'Autorite commune'
        ]);
        \App\Models\Role::factory()->create([
            'nomRole' => 'Autorite prefecture'
        ]);
        \App\Models\Role::factory()->create([
            'nomRole' => 'user'
        ]);
        \App\Models\User::factory()->create([
            // 'name' => 'Test User',
            'email' => 'faye@gmail.com',
            'role_id' => 1
        ]);
    }
}
