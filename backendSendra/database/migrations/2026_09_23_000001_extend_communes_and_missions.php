<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('communes', function (Blueprint $table) {
            $table->string('departement')->nullable()->after('nomCommune');
            $table->json('geofence')->nullable()->after('longitude');
            $table->unsignedSmallInteger('geofence_margin_meters')->default(500)->after('geofence');
        });

        Schema::table('missions', function (Blueprint $table) {
            $table->string('code')->nullable()->unique()->after('id');
            $table->foreignId('commune_id')->nullable()->after('title')->constrained('communes')->nullOnDelete();
            $table->string('provider_name')->nullable()->after('status');
        });

        Schema::create('mission_trucks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mission_id')->constrained()->cascadeOnDelete();
            $table->string('trailer_brand')->nullable();
            $table->string('registration')->nullable();
            $table->string('driver_name')->nullable();
            $table->unsignedSmallInteger('seats')->nullable();
            $table->timestamps();
        });
        if (DB::getDriverName() === 'mysql') {
            DB::statement('ALTER TABLE missions MODIFY scheduled_at DATETIME NULL, MODIFY address VARCHAR(255) NULL, MODIFY latitude DECIMAL(10,7) NULL, MODIFY longitude DECIMAL(10,7) NULL');
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('mission_trucks');
        Schema::table('missions', function (Blueprint $table) {
            $table->dropConstrainedForeignId('commune_id');
            $table->dropUnique(['code']);
            $table->dropColumn(['code', 'provider_name']);
        });
        Schema::table('communes', function (Blueprint $table) {
            $table->dropColumn(['departement', 'geofence', 'geofence_margin_meters']);
        });
    }
};
