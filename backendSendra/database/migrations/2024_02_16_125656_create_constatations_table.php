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
        Schema::create('constatations', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('card_id');
            $table->foreign('card_id')->references('id')->on('car_positions')->onDelete('cascade');
            $table->unsignedBigInteger('user_id');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->dateTime('date_enlevement')->nullable();
            $table->time('heure_enlevement')->nullable();
            $table->string('agent', 254)->nullable();
            $table->boolean('enleve')->nullable();
            $table->text('motif_infraction')->nullable();
            $table->string('contact', 254)->nullable();
            $table->string('releve_valves', 254)->nullable();
            $table->string('marque', 254)->nullable();
            $table->string('type', 254)->nullable();
            $table->string('kilometrage', 254)->nullable();
            $table->string('marquage_au_sol', 254)->nullable();
            $table->string('couleurs', 254)->nullable();
            $table->string('saisine', 254)->nullable();
            $table->text('autres_renseignements')->nullable();
            $table->string('identification_immat_sn', 254)->nullable();
            $table->text('mesures_prises')->nullable();
            $table->string('phase', 254)->nullable();
            $table->dateTime('date_constat')->nullable();
            $table->string('adresse_precise', 254)->nullable();
            $table->string('valide', 254)->nullable();
            $table->string('type_agent', 254)->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('constatations');
    }
};
