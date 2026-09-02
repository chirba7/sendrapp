<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Correction perf : voir CarPositionController@index/index2/index3/infos —
 * même fix miroir que backendSendra/database/migrations/..._add_perf_indexes
 * _to_car_positions_table.php (table `car_positions` partagée entre les deux
 * apps). Idempotent via vérification SHOW INDEX : contrairement à un ALTER
 * ENUM, ajouter un index déjà présent lève une erreur "Duplicate key name".
 */
return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() !== 'mysql') {
            return;
        }

        if (!$this->indexExists('car_positions_is_deleted_etat_index')) {
            Schema::table('car_positions', function (Blueprint $table) {
                $table->index(['is_deleted', 'etat'], 'car_positions_is_deleted_etat_index');
            });
        }

        if (!$this->indexExists('car_positions_created_at_index')) {
            Schema::table('car_positions', function (Blueprint $table) {
                $table->index('created_at', 'car_positions_created_at_index');
            });
        }
    }

    public function down(): void
    {
        if (DB::getDriverName() !== 'mysql') {
            return;
        }

        if ($this->indexExists('car_positions_is_deleted_etat_index')) {
            Schema::table('car_positions', function (Blueprint $table) {
                $table->dropIndex('car_positions_is_deleted_etat_index');
            });
        }

        if ($this->indexExists('car_positions_created_at_index')) {
            Schema::table('car_positions', function (Blueprint $table) {
                $table->dropIndex('car_positions_created_at_index');
            });
        }
    }

    private function indexExists(string $name): bool
    {
        return collect(DB::select('SHOW INDEX FROM car_positions WHERE Key_name = ?', [$name]))->isNotEmpty();
    }
};
