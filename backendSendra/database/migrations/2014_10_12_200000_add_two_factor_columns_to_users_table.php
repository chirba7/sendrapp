<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Correction : ce fichier référençait `Laravel\Fortify\Fortify`, un
 * package que backendSendra n'installe pas du tout (copié tel quel depuis
 * sendraApp — la duplication non synchronisée entre les deux codebases,
 * documentée dans AUDIT_SENDRA.md Partie 3). Cette API n'a ni Fortify ni
 * d'UI 2FA (User n'implémente pas TwoFactorAuthenticatable) ; seules les
 * colonnes réellement utilisées (masquées par $hidden sur User, cf
 * correction API-C-4) sont conservées.
 */
return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->text('two_factor_secret')
                ->after('password')
                ->nullable();

            $table->text('two_factor_recovery_codes')
                ->after('two_factor_secret')
                ->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'two_factor_secret',
                'two_factor_recovery_codes',
            ]);
        });
    }
};
