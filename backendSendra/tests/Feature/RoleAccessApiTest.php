<?php

namespace Tests\Feature;

use App\Models\CarPosition;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Correction API-C-3 / ACL : un citoyen (role 5) ne doit accéder à aucune
 * route "métier" ; un Agent (role 2) ne doit pas pouvoir approuver
 * (AUDIT_SENDRA.md §1.1 : "Agent... pas d'accès à l'approbation").
 */
class RoleAccessApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_citizen_is_forbidden_from_all_business_routes(): void
    {
        User::factory()->create(['telephone' => '772000001', 'role_id' => 5]);
        $carPosition = CarPosition::factory()->create();
        $token = $this->loginAndGetToken('772000001');
        $headers = ['Authorization' => "Bearer {$token}"];

        $this->getJson('/api/listerSignalements', $headers)->assertStatus(403);
        $this->getJson('/api/statistiques', $headers)->assertStatus(403);
        $this->getJson("/api/vehicule/{$carPosition->id}", $headers)->assertStatus(403);
        $this->putJson("/api/infraction/{$carPosition->id}", [], $headers)->assertStatus(403);
        $this->putJson("/api/soumettreApprobation/{$carPosition->id}", [], $headers)->assertStatus(403);
        $this->putJson("/api/enlevement/{$carPosition->id}", [], $headers)->assertStatus(403);
        $this->deleteJson("/api/supprimerSignalement/{$carPosition->id}", [], $headers)->assertStatus(403);
    }

    public function test_agent_is_excluded_from_approbation_only(): void
    {
        User::factory()->create(['telephone' => '772000002', 'role_id' => 2]);
        $carPosition = CarPosition::factory()->create();
        $token = $this->loginAndGetToken('772000002');
        $headers = ['Authorization' => "Bearer {$token}"];

        $this->putJson("/api/soumettreApprobation/{$carPosition->id}", [
            'approbation' => 'OUI',
        ], $headers)->assertStatus(403);

        $this->getJson("/api/motifsApprobation/{$carPosition->id}", $headers)->assertStatus(403);

        // Mais reste autorisé sur le reste du workflow métier.
        $this->getJson('/api/statistiques', $headers)->assertOk();
        $this->getJson("/api/vehicule/{$carPosition->id}", $headers)->assertOk();
    }

    public function test_autorite_commune_and_prefecture_can_approve(): void
    {
        foreach ([3, 4] as $roleId) {
            $telephone = '77200000' . $roleId;
            User::factory()->create(['telephone' => $telephone, 'role_id' => $roleId]);
            $carPosition = CarPosition::factory()->create();
            $token = $this->loginAndGetToken($telephone);

            $this->putJson("/api/soumettreApprobation/{$carPosition->id}", [
                'approbation' => 'OUI',
            ], ['Authorization' => "Bearer {$token}"])->assertOk();
        }
    }

    private function loginAndGetToken(string $telephone, string $password = 'password'): string
    {
        return $this->postJson('/api/login', compact('telephone', 'password'))->json('token');
    }
}
