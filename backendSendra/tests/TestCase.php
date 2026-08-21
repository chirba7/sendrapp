<?php

namespace Tests;

use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    use CreatesApplication;

    // `users.role_id` est une FK NOT NULL vers `roles.id` — aucun seeder
    // n'existait dans cette app. RefreshDatabase seede via $seeder juste
    // après la migration, avant que les tests individuels ne démarrent.
    protected $seed = true;

    protected $seeder = RoleSeeder::class;
}
