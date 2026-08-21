<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Correction API-H-2 : la migration d'origine ne créait que id+timestamps
 * alors que le contrôleur (AuthControllerApi) utilise déjà phone/code/
 * expires_at — ces colonnes existaient en production sans migration
 * correspondante, ce qui aurait cassé toute inscription sur une base
 * fraîchement migrée. On les ajoute ici, plus `verified_at` pour la
 * correction API-H-6 (lier register() à un verifyCode() réellement réussi).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('user_verification_codes', function (Blueprint $table) {
            $table->string('phone')->after('id')->index();
            $table->string('code');
            $table->timestamp('expires_at')->nullable();
            $table->timestamp('verified_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('user_verification_codes', function (Blueprint $table) {
            $table->dropColumn(['phone', 'code', 'expires_at', 'verified_at']);
        });
    }
};
