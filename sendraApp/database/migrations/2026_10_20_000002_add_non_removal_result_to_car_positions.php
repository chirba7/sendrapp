<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('car_positions', function (Blueprint $table) {
            $table->string('non_removal_reason', 500)->nullable();
            $table->timestamp('non_removed_at')->nullable();
        });
        foreach (DB::table('mission_vehicle')->whereNotNull('non_removed_at')->orderBy('non_removed_at')->get() as $assignment) {
            $removedLater = DB::table('mission_removals')
                ->where('car_position_id', $assignment->car_position_id)
                ->where('created_at', '>=', $assignment->non_removed_at)
                ->exists();
            if (! $removedLater) {
                DB::table('car_positions')->where('id', $assignment->car_position_id)
                    ->whereIn('etat', ['SIGNALE', 'EN COURS'])
                    ->update([
                        'non_removal_reason' => $assignment->non_removal_reason,
                        'non_removed_at' => $assignment->non_removed_at,
                    ]);
            }
        }
    }

    public function down(): void
    {
        Schema::table('car_positions', function (Blueprint $table) {
            $table->dropColumn(['non_removal_reason', 'non_removed_at']);
        });
    }
};
