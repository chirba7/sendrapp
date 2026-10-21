<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('attendance_sessions', function (Blueprint $table) {
            $table->dateTime('break_started_at')->nullable();
            $table->dateTime('break_ended_at')->nullable();
            $table->uuid('break_start_request_id')->nullable()->unique();
            $table->uuid('break_end_request_id')->nullable()->unique();
            $table->json('break_start_position')->nullable();
            $table->json('break_end_position')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('attendance_sessions', function (Blueprint $table) {
            $table->dropColumn(['break_started_at', 'break_ended_at', 'break_start_request_id',
                'break_end_request_id', 'break_start_position', 'break_end_position']);
        });
    }
};
