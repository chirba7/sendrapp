<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Correction ACL : rien n'empêchait un compte citoyen (role_id=5, créé
 * depuis l'app mobile, même table `users`) de se connecter au back-office
 * — seule la gestion des comptes vérifiait un rôle (WEB-C-1). `role:1,2,3,4`
 * est désormais posé sur tous les groupes authentifiés.
 */
class RoleAccessWebTest extends TestCase
{
    use RefreshDatabase;

    public function test_citizen_account_is_forbidden_everywhere_in_the_back_office(): void
    {
        $citizen = User::factory()->create(['role_id' => 5, 'is_enabled' => true]);

        $this->actingAs($citizen)->get('/dashboard')->assertStatus(403);
        $this->actingAs($citizen)->get('/')->assertStatus(403);
        $this->actingAs($citizen)->get('/dashboard/cartographie')->assertStatus(403);
        $this->actingAs($citizen)->get('/modifier/motDePasse')->assertStatus(403);
    }

    public function test_all_four_staff_roles_reach_the_dashboard(): void
    {
        foreach ([1, 2, 3, 4] as $roleId) {
            $user = User::factory()->create(['role_id' => $roleId, 'is_enabled' => true]);
            $this->actingAs($user)->get('/dashboard')->assertOk();
        }
    }

    public function test_registration_route_is_disabled(): void
    {
        $this->get('/register')->assertStatus(404);
        $this->post('/register', [])->assertStatus(404);
    }
}
