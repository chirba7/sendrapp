<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Correction API-M-1 : voir ApprobationController — même fix miroir que
 * sendraApp/database/migrations/..._add_rejete_to_car_positions_etat_enum.php
 * (table `car_positions` partagée entre les deux apps). Idempotent si déjà
 * appliquée par l'autre app sur la même base.
 */
return new class extends Migration
{
    public function up(): void
    {
        // La syntaxe ALTER ... MODIFY est spécifique à MySQL — en test
        // (sqlite, voir phpunit.xml), on la saute.
        if (DB::getDriverName() === 'mysql') {
            DB::statement("ALTER TABLE car_positions MODIFY etat ENUM('SIGNALE','ENLEVE','EN COURS','REJETE') NOT NULL DEFAULT 'SIGNALE'");
        }
    }

    public function down(): void
    {
        if (DB::getDriverName() === 'mysql') {
            DB::statement("ALTER TABLE car_positions MODIFY etat ENUM('SIGNALE','ENLEVE','EN COURS') NOT NULL DEFAULT 'SIGNALE'");
        }
    }
};
