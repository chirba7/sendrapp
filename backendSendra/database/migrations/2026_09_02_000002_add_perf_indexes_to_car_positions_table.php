<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Correction perf : les listes web (Signalés/Enlevés/En cours) filtrent sur
 * (is_deleted, etat) et l'API mobile trie sur created_at, sans aucun index
 * dédié — MySQL fait un scan complet à chaque requête. Négligeable au
 * volume actuel, mais dégradera linéairement à mesure que la table grossit.
 * Voir même fix miroir dans sendraApp/database/migrations (table
 * `car_positions` partagée entre les deux apps). Idempotent via vérification
 * SHOW INDEX : contrairement à un ALTER ENUM, ajouter un index déjà présent
 * lève une erreur "Duplicate key name".
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
