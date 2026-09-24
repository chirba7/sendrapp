<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('mission_dispatches', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mission_id')->constrained()->cascadeOnDelete();
            $table->foreignId('mission_truck_id')->nullable()->constrained()->nullOnDelete();
            $table->string('pound_name');
            $table->string('sheet_photo_path');
            $table->foreignId('created_by')->constrained('users')->restrictOnDelete();
            $table->timestamp('departed_at');
            $table->timestamps();
        });

        Schema::create('mission_removals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mission_id')->constrained()->cascadeOnDelete();
            $table->foreignId('car_position_id')->nullable()->constrained('car_positions')->nullOnDelete();
            $table->foreignId('mission_truck_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('mission_dispatch_id')->nullable()->constrained()->nullOnDelete();
            $table->string('vehicle_label')->nullable();
            $table->string('plate')->nullable();
            $table->foreignId('created_by')->constrained('users')->restrictOnDelete();
            $table->timestamps();
            $table->unique(['mission_id', 'car_position_id']);
        });

        Schema::create('mission_removal_photos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mission_removal_id')->constrained()->cascadeOnDelete();
            $table->enum('angle', ['front', 'back', 'left', 'right']);
            $table->string('path');
            $table->timestamps();
            $table->unique(['mission_removal_id', 'angle']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('mission_removal_photos');
        Schema::dropIfExists('mission_removals');
        Schema::dropIfExists('mission_dispatches');
    }
};
