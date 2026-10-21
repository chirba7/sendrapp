<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        foreach (['explication_infraction', 'pieces_manquantes'] as $column) {
            if (!Schema::hasColumn('car_positions', $column)) {
                Schema::table('car_positions', function (Blueprint $table) use ($column) {
                    $table->text($column)->nullable();
                });
            }
        }
    }

    public function down(): void
    {
        foreach (['explication_infraction', 'pieces_manquantes'] as $column) {
            if (Schema::hasColumn('car_positions', $column)) {
                Schema::table('car_positions', function (Blueprint $table) use ($column) {
                    $table->dropColumn($column);
                });
            }
        }
    }
};
