<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Lot 1 des demandes de la réunion de direction (compte rendu SENDRA) :
 *
 *  - `car_photos.source` : distinguer les photos envoyées par le citoyen de
 *    celles prises par l'agent pendant la constatation. Les photos existantes
 *    proviennent toutes de l'app citoyen.
 *  - `car_positions.explication_infraction` : zone de texte justifiant le
 *    motif d'infraction choisi dans la liste.
 *  - `car_positions.soumis_approbation_at` : date d'envoi pour approbation.
 *    Elle sert de verrou — au-delà, l'agent ne peut plus modifier le
 *    signalement — et de repère dans l'historique.
 *  - `signalement_status_history` : l'historique daté des changements d'état,
 *    qui n'existait nulle part. Sans lui, impossible d'afficher au citoyen
 *    l'avancement de son signalement : la table ne portait que l'état courant.
 *  - rôle « Operateur » (création des missions).
 *
 * Idempotent : chaque ajout est conditionné, la migration peut être rejouée.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('car_photos', 'source')) {
            Schema::table('car_photos', function (Blueprint $table) {
                $table->string('source', 10)->nullable()->after('position');
            });
            // Tout l'existant vient du signalement citoyen.
            DB::table('car_photos')->whereNull('source')->update(['source' => 'citoyen']);
        }

        if (!Schema::hasColumn('car_positions', 'explication_infraction')) {
            Schema::table('car_positions', function (Blueprint $table) {
                $table->text('explication_infraction')->nullable()->after('motif_infraction');
            });
        }

        if (!Schema::hasColumn('car_positions', 'soumis_approbation_at')) {
            Schema::table('car_positions', function (Blueprint $table) {
                $table->timestamp('soumis_approbation_at')->nullable()->after('is_approve');
            });
            // Un signalement dont les dommages sont saisis a déjà été envoyé
            // pour approbation : on reprend sa date de dernière modification.
            DB::table('car_positions')
                ->whereNotNull('dommage_image')
                ->where('dommage_image', '!=', '')
                ->update(['soumis_approbation_at' => DB::raw('updated_at')]);
        }

        if (!Schema::hasTable('signalement_status_history')) {
            Schema::create('signalement_status_history', function (Blueprint $table) {
                $table->id();
                $table->foreignId('car_position_id')->constrained('car_positions')->cascadeOnDelete();
                // Évènement métier, stable dans le temps (le libellé affiché
                // reste côté application, pour pouvoir le traduire).
                $table->string('event', 40);
                $table->string('etat', 40)->nullable();
                $table->boolean('is_approve')->nullable();
                $table->text('motif')->nullable();
                $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
                $table->timestamp('created_at')->nullable();
                $table->index(['car_position_id', 'created_at']);
            });

            // Reprise de l'existant : au minimum la création, puis l'envoi
            // pour approbation et la décision quand on peut les dater.
            foreach (DB::table('car_positions')->orderBy('id')->get() as $s) {
                $lignes = [[
                    'car_position_id' => $s->id, 'event' => 'cree', 'etat' => 'SIGNALE',
                    'is_approve' => null, 'motif' => null, 'user_id' => $s->user_id,
                    'created_at' => $s->created_at,
                ]];
                if (!empty($s->soumis_approbation_at)) {
                    $lignes[] = [
                        'car_position_id' => $s->id, 'event' => 'constat_soumis', 'etat' => $s->etat,
                        'is_approve' => null, 'motif' => null, 'user_id' => $s->agent_id,
                        'created_at' => $s->soumis_approbation_at,
                    ];
                }
                if ($s->is_approve !== null && in_array($s->etat, ['EN COURS', 'REJETE', 'ENLEVE'], true)) {
                    $lignes[] = [
                        'car_position_id' => $s->id, 'event' => $s->is_approve ? 'approuve' : 'rejete',
                        'etat' => $s->etat, 'is_approve' => (bool) $s->is_approve,
                        'motif' => $s->motife_approbation, 'user_id' => null,
                        'created_at' => $s->updated_at,
                    ];
                }
                DB::table('signalement_status_history')->insert($lignes);
            }
        }

        if (!DB::table('roles')->where('nomRole', 'Operateur')->exists()) {
            DB::table('roles')->insert([
                'nomRole' => 'Operateur',
                'created_at' => now(), 'updated_at' => now(),
            ]);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('signalement_status_history');
        if (Schema::hasColumn('car_positions', 'soumis_approbation_at')) {
            Schema::table('car_positions', fn (Blueprint $t) => $t->dropColumn('soumis_approbation_at'));
        }
        if (Schema::hasColumn('car_positions', 'explication_infraction')) {
            Schema::table('car_positions', fn (Blueprint $t) => $t->dropColumn('explication_infraction'));
        }
        if (Schema::hasColumn('car_photos', 'source')) {
            Schema::table('car_photos', fn (Blueprint $t) => $t->dropColumn('source'));
        }
        DB::table('roles')->where('nomRole', 'Operateur')->delete();
    }
};
