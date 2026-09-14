<?php

namespace Tests\Feature;

use App\Models\CarPosition;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
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
            'moment' => 'jour',
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

    public function test_la_signature_est_ecrite_dans_le_stockage_du_backend(): void
    {
        // 11/09/2026 — la fiche (show.blade.php) et l'application mobile lisent
        // les dommages dans le stockage du backend (BACKEND_STORAGE_URL). La
        // signature saisie ici était écrite sur le disque de sendraApp : elle
        // n'était donc visible nulle part. Elle doit être écrite là où elle est
        // lue. Voir sendra-refonte/docs/inventaire-sendraapp.md §5.3.
        Storage::fake('backend');
        Storage::fake('public');

        $staff = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);
        $carPosition = CarPosition::factory()->create();

        $this->actingAs($staff)
            ->post("/signature/store/{$carPosition->id}", [
                'signature' => 'data:image/png;base64,' . self::VALID_PNG_BASE64,
            ])
            ->assertSessionHasNoErrors();

        $nom = $carPosition->fresh()->dommage_image;
        $this->assertNotNull($nom);
        // Convention inchangée : nom seul en base, préfixe dommages/ sur disque.
        $this->assertStringStartsWith('dommages', $nom);
        Storage::disk('backend')->assertExists('dommages/' . $nom);
        Storage::disk('public')->assertMissing('dommages/' . $nom);
    }

    public function test_une_signature_non_ecrite_ne_laisse_pas_de_reference_en_base(): void
    {
        // Un disque en échec (droits, volume plein) ne doit pas produire une
        // référence vers un fichier absent — c'est ainsi que naissent les
        // « médias manquants ».
        Storage::shouldReceive('disk')->with('backend')->andReturnSelf();
        Storage::shouldReceive('put')->andReturn(false);

        $staff = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);
        $carPosition = CarPosition::factory()->create(['dommage_image' => null]);

        $this->actingAs($staff)
            ->post("/signature/store/{$carPosition->id}", [
                'signature' => 'data:image/png;base64,' . self::VALID_PNG_BASE64,
            ])
            ->assertSessionHasErrors('signature');

        $this->assertNull($carPosition->fresh()->dommage_image);
    }

    public function test_le_pdf_integre_la_signature_lue_dans_le_stockage_du_backend(): void
    {
        // Le PDF lisait public_path('storage/dommages/…') : le disque de
        // sendraApp. DomPDF refuse de lire hors de base_path() (chroot) ; l'image
        // est donc intégrée en data URI depuis le disque du backend.
        Storage::fake('backend');
        Storage::disk('backend')->put('dommages/dommagesTEST.png', base64_decode(self::VALID_PNG_BASE64));

        $agent = User::factory()->create(['role_id' => 2, 'is_enabled' => true]);
        $carPosition = CarPosition::factory()->create([
            'dommage_image' => 'dommagesTEST.png',
            'agent_id' => $agent->id,
        ]);

        $html = view('carPosition.pdf', compact('carPosition'))->render();

        $this->assertStringContainsString('data:image/png;base64,' . self::VALID_PNG_BASE64, $html);
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
