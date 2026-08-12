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
        Schema::create('car_positions', function (Blueprint $table) {
            $table->id();
            $table->string('description', 254)->nullable();
            $table->string('latitude', 254)->nullable();
            $table->string('longitude', 254)->nullable();
            $table->string('title', 254)->nullable();
            $table->string('uuid', 254)->nullable();
            //    $table->integer('etat_procedure_id')->nullable();
            $table->unsignedBigInteger('user_id');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->unsignedBigInteger('agent_id')->nullable();
            $table->foreign('agent_id')->references('id')->on('users')->onDelete('cascade');
            $table->string('numero_vehicule', 254)->nullable();
            $table->string('secteur', 254)->nullable();
            $table->dateTime('date_pv_enelevement')->nullable();
            $table->dateTime('date_enlevement')->nullable();
            $table->string('adresse_precise', 254)->nullable();
            $table->integer('statut')->default(1);
            $table->string('qrcode', 254)->nullable();
            $table->string('qrcode_file', 254)->nullable();
            $table->text('pv_enlevement')->nullable();
            $table->string('commune', 254)->nullable();
            $table->enum('etat', ['SIGNALE', 'ENLEVE', 'EN COURS'])->default('SIGNALE');
            $table->enum('lieu', ['PUBLIC', 'PRIVE'])->default('PUBLIC');
            $table->enum('pays_etranger', ['OUI', 'NON'])->default('NON');
            $table->integer('step')->nullable();
            $table->string('model', 254)->nullable();
            $table->string('type_car', 254)->nullable();
            $table->enum('entretien', ['BON',  'MOYEN',  'DEGRADE'])->nullable();
            $table->string('categorie', 254)->nullable();
            $table->string('couleur', 254)->nullable();
            $table->string('motif_enlevement', 254)->nullable();
            $table->string('motif_infraction', 254)->nullable();
            $table->string('lieu_enlevement', 254)->nullable();
            $table->string('nom_responsable_mef', 254)->nullable();
            $table->string('enleve', 254)->nullable();
            $table->string('marque', 254)->nullable();
            $table->string('motife_approbation', 254)->nullable();
            $table->boolean('is_approve')->default(0);
            $table->boolean('is_deleted')->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('car_positions');
    }
};
