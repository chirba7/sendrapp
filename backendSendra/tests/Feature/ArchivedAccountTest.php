<?php

namespace Tests\Feature;

use App\Models\CarPosition;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

/**
 * Comptes supprimés depuis le back-office (colonne `users.deleted`).
 *
 * Un compte qui n'est plus affilié à SENDRA ne doit plus recevoir les
 * demandes d'approbation — c'est le symptôme qui a motivé la suppression —
 * ni obtenir de jeton d'API, même si son mot de passe reste valable.
 */
class ArchivedAccountTest extends TestCase
{
    use RefreshDatabase;

    private const VALID_PNG_BASE64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

    public function test_archived_admin_does_not_receive_the_approval_request(): void
    {
        $citoyen = User::factory()->create(['telephone' => '772000001', 'role_id' => 5]);
        $adminActif = User::factory()->create([
            'telephone' => '772000002', 'role_id' => 1, 'email' => 'actif@sendra.sn',
        ]);
        User::factory()->create([
            'telephone' => '772000003', 'role_id' => 1, 'email' => 'ancien@sendra.sn', 'deleted' => true,
        ]);

        $jetonCitoyen = $this->postJson('/api/login', ['telephone' => '772000001', 'password' => 'password'])->json('token');
        $jetonStaff = $this->postJson('/api/login', ['telephone' => '772000002', 'password' => 'password'])->json('token');

        $this->postJson('/api/faireSignalement', [
            'titre' => 'Véhicule abandonné',
            'commune' => 'Dakar-Plateau',
            'latitude' => 14.6928,
            'longitude' => -17.4467,
            'image' => self::VALID_PNG_BASE64,
        ], ['Authorization' => "Bearer {$jetonCitoyen}"])->assertOk();

        $signalement = CarPosition::where('user_id', $citoyen->id)->firstOrFail();

        // Signalement non approuvé : la saisie des dommages déclenche la
        // demande d'approbation par e-mail à tous les Admins.
        $this->putJson("/api/enregistrerDommages/{$signalement->id}", [
            'signature' => 'data:image/png;base64,' . self::VALID_PNG_BASE64,
        ], ['Authorization' => "Bearer {$jetonStaff}"])->assertOk();

        $destinataires = collect(Mail::getSymfonyTransport()->messages())
            ->flatMap(fn ($envoi) => $envoi->getEnvelope()->getRecipients())
            ->map(fn ($adresse) => $adresse->getAddress())
            ->all();

        $this->assertContains($adminActif->email, $destinataires);
        $this->assertNotContains('ancien@sendra.sn', $destinataires);
    }

    public function test_archived_account_cannot_obtain_an_api_token(): void
    {
        User::factory()->create(['telephone' => '772000004', 'role_id' => 2, 'deleted' => true]);

        $this->postJson('/api/login', ['telephone' => '772000004', 'password' => 'password'])
            ->assertStatus(401);
    }
}
