<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('attendance_sites', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('address')->nullable();
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->unsignedInteger('radius_meters')->default(100);
            $table->unsignedInteger('max_accuracy_meters')->default(50);
            $table->string('timezone')->default('Africa/Dakar');
            $table->boolean('active')->default(true);
            $table->timestamps();
        });
        Schema::create('attendance_assignments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->restrictOnDelete();
            $table->foreignId('attendance_site_id')->constrained()->restrictOnDelete();
            $table->json('weekdays'); // ISO 8601 : lundi = 1, dimanche = 7.
            $table->time('starts_at');
            $table->time('ends_at');
            $table->unsignedSmallInteger('late_tolerance_minutes')->default(5);
            $table->boolean('active')->default(true);
            $table->timestamps();
        });
        Schema::create('attendance_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->restrictOnDelete();
            $table->foreignId('attendance_site_id')->constrained()->restrictOnDelete();
            $table->date('work_date');
            $table->string('timezone');
            $table->json('schedule_snapshot');
            $table->dateTime('scheduled_start'); // UTC
            $table->dateTime('scheduled_end');
            $table->dateTime('arrived_at');
            $table->dateTime('departed_at')->nullable();
            $table->uuid('arrival_request_id');
            $table->uuid('departure_request_id')->nullable();
            $table->json('arrival_position');
            $table->json('departure_position')->nullable();
            $table->string('arrival_status');
            $table->unsignedInteger('late_minutes')->default(0);
            $table->unsignedInteger('early_departure_minutes')->default(0);
            $table->timestamps();
            $table->unique(['user_id', 'work_date']);
            $table->unique(['user_id', 'arrival_request_id'], 'attendance_arrival_request_unique');
            $table->unique(['user_id', 'departure_request_id'], 'attendance_departure_request_unique');
            $table->index(['work_date', 'attendance_site_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('attendance_sessions');
        Schema::dropIfExists('attendance_assignments');
        Schema::dropIfExists('attendance_sites');
    }
};
