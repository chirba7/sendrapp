<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('attendance_devices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->uuid('device_id')->unique();
            $table->text('encrypted_secret');
            $table->timestamps();
        });
        Schema::create('attendance_device_challenges', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->uuid('device_id');
            $table->uuid('request_id');
            $table->string('purpose', 20);
            $table->timestamp('expires_at');
            $table->timestamp('consumed_at')->nullable();
            $table->timestamps();
            $table->index(['user_id', 'expires_at']);
        });
        // Les validations fondées sur l'ancien selfie ne valent pas validation d'un appareil.
        DB::table('attendance_enrollments')->where('status', 'approved')->update([
            'status' => 'pending', 'approved_by' => null, 'approved_at' => null,
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('attendance_device_challenges');
        Schema::dropIfExists('attendance_devices');
    }
};
