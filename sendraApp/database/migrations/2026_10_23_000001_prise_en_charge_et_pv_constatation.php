<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Demandes du 23/10/2026 :
 *
 *  - `pris_en_charge_at` : un agent qui ouvre un signalement le prend en
 *    charge (`agent_id` = lui). Tant qu'il le garde, aucun autre agent ne peut
 *    saisir la constatation : plus de saisies concurrentes incohérentes.
 *    Les signalements déjà commencés (agent_id renseigné) sont considérés
 *    comme pris en charge par cet agent, à leur date de dernière modification.
 *  - `pv_*` : procès-verbal de constatation généré à l'envoi pour approbation,
 *    signé par l'agent dans l'application, puis consultable / téléchargeable.
 *
 * Idempotent : chaque ajout est conditionné, la migration peut être rejouée.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('car_positions', 'pris_en_charge_at')) {
            Schema::table('car_positions', function (Blueprint $table) {
                $table->timestamp('pris_en_charge_at')->nullable();
            });
            DB::table('car_positions')
                ->whereNotNull('agent_id')
                ->update(['pris_en_charge_at' => DB::raw('updated_at')]);
        }

        foreach ([
            'pv_numero' => fn (Blueprint $t) => $t->string('pv_numero', 40)->nullable(),
            'pv_path' => fn (Blueprint $t) => $t->string('pv_path', 255)->nullable(),
            'pv_signature' => fn (Blueprint $t) => $t->string('pv_signature', 255)->nullable(),
            'pv_signe_at' => fn (Blueprint $t) => $t->timestamp('pv_signe_at')->nullable(),
        ] as $colonne => $definition) {
            if (!Schema::hasColumn('car_positions', $colonne)) {
                Schema::table('car_positions', $definition);
            }
        }
    }

    public function down(): void
    {
        foreach (['pris_en_charge_at', 'pv_numero', 'pv_path', 'pv_signature', 'pv_signe_at'] as $colonne) {
            if (Schema::hasColumn('car_positions', $colonne)) {
                Schema::table('car_positions', fn (Blueprint $t) => $t->dropColumn($colonne));
            }
        }
    }
};
