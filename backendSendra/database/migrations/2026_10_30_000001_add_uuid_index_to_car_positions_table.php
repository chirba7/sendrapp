<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Correction perf (audit du 29/10/2026) : chaque envoi de signalement vérifie
 * d'abord qu'il n'est pas un renvoi (`uuid` + `user_id`, synchro hors ligne).
 * Sans index sur `uuid`, MySQL parcourt tous les signalements du citoyen.
 * Idempotente sur MySQL (SHOW INDEX), comme 2026_09_02_000002.
 */
return new class extends Migration
{
    private const INDEX = 'car_positions_uuid_index';

    public function up(): void
    {
        if ($this->indexExists()) {
            return;
        }

        Schema::table('car_positions', function (Blueprint $table) {
            $table->index('uuid', self::INDEX);
        });
    }

    public function down(): void
    {
        if (!$this->indexExists()) {
            return;
        }

        Schema::table('car_positions', function (Blueprint $table) {
            $table->dropIndex(self::INDEX);
        });
    }

    private function indexExists(): bool
    {
        if (DB::getDriverName() === 'mysql') {
            return collect(DB::select('SHOW INDEX FROM car_positions WHERE Key_name = ?', [self::INDEX]))->isNotEmpty();
        }
        if (DB::getDriverName() === 'sqlite') {
            return collect(DB::select("SELECT name FROM sqlite_master WHERE type = 'index' AND name = ?", [self::INDEX]))->isNotEmpty();
        }

        return false;
    }
};
