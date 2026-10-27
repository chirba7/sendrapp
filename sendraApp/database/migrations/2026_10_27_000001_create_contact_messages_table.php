<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Messages envoyés depuis le formulaire de contact du site web
 * (sendra-version-scroll). Consultés et traités par l'Admin uniquement.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('contact_messages', function (Blueprint $table) {
            $table->id();
            $table->string('nom', 120);
            $table->string('email', 190);
            $table->string('telephone', 40)->nullable();
            $table->string('objet', 160)->nullable();
            $table->text('message');
            $table->enum('statut', ['nouveau', 'en_cours', 'traite'])->default('nouveau');
            $table->text('note_interne')->nullable();
            $table->timestamp('lu_le')->nullable();
            $table->timestamp('traite_le')->nullable();
            $table->foreignId('traite_par')->nullable()->constrained('users')->nullOnDelete();
            $table->string('ip', 45)->nullable();
            $table->string('user_agent', 255)->nullable();
            $table->timestamps();

            $table->index(['statut', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('contact_messages');
    }
};
