<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Suppression d'un compte du personnel qui n'est plus affilié à SENDRA.
 *
 * La suppression est un archivage (colonne `users.deleted`) et non un DELETE :
 * `car_positions.user_id` et `car_positions.agent_id` sont en ON DELETE
 * CASCADE, effacer la ligne emporterait tous les signalements du compte.
 * Ce que ces tests figent : le compte sort des listes, ne peut plus ouvrir le
 * back-office, reste restaurable, et les garde-fous (soi-même, dernier Admin,
 * non-Admin) tiennent.
 */
class AccountDeletionTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        return User::factory()->create(['role_id' => 1, 'is_enabled' => true]);
    }

    public function test_admin_can_delete_a_staff_account(): void
    {
        $admin = $this->admin();
        $agent = User::factory()->create(['role_id' => 2, 'is_enabled' => true]);

        $this->actingAs($admin)
            ->delete("/dashboard/comptes/{$agent->id}")
            ->assertSessionHas('success');

        $this->assertTrue((bool) $agent->fresh()->deleted);
        // La ligne reste en base : aucun signalement n'est emporté.
        $this->assertDatabaseHas('users', ['id' => $agent->id]);
    }

    public function test_deleted_account_disappears_from_the_list_and_is_found_under_archives(): void
    {
        $admin = $this->admin();
        $agent = User::factory()->create(['role_id' => 2, 'is_enabled' => true, 'deleted' => true]);

        $this->actingAs($admin)->get('/dashboard/comptes/agents')
            ->assertOk()->assertDontSee($agent->email);

        $this->actingAs($admin)->get('/dashboard/comptes/agents?archives=1')
            ->assertOk()->assertSee($agent->email);
    }

    public function test_deleted_account_cannot_open_the_backoffice(): void
    {
        $exAgent = User::factory()->create(['role_id' => 2, 'is_enabled' => true, 'deleted' => true]);

        $this->actingAs($exAgent)->get('/dashboard')
            ->assertRedirect(route('login'))
            ->assertSessionHasErrors('email');
    }

    public function test_deleted_account_cannot_reach_the_forced_password_change_page(): void
    {
        // Ce groupe de routes n'a pas le middleware `isActived` (il est sa
        // propre cible de redirection) : il doit être couvert quand même.
        $exAgent = User::factory()->create(['role_id' => 2, 'is_enabled' => false, 'deleted' => true]);

        $this->actingAs($exAgent)->get('/modifier/motDePasse')->assertRedirect(route('login'));
    }

    public function test_admin_cannot_delete_their_own_account(): void
    {
        $admin = $this->admin();
        User::factory()->create(['role_id' => 1, 'is_enabled' => true]); // un autre Admin existe

        $this->actingAs($admin)
            ->delete("/dashboard/comptes/{$admin->id}")
            ->assertSessionHas('error');

        $this->assertNull($admin->fresh()->deleted);
    }

    public function test_last_active_admin_cannot_be_deleted(): void
    {
        $admin = $this->admin();
        $dernier = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);

        $this->actingAs($admin)
            ->delete("/dashboard/comptes/{$dernier->id}")
            ->assertSessionHas('success');

        // Il ne reste plus que $admin : il ne peut plus être supprimé par
        // personne (et pas non plus par lui-même, cf. test précédent).
        $autre = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);
        $this->actingAs($autre)
            ->delete("/dashboard/comptes/{$admin->id}")
            ->assertSessionHas('success');

        $this->assertTrue((bool) $admin->fresh()->deleted);

        $this->actingAs($autre)->delete("/dashboard/comptes/{$autre->id}")->assertSessionHas('error');
        $this->assertNull($autre->fresh()->deleted);
    }

    public function test_non_admin_cannot_delete_an_account(): void
    {
        $agent = User::factory()->create(['role_id' => 2, 'is_enabled' => true]);
        $cible = User::factory()->create(['role_id' => 3, 'is_enabled' => true]);

        $this->actingAs($agent)->delete("/dashboard/comptes/{$cible->id}")->assertForbidden();
        $this->assertNull($cible->fresh()->deleted);
    }

    public function test_admin_can_restore_a_deleted_account(): void
    {
        $admin = $this->admin();
        $exAgent = User::factory()->create(['role_id' => 2, 'is_enabled' => true, 'deleted' => true]);

        $this->actingAs($admin)
            ->patch("/dashboard/comptes/{$exAgent->id}/restaurer")
            ->assertSessionHas('success');

        $this->assertFalse((bool) $exAgent->fresh()->deleted);
    }

    public function test_citizen_accounts_are_not_deletable_from_these_screens(): void
    {
        $admin = $this->admin();
        $citoyen = User::factory()->create(['role_id' => 5]);

        $this->actingAs($admin)
            ->delete("/dashboard/comptes/{$citoyen->id}")
            ->assertSessionHas('error');

        $this->assertNull($citoyen->fresh()->deleted);
    }
}
