<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Bug trouvé en testant le flux "mot de passe oublié" : `expires_at` avait
 * hérité du comportement historique MySQL qui donne à la première colonne
 * TIMESTAMP d'une table `DEFAULT CURRENT_TIMESTAMP ON UPDATE
 * CURRENT_TIMESTAMP` si rien n'est précisé. Résultat : n'importe quel
 * `save()` sur la ligne (par ex. verifyCode() qui ne pose que `verified_at`)
 * réécrivait silencieusement `expires_at` à l'instant présent, rendant le
 * code "expiré" quasi immédiatement après vérification — reset-password
 * échouait systématiquement juste après un verify-code pourtant réussi.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() === 'mysql') {
            DB::statement('ALTER TABLE user_verification_codes MODIFY expires_at TIMESTAMP NULL DEFAULT NULL');
        }
    }

    public function down(): void
    {
        if (DB::getDriverName() === 'mysql') {
            DB::statement('ALTER TABLE user_verification_codes MODIFY expires_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP');
        }
    }
};
