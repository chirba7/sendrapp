<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();

            $table->string('first_name', 254)->nullable();
            $table->string('last_name', 254)->nullable();
            $table->string('telephone', 254)->unique()->nullable();
            $table->string('email')->unique()->nullable();
            $table->timestamp('email_verified_at')->nullable();
            $table->string('password')->nullable();

            $table->string('adresse', 254)->nullable();
            $table->timestamp('activation_date')->nullable();
            $table->integer('max_attempt')->nullable();
            $table->string('username', 254)->nullable();
            $table->string('uuid', 254)->nullable();
            $table->string('ville', 254)->nullable();
            
            $table->boolean('is_connected')->nullable();
            $table->boolean('is_enabled')->nullable();
            $table->boolean('was_successfull')->nullable();
            $table->boolean('deleted')->nullable();
            $table->unsignedBigInteger('role_id');
            $table->foreign('role_id')->references('id')->on('roles')->onDelete('cascade');
       
            $table->rememberToken();
            $table->foreignId('current_team_id')->nullable();
            $table->string('profile_photo_path', 2048)->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
