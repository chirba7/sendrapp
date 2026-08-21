<?php

namespace Tests;

use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    use CreatesApplication;

    // Correction : User::factory() plantait (FK role_id) sur toute base de
    // test fraîche puisque `roles` n'était jamais peuplée — RefreshDatabase
    // seede automatiquement via $seeder après la migration, avant que les
    // tests individuels ne démarrent leur transaction.
    protected $seed = true;

    protected $seeder = RoleSeeder::class;
}
