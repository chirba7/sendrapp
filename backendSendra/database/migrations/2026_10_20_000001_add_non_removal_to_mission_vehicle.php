<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('mission_vehicle', function (Blueprint $table) {
            $table->string('non_removal_reason', 500)->nullable();
            $table->timestamp('non_removed_at')->nullable();
            $table->foreignId('non_removed_by')->nullable()->constrained('users')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('mission_vehicle', function (Blueprint $table) {
            $table->dropConstrainedForeignId('non_removed_by');
            $table->dropColumn(['non_removal_reason', 'non_removed_at']);
        });
    }
};
