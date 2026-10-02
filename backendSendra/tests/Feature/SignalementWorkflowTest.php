<?php

namespace Tests\Feature;

use App\Models\CarPosition;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Rejoue le workflow métier complet documenté (AUDIT_SENDRA.md §1.2) :
 * signalement → véhicule → infraction → approbation → enlèvement/dommages,
 * ainsi que les garde-fous ajoutés lors des corrections (image invalide,
 * enlèvement sans approbation, `lieu` optionnel qui ne doit jamais planter).
 */
class SignalementWorkflowTest extends TestCase
{
    use RefreshDatabase;

    // PNG 1x1 valide, transparent.
    private const VALID_PNG_BASE64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

    public function test_full_signalement_lifecycle(): void
    {
        $citizen = User::factory()->create(['telephone' => '771000001', 'role_id' => 5]);
        $staff = User::factory()->create(['telephone' => '771000002', 'role_id' => 1]);

        $citizenToken = $this->loginAndGetToken('771000001');
        $staffToken = $this->loginAndGetToken('771000002');

        // 1. Le citoyen signale un véhicule.
        $store = $this->postJson('/api/faireSignalement', [
            'titre' => 'Véhicule abandonné',
            'commune' => 'Dakar-Plateau',
            'latitude' => 14.6928,
            'longitude' => -17.4467,
            'image' => self::VALID_PNG_BASE64,
        ], ['Authorization' => "Bearer {$citizenToken}"]);
        $store->assertOk();

        $carPosition = CarPosition::where('user_id', $citizen->id)->firstOrFail();
        $this->assertDatabaseHas('car_photos', ['card_id' => $carPosition->id]);

        // Une image invalide doit être rejetée (API-H-3), sans créer de ligne.
        $this->postJson('/api/faireSignalement', [
            'titre' => 'x', 'commune' => 'x', 'latitude' => 1, 'longitude' => 1,
            'image' => 'ceci-nest-pas-une-image',
        ], ['Authorization' => "Bearer {$citizenToken}"])->assertStatus(422);

        // 2. Le personnel renseigne le véhicule.
        $this->putJson("/api/vehicule/{$carPosition->id}", [
            'numero_vehicule' => 'DK-1234-AB',
            'marque' => 'Toyota',
            'type' => 'Berline',
            'model' => 'Corolla',
            'categorie' => 'Particulier',
            'couleur' => 'Grise',
            'entretien' => 'MOYEN',
            'pays_etranger' => 'NON',
        ], ['Authorization' => "Bearer {$staffToken}"])->assertOk();

        // 3. Infraction — sans `lieu` : ne doit jamais planter (API-H-4).
        $this->putJson("/api/infraction/{$carPosition->id}", [
            'adresse_precise' => 'Avenue Cheikh Anta Diop',
            'motif_infraction' => 'Stationnement prolongé',
        ], ['Authorization' => "Bearer {$staffToken}"])->assertOk();

        $carPosition->refresh();
        $this->assertSame('PUBLIC', $carPosition->lieu); // valeur par défaut DB conservée

        // 4. Enlèvement refusé tant que non approuvé (API-M-2).
        $this->putJson("/api/enlevement/{$carPosition->id}", [
            'motif' => 'Épave',
            'date' => now()->toDateString(),
            'lieu' => 'Fourrière municipale',
            'nom_responsable' => 'M. Sarr',
        ], ['Authorization' => "Bearer {$staffToken}"])->assertStatus(403);

        // 5. Approbation.
        $this->putJson("/api/soumettreApprobation/{$carPosition->id}", [
            'approbation' => 'OUI',
            'motifApprobation' => 'Dossier complet',
        ], ['Authorization' => "Bearer {$staffToken}"])->assertOk();

        $carPosition->refresh();
        $this->assertTrue((bool) $carPosition->is_approve);
        $this->assertSame('EN COURS', $carPosition->etat);

        // 6. Enlèvement, maintenant autorisé.
        $this->putJson("/api/enlevement/{$carPosition->id}", [
            'motif' => 'Épave',
            'date' => now()->toDateString(),
            'lieu' => 'Fourrière municipale',
            'nom_responsable' => 'M. Sarr',
        ], ['Authorization' => "Bearer {$staffToken}"])->assertStatus(201);

        $carPosition->refresh();
        $this->assertSame('ENLEVE', $carPosition->etat);

        // 7. Dommages (signature au format data URL).
        $this->putJson("/api/enregistrerDommages/{$carPosition->id}", [
            'signature' => 'data:image/png;base64,' . self::VALID_PNG_BASE64,
        ], ['Authorization' => "Bearer {$staffToken}"])->assertOk();

        $this->getJson("/api/voirDommages/{$carPosition->id}", ['Authorization' => "Bearer {$staffToken}"])
            ->assertOk()
            ->assertJsonStructure(['message', 'dommages']);

        // 8. Les statistiques reflètent l'état final.
        $stats = $this->getJson('/api/statistiques', ['Authorization' => "Bearer {$staffToken}"]);
        $stats->assertOk();
        $this->assertSame(1, $stats->json('signalements'));
        $this->assertSame(1, $stats->json('enleves'));
    }

    public function test_approbation_refusee_marque_le_signalement_rejete(): void
    {
        $staff = User::factory()->create(['telephone' => '771000003', 'role_id' => 1]);
        $carPosition = \App\Models\CarPosition::factory()->create();
        $token = $this->loginAndGetToken('771000003');

        $this->putJson("/api/soumettreApprobation/{$carPosition->id}", [
            'approbation' => 'NON',
            'motifApprobation' => 'Dossier incomplet',
        ], ['Authorization' => "Bearer {$token}"])->assertOk();

        $carPosition->refresh();
        $this->assertFalse((bool) $carPosition->is_approve);
        $this->assertSame('REJETE', $carPosition->etat);
    }

    public function test_staff_listing_keeps_signalements_older_than_ten_days(): void
    {
        User::factory()->create(['telephone' => '771000004', 'role_id' => 2]);
        $older = CarPosition::factory()->create(['created_at' => now()->subDays(30)]);
        $recent = CarPosition::factory()->create(['created_at' => now()]);
        $token = $this->loginAndGetToken('771000004');

        $this->getJson('/api/listerSignalements', ['Authorization' => "Bearer {$token}"])
            ->assertOk()
            ->assertJsonFragment(['signalementId' => $older->id])
            ->assertJsonFragment(['signalementId' => $recent->id]);
    }

    private function loginAndGetToken(string $telephone, string $password = 'password'): string
    {
        return $this->postJson('/api/login', compact('telephone', 'password'))->json('token');
    }
}
