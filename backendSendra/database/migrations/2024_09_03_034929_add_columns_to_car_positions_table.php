<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('car_positions', function (Blueprint $table) {
            $table->boolean('defaut_controle_technique')->default(0);
            $table->boolean('pneumatiques_manquantes')->default(0);
            $table->boolean('vehicule_immerge')->default(0);
            $table->boolean('defauts_techniques_irreversibles')->default(0);
            $table->boolean('vehicule_non_identifiable')->default(0);
            $table->boolean('vehicule_brule')->default(0);
            $table->boolean('chassis_non_reparable')->default(0);

            $table->boolean('sticker')->default(0);
            $table->boolean('nuit')->default(0);
            $table->boolean('pluie')->default(0);
            $table->string('dommage_image', 254)->nullable();
            
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('car_positions', function (Blueprint $table) {
            $table->dropColumn([
                'defaut_controle_technique',
                'pneumatiques_manquantes',
                'vehicule_immerge',
                'defauts_techniques_irreversibles',
                'vehicule_non_identifiable',
                'vehicule_brule',
                'chassis_non_reparable',
                'sticker',
                'nuit',
                'pluie',
                'dommage_image',
            ]);
        });
    }
};
