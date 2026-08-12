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
        Schema::create('t_procedures', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('card_id');
            $table->foreign('card_id')->references('id')->on('car_positions')->onDelete('cascade');
            $table->dateTime('identification_le')->nullable();
            $table->string('proprietaire_avise_par', 254)->nullable();
            $table->string('qualite_autorite', 254)->nullable();
            $table->string('avis_lettre', 254)->nullable();
            $table->string('avis_sticker', 254)->nullable();
            $table->string('avis_appel_sms', 254)->nullable();
            $table->string('avis_av', 254)->nullable();
            $table->string('valide', 254)->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('t_procedures');
    }
};
