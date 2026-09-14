<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Plusieurs photos par signalement (application mobile) : chaque photo porte
 * désormais son angle de prise de vue (vue_ensemble, devant, derriere,
 * cote_gauche, cote_droit). NULL sur les photos historiques, envoyées une
 * par signalement sans angle. Idempotent via hasColumn.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('car_photos', 'position')) {
            Schema::table('car_photos', function (Blueprint $table) {
                $table->string('position', 30)->nullable()->after('filepath');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('car_photos', 'position')) {
            Schema::table('car_photos', function (Blueprint $table) {
                $table->dropColumn('position');
            });
        }
    }
};
