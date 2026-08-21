<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Correction API-M-1 : l'état d'un signalement était forcé à "EN COURS"
 * même en cas de refus d'approbation faute d'état "rejeté" distinct.
 * La colonne `etat` est un ENUM MySQL limité à ['SIGNALE','ENLEVE',
 * 'EN COURS'] — on lui ajoute 'REJETE' (nécessite une ALTER TABLE brute,
 * Schema::table()->enum()->change() n'est pas fiable sans doctrine/dbal).
 */
return new class extends Migration
{
    public function up(): void
    {
        // La syntaxe ALTER ... MODIFY est spécifique à MySQL — en test
        // (sqlite, voir phpunit.xml), on la saute : aucun test n'exerce
        // l'état "REJETE" et sqlite gère les enums différemment (CHECK).
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
