<?php

namespace Tests\Feature;

use App\Models\ContactMessage;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Formulaire de contact du site web → back-office.
 *
 * Ce que ces tests figent : seul le serveur du site (clé partagée) peut
 * déposer un message ; seul l'Admin peut lire et traiter les messages.
 */
class ContactMessageTest extends TestCase
{
    use RefreshDatabase;

    private const KEY = 'cle-de-test-site';

    protected function setUp(): void
    {
        parent::setUp();
        config(['services.site_contact.key' => self::KEY]);
    }

    private function payload(array $extra = []): array
    {
        return array_merge([
            'nom' => 'Awa Diop',
            'email' => 'awa@example.sn',
            'telephone' => '+221 77 000 00 00',
            'objet' => 'Véhicule en fourrière / restitution',
            'message' => 'Bonjour, je souhaite connaître la procédure de restitution.',
        ], $extra);
    }

    public function test_site_can_post_a_message_with_the_shared_key(): void
    {
        $this->postJson('/api/site/contact', $this->payload(), ['X-Sendra-Site-Key' => self::KEY])
            ->assertCreated()
            ->assertJson(['ok' => true]);

        $this->assertDatabaseHas('contact_messages', ['email' => 'awa@example.sn', 'statut' => 'nouveau']);
    }

    public function test_post_without_or_with_wrong_key_is_refused(): void
    {
        $this->postJson('/api/site/contact', $this->payload())->assertUnauthorized();
        $this->postJson('/api/site/contact', $this->payload(), ['X-Sendra-Site-Key' => 'mauvaise'])->assertUnauthorized();

        config(['services.site_contact.key' => null]);
        $this->postJson('/api/site/contact', $this->payload(), ['X-Sendra-Site-Key' => ''])->assertUnauthorized();

        $this->assertDatabaseCount('contact_messages', 0);
    }

    public function test_invalid_payload_is_rejected(): void
    {
        $this->postJson('/api/site/contact', $this->payload(['email' => 'pas-un-email', 'message' => 'court']), ['X-Sendra-Site-Key' => self::KEY])
            ->assertUnprocessable();
        $this->assertDatabaseCount('contact_messages', 0);
    }

    public function test_admin_can_list_open_and_process_messages(): void
    {
        $admin = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);
        $msg = ContactMessage::create($this->payload(['statut' => 'nouveau']));

        $this->actingAs($admin)->get('/dashboard/messages-site')->assertOk()->assertSee('Awa Diop');

        $this->actingAs($admin)->get("/dashboard/messages-site/{$msg->id}")->assertOk()->assertSee('procédure de restitution');
        $this->assertNotNull($msg->fresh()->lu_le);

        $this->actingAs($admin)
            ->patch("/dashboard/messages-site/{$msg->id}", ['statut' => 'traite', 'note_interne' => 'Rappelée le jour même.'])
            ->assertRedirect("/dashboard/messages-site/{$msg->id}");

        $msg->refresh();
        $this->assertSame('traite', $msg->statut);
        $this->assertSame($admin->id, $msg->traite_par);
        $this->assertNotNull($msg->traite_le);

        // Retour à « en cours » : la trace de traitement est effacée.
        $this->actingAs($admin)->patch("/dashboard/messages-site/{$msg->id}", ['statut' => 'en_cours']);
        $this->assertNull($msg->fresh()->traite_le);
    }

    public function test_non_admin_staff_cannot_see_messages(): void
    {
        $msg = ContactMessage::create($this->payload(['statut' => 'nouveau']));

        foreach ([2, 3, 4, 5, 7] as $role) {
            $user = User::factory()->create(['role_id' => $role, 'is_enabled' => true]);
            $this->actingAs($user)->get('/dashboard/messages-site')->assertForbidden();
            $this->actingAs($user)->get("/dashboard/messages-site/{$msg->id}")->assertForbidden();
            $this->actingAs($user)->patch("/dashboard/messages-site/{$msg->id}", ['statut' => 'traite'])->assertForbidden();
        }

        $this->assertSame('nouveau', $msg->fresh()->statut);
    }

    public function test_guest_is_redirected_to_login(): void
    {
        $this->get('/dashboard/messages-site')->assertRedirect('/login');
    }
}
