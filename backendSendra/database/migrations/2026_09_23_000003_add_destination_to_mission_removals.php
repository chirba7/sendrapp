<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('mission_removals', function (Blueprint $table) {
            $table->string('pound_name')->nullable()->after('plate');
            $table->string('sheet_photo_path')->nullable()->after('pound_name');
        });
    }

    public function down(): void
    {
        Schema::table('mission_removals', function (Blueprint $table) {
            $table->dropColumn(['pound_name', 'sheet_photo_path']);
        });
    }
};
