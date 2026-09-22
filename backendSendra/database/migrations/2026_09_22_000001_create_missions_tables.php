<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('missions', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->enum('type', ['programmee', 'brute']);
            $table->enum('status', ['brouillon', 'planifiee', 'en_cours', 'terminee', 'annulee'])->default('planifiee');
            $table->dateTime('scheduled_at');
            $table->string('address');
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->unsignedSmallInteger('check_in_radius_meters')->default(150);
            $table->string('trailer_brand')->nullable();
            $table->string('trailer_plate')->nullable();
            $table->json('pounds')->nullable();
            $table->foreignId('created_by')->constrained('users')->cascadeOnDelete();
            $table->timestamps();
        });

        Schema::create('mission_user', function (Blueprint $table) {
            $table->foreignId('mission_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->dateTime('checked_in_at')->nullable();
            $table->decimal('check_in_latitude', 10, 7)->nullable();
            $table->decimal('check_in_longitude', 10, 7)->nullable();
            $table->decimal('check_in_accuracy', 8, 2)->nullable();
            $table->decimal('check_in_distance', 8, 2)->nullable();
            $table->timestamps();
            $table->primary(['mission_id', 'user_id']);
        });

        Schema::create('mission_vehicle', function (Blueprint $table) {
            $table->foreignId('mission_id')->constrained()->cascadeOnDelete();
            $table->foreignId('car_position_id')->constrained('car_positions')->cascadeOnDelete();
            $table->timestamps();
            $table->primary(['mission_id', 'car_position_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('mission_vehicle');
        Schema::dropIfExists('mission_user');
        Schema::dropIfExists('missions');
    }
};
