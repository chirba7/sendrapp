<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pounds', function (Blueprint $table) {
            $table->id(); $table->string('name'); $table->string('department')->nullable();
            $table->decimal('latitude', 10, 7); $table->decimal('longitude', 10, 7); $table->json('geofence');
            $table->unsignedSmallInteger('geofence_margin_meters')->default(500);
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete(); $table->timestamps();
        });
        Schema::table('missions', function (Blueprint $table) {
            $table->foreignId('reception_agent_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('reception_pound_id')->nullable()->constrained('pounds')->nullOnDelete();
            $table->timestamp('removal_validated_at')->nullable();
            $table->foreignId('removal_validated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reception_checked_in_at')->nullable();
            $table->decimal('reception_check_in_latitude', 10, 7)->nullable();
            $table->decimal('reception_check_in_longitude', 10, 7)->nullable(); $table->timestamp('completed_at')->nullable();
        });
        Schema::create('mission_receptions', function (Blueprint $table) {
            $table->id(); $table->foreignId('mission_id')->constrained()->cascadeOnDelete();
            $table->foreignId('mission_removal_id')->unique()->constrained()->cascadeOnDelete();
            $table->foreignId('received_by')->constrained('users')->restrictOnDelete();
            $table->string('front_photo_path'); $table->string('back_photo_path'); $table->string('left_photo_path');
            $table->string('right_photo_path'); $table->string('sheet_photo_path'); $table->timestamp('received_at'); $table->timestamps();
        });
    }
    public function down(): void
    {
        Schema::dropIfExists('mission_receptions');
        Schema::table('missions', function (Blueprint $table) {
            $table->dropConstrainedForeignId('reception_agent_id'); $table->dropConstrainedForeignId('reception_pound_id');
            $table->dropConstrainedForeignId('removal_validated_by');
            $table->dropColumn(['removal_validated_at','reception_checked_in_at','reception_check_in_latitude','reception_check_in_longitude','completed_at']);
        });
        Schema::dropIfExists('pounds');
    }
};
