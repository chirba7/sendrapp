<?php

namespace Tests\Feature;

use App\Models\CarPosition;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Miroir web du workflow métier (AUDIT_SENDRA.md §1.3) : véhicule →
 * infraction → approbation → enlèvement, plus les garde-fous ajoutés
 * (Agent exclu de l'approbation, enlèvement bloqué sans approbation,
 * upload de signature invalide rejeté).
 */
class SignalementWorkflowTest extends TestCase
{
    use RefreshDatabase;

    private const VALID_PNG_BASE64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

    public function test_staff_can_process_a_signalement_end_to_end(): void
    {
        $staff = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);
        $carPosition = CarPosition::factory()->create();

        $this->actingAs($staff)->patch("/dashboard/vehicule/{$carPosition->id}", [
            'numero_vehicule' => 'DK-1234-AB',
            'marque' => 'Toyota',
            'type' => 'Berline',
            'model' => 'Corolla',
            'categorie' => 'Particulier',
            'couleur' => 'Grise',
            'entretien' => 'MOYEN',
            'pays_etranger' => 'NON',
        ])->assertSessionHasNoErrors();

        $this->actingAs($staff)->patch("/dashboard/infraction/{$carPosition->id}", [
            'adresse_precise' => 'Avenue Cheikh Anta Diop',
            'motif_infraction' => 'Stationnement prolongé',
            'lieu' => 'PUBLIC',
        ])->assertSessionHasNoErrors();

        // Enlèvement refusé tant que non approuvé (même garde-fou que l'API).
        $this->actingAs($staff)->patch("/dashboard/enlevement/{$carPosition->id}", [
            'motif_enlevement' => 'Épave',
            'date_enlevement' => now()->toDateString(),
            'lieu_enlevement' => 'Fourrière municipale',
            'nom_responsable_mef' => 'M. Sarr',
        ])->assertSessionHasErrors('approbation');

        $this->actingAs($staff)->patch("/dashboard/approbation/{$carPosition->id}", [
            'approbation' => 'OUI',
            'motife_approbation' => 'Dossier complet',
        ])->assertSessionHasNoErrors();

        $carPosition->refresh();
        $this->assertTrue((bool) $carPosition->is_approve);
        $this->assertSame('EN COURS', $carPosition->etat);

        $this->actingAs($staff)->patch("/dashboard/enlevement/{$carPosition->id}", [
            'motif_enlevement' => 'Épave',
            'date_enlevement' => now()->toDateString(),
            'lieu_enlevement' => 'Fourrière municipale',
            'nom_responsable_mef' => 'M. Sarr',
        ])->assertSessionHasNoErrors();

        $carPosition->refresh();
        $this->assertSame('ENLEVE', $carPosition->etat);
    }

    public function test_approbation_refusee_marque_le_signalement_rejete(): void
    {
        $staff = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);
        $carPosition = CarPosition::factory()->create();

        $this->actingAs($staff)->patch("/dashboard/approbation/{$carPosition->id}", [
            'approbation' => 'NON',
            'motife_approbation' => 'Dossier incomplet',
        ])->assertSessionHasNoErrors();

        $carPosition->refresh();
        $this->assertFalse((bool) $carPosition->is_approve);
        $this->assertSame('REJETE', $carPosition->etat);
    }

    public function test_agent_is_forbidden_from_approving(): void
    {
        // Correction ACL : l'Agent traite les signalements mais n'a pas
        // accès à l'approbation (AUDIT_SENDRA.md §1.1).
        $agent = User::factory()->create(['role_id' => 2, 'is_enabled' => true]);
        $carPosition = CarPosition::factory()->create();

        $this->actingAs($agent)
            ->patch("/dashboard/approbation/{$carPosition->id}", ['approbation' => 'OUI'])
            ->assertStatus(403);
    }

    public function test_signature_upload_rejects_invalid_payload(): void
    {
        // Correction WEB-M-4 : payload malformé rejeté proprement (pas de
        // crash serveur), aucune image invalide écrite en storage.
        $staff = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);
        $carPosition = CarPosition::factory()->create();

        $this->actingAs($staff)
            ->post("/signature/store/{$carPosition->id}", ['signature' => 'pas-une-image'])
            ->assertSessionHasErrors('signature');

        $this->actingAs($staff)
            ->post("/signature/store/{$carPosition->id}", [
                'signature' => 'data:image/png;base64,' . self::VALID_PNG_BASE64,
            ])
            ->assertSessionHasNoErrors();

        $carPosition->refresh();
        $this->assertNotNull($carPosition->dommage_image);
    }

    public function test_listing_and_map_pages_render_for_staff(): void
    {
        $staff = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);
        CarPosition::factory()->create();

        foreach (['/dashboard', '/dashboard/signalement/signales', '/dashboard/signalement/enleves', '/dashboard/signalement/encours', '/dashboard/cartographie'] as $uri) {
            $this->actingAs($staff)->get($uri)->assertOk();
        }
    }
}
