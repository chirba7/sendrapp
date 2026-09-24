<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("ALTER TABLE missions MODIFY status ENUM('brouillon', 'planifiee', 'en_cours', 'en_reception', 'terminee', 'annulee') NOT NULL DEFAULT 'planifiee'");
    }

    public function down(): void
    {
        DB::table('missions')->where('status', 'en_reception')->update(['status' => 'en_cours']);
        DB::statement("ALTER TABLE missions MODIFY status ENUM('brouillon', 'planifiee', 'en_cours', 'terminee', 'annulee') NOT NULL DEFAULT 'planifiee'");
    }
};
