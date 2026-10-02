<?php

namespace Tests\Feature;

use App\Mail\AuthMail;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

/**
 * Rejoue la gestion des comptes staff documentée (AUDIT_SENDRA.md §1.3) :
 * seul un Admin peut créer/modifier des comptes (correction WEB-C-1), le
 * mot de passe temporaire est aléatoire (correction WEB-H-5) et le premier
 * login force un changement de mot de passe (is_enabled).
 */
class AccountManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_create_a_staff_account_with_random_temporary_password(): void
    {
        Mail::fake();
        $admin = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);

        $response = $this->actingAs($admin)->post('/ajouter', [
            'prenom' => 'Awa',
            'nom' => 'Ndiaye',
            'email' => 'awa.ndiaye@example.com',
            'role' => 2,
            'telephone' => '771111111',
        ]);

        $response->assertSessionHasNoErrors();
        $this->assertDatabaseHas('users', ['email' => 'awa.ndiaye@example.com', 'role_id' => 2]);

        $created = User::where('email', 'awa.ndiaye@example.com')->first();
        $this->assertNotSame('sendra2024@', $created->password); // WEB-H-5 : plus de mdp partagé
        $this->assertNull($created->is_enabled); // force le changement au premier login

        Mail::assertSent(AuthMail::class, fn ($mail) => $mail->hasTo('awa.ndiaye@example.com'));
    }

    public function test_role_field_is_restricted_to_the_four_staff_roles(): void
    {
        // Correction WEB-C-1 (résiduel) : un role_id hors 1-4 doit être rejeté.
        $admin = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);

        $this->actingAs($admin)->post('/ajouter', [
            'prenom' => 'Test', 'nom' => 'Citoyen', 'email' => 'citoyen@example.com',
            'role' => 5, 'telephone' => '771111112',
        ])->assertSessionHasErrors('role');

        $this->assertDatabaseMissing('users', ['email' => 'citoyen@example.com']);
    }

    public function test_non_admin_cannot_manage_accounts(): void
    {
        $agent = User::factory()->create(['role_id' => 2, 'is_enabled' => true]);

        $this->actingAs($agent)->get('/dashboard/comptes/agents')->assertStatus(403);
        $this->actingAs($agent)->post('/ajouter', [
            'prenom' => 'Test', 'nom' => 'Test', 'email' => 'x@example.com',
            'role' => 2, 'telephone' => '771111113',
        ])->assertStatus(403);
    }

    public function test_utilisateurs_screen_lists_autorite_prefecture_accounts(): void
    {
        // Correction WEB-M-1 : l'écran "Utilisateurs" liste en réalité les
        // comptes Autorité préfecture (role_id=4), pas les citoyens.
        $admin = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);
        $prefecture = User::factory()->create(['role_id' => 4, 'first_name' => 'Fatou']);

        $response = $this->actingAs($admin)->get('/dashboard/comptes/utilisateurs');

        $response->assertOk();
        $response->assertSeeText('Fatou');
    }

    public function test_admin_can_change_citizen_phone_without_changing_its_role(): void
    {
        $admin = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);
        $citizen = User::factory()->create([
            'role_id' => 5, 'email' => null, 'telephone' => '771111114',
        ]);

        $this->actingAs($admin)->get('/dashboard/comptes/'.$citizen->id)
            ->assertOk()->assertSee('Citoyen');

        $this->actingAs($admin)->patch('/dashboard/comptes/'.$citizen->id, [
            'prenom' => $citizen->first_name,
            'nom' => $citizen->last_name,
            'email' => '',
            'telephone' => '771111115',
        ])->assertSessionHasNoErrors();

        $citizen->refresh();
        $this->assertSame('771111115', $citizen->telephone);
        $this->assertSame(5, $citizen->role_id);
        $this->assertNull($citizen->email);
    }

    public function test_duplicate_email_is_reported_as_validation_error(): void
    {
        $admin = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);
        $citizen = User::factory()->create(['role_id' => 5, 'telephone' => '771111116']);

        $this->actingAs($admin)->patch('/dashboard/comptes/'.$citizen->id, [
            'prenom' => $citizen->first_name,
            'nom' => $citizen->last_name,
            'email' => $admin->email,
            'telephone' => '771111117',
        ])->assertSessionHasErrors('email');

        $this->assertSame('771111116', $citizen->fresh()->telephone);
    }

    public function test_forced_password_change_flow_enables_the_account(): void
    {
        $staff = User::factory()->create(['role_id' => 2, 'is_enabled' => false]);

        // Tant que is_enabled=false, toute route protégée par isActived redirige.
        $this->actingAs($staff)->get('/dashboard')->assertRedirect('/modifier/motDePasse');

        $this->actingAs($staff)->patch('/motDePasse', [
            'current_password' => 'ignoré',
            'password' => 'NouveauMdp123!',
            'password_confirmation' => 'NouveauMdp123!',
        ]);

        $staff->refresh();
        $this->assertTrue((bool) $staff->is_enabled);
    }
}
