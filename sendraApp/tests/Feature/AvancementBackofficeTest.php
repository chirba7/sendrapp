<?php

namespace Tests\Feature;

use App\Models\CarPosition;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Avancement en cinq états (23/10/2026) : la fiche du back-office affiche la
 * même frise que les applications, et les signalements rejetés ont leur liste.
 */
class AvancementBackofficeTest extends TestCase
{
    use RefreshDatabase;

    public function test_fiche_affiche_l_avancement_en_cinq_etats(): void
    {
        $staff = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);
        $s = CarPosition::factory()->create(['etat' => 'EN COURS', 'is_approve' => true]);

        $this->actingAs($staff)->get("/dashboard/signalement/{$s->id}")
            ->assertOk()
            ->assertSee('Avancement du signalement')
            ->assertSee('Étape actuelle')
            ->assertSeeInOrder(['Signalé', 'Constaté par l’agent', 'Approuvé par l’autorité', 'En attente d’enlèvement', 'Résolu'], false);
    }

    public function test_envoye_pour_approbation_passe_en_cours(): void
    {
        $staff = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);
        CarPosition::factory()->create(['etat' => 'SIGNALE', 'title' => 'Transmis', 'soumis_approbation_at' => now()]);
        CarPosition::factory()->create(['etat' => 'SIGNALE', 'title' => 'Pas encore']);

        $this->actingAs($staff)->get('/dashboard/signalement/encours')->assertSee('Transmis')->assertDontSee('Pas encore');
        $this->actingAs($staff)->get('/dashboard/signalement/signales')->assertSee('Pas encore')->assertDontSee('Transmis');
    }

    public function test_liste_des_rejetes(): void
    {
        $staff = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);
        CarPosition::factory()->create(['etat' => 'REJETE', 'title' => 'Dossier refusé', 'motife_approbation' => 'Hors périmètre']);
        CarPosition::factory()->create(['etat' => 'SIGNALE', 'title' => 'Autre dossier']);

        $this->actingAs($staff)->get('/dashboard/signalement/rejetes')
            ->assertOk()
            ->assertSee('Dossier refusé')
            ->assertSee('Hors périmètre')
            ->assertDontSee('Autre dossier');
    }
}
