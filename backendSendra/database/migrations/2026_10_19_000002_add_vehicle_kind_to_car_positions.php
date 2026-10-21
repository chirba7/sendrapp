<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (!Schema::hasColumn('car_positions', 'vehicle_kind')) {
            Schema::table('car_positions', function (Blueprint $table) {
                $table->string('vehicle_kind', 20)->nullable();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('car_positions', 'vehicle_kind')) {
            Schema::table('car_positions', function (Blueprint $table) {
                $table->dropColumn('vehicle_kind');
            });
        }
    }
};
