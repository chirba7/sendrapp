<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\UserVerificationCode;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Rejoue le parcours d'authentification réel documenté (AUDIT_SENDRA.md §1.2) :
 * vérification du téléphone par OTP, inscription, connexion JWT, suppression
 * de compte limitée à soi-même.
 */
class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_check_phone_reports_existing_and_unknown_numbers(): void
    {
        $user = User::factory()->create(['telephone' => '770000001']);

        $this->postJson('/api/check-phone', ['telephone' => '770000001'])
            ->assertOk()
            ->assertJson(['exists' => true]);

        $this->postJson('/api/check-phone', ['telephone' => '779999999'])
            ->assertOk()
            ->assertJson(['exists' => false]);
    }

    public function test_verify_code_rejects_wrong_or_expired_code(): void
    {
        UserVerificationCode::create([
            'phone' => '770000002',
            'code' => '123456',
            'expires_at' => now()->addMinutes(10),
        ]);

        $this->postJson('/api/verify-code', ['telephone' => '770000002', 'code' => '000000'])
            ->assertStatus(400);

        UserVerificationCode::where('phone', '770000002')->update(['expires_at' => now()->subMinute()]);

        $this->postJson('/api/verify-code', ['telephone' => '770000002', 'code' => '123456'])
            ->assertStatus(400);
    }

    public function test_verify_code_succeeds_and_marks_verification(): void
    {
        UserVerificationCode::create([
            'phone' => '770000003',
            'code' => '654321',
            'expires_at' => now()->addMinutes(10),
        ]);

        $this->postJson('/api/verify-code', ['telephone' => '770000003', 'code' => '654321'])
            ->assertOk()
            ->assertJson(['success' => true]);

        $this->assertNotNull(
            UserVerificationCode::where('phone', '770000003')->first()->verified_at
        );
    }

    public function test_register_requires_a_successful_verification_first(): void
    {
        // Correction API-H-6 : un code existant-mais-jamais-vérifié ne doit
        // pas suffire à créer un compte.
        UserVerificationCode::create([
            'phone' => '770000004',
            'code' => '111111',
            'expires_at' => now()->addMinutes(10),
        ]);

        $this->postJson('/api/register', [
            'first_name' => 'Jean',
            'last_name' => 'Dupont',
            'telephone' => '770000004',
            'password' => 'motdepasse123',
        ])->assertStatus(400);

        $this->assertDatabaseMissing('users', ['telephone' => '770000004']);
    }

    public function test_register_succeeds_after_verification_with_citizen_role(): void
    {
        UserVerificationCode::create([
            'phone' => '770000005',
            'code' => '222222',
            'expires_at' => now()->addMinutes(10),
            'verified_at' => now(),
        ]);

        $this->postJson('/api/register', [
            'first_name' => 'Awa',
            'last_name' => 'Ndiaye',
            'telephone' => '770000005',
            'password' => 'motdepasse123',
        ])->assertOk();

        $user = User::where('telephone', '770000005')->first();
        $this->assertNotNull($user);
        $this->assertSame(5, $user->role_id);

        // Le code doit être consommé (supprimé) après inscription.
        $this->assertDatabaseMissing('user_verification_codes', ['phone' => '770000005']);
    }

    public function test_login_returns_token_on_success_and_401_otherwise(): void
    {
        User::factory()->create([
            'telephone' => '770000006',
            'password' => bcrypt('bonmotdepasse'),
        ]);

        $this->postJson('/api/login', ['telephone' => '770000006', 'password' => 'bonmotdepasse'])
            ->assertOk()
            ->assertJsonStructure(['success', 'token', 'id', 'fullName', 'phone', 'token_type']);

        $this->postJson('/api/login', ['telephone' => '770000006', 'password' => 'mauvais'])
            ->assertStatus(401);
    }

    public function test_me_hides_password_and_two_factor_fields(): void
    {
        User::factory()->create(['telephone' => '770000007', 'password' => bcrypt('secret123')]);
        $token = $this->loginAndGetToken('770000007', 'secret123');

        $response = $this->postJson('/api/me', [], ['Authorization' => "Bearer {$token}"]);

        $response->assertOk();
        $response->assertJsonMissing(['password']);
        $this->assertArrayNotHasKey('password', $response->json());
        $this->assertArrayNotHasKey('two_factor_secret', $response->json());
    }

    public function test_logout_and_refresh_require_a_valid_token(): void
    {
        $this->postJson('/api/logout')->assertStatus(401);
        $this->postJson('/api/refresh')->assertStatus(401);

        User::factory()->create(['telephone' => '770000008', 'password' => bcrypt('secret123')]);
        $token = $this->loginAndGetToken('770000008', 'secret123');

        $this->postJson('/api/logout', [], ['Authorization' => "Bearer {$token}"])->assertOk();
        $this->postJson('/api/refresh', [], ['Authorization' => "Bearer {$token}"])->assertStatus(401);
    }

    public function test_delete_user_only_deletes_the_authenticated_account(): void
    {
        // Correction API-C-2 : delete-user ne doit jamais pouvoir supprimer
        // le compte d'un tiers, même si un `telephone` arbitraire est fourni.
        User::factory()->create(['telephone' => '770000009', 'password' => bcrypt('secret123')]);
        $victim = User::factory()->create(['telephone' => '770000010']);
        $token = $this->loginAndGetToken('770000009', 'secret123');

        $this->postJson('/api/delete-user', ['telephone' => '770000010'], ['Authorization' => "Bearer {$token}"])
            ->assertOk();

        $this->assertDatabaseMissing('users', ['telephone' => '770000009']);
        $this->assertDatabaseHas('users', ['telephone' => '770000010']);
    }

    private function loginAndGetToken(string $telephone, string $password): string
    {
        return $this->postJson('/api/login', compact('telephone', 'password'))->json('token');
    }
}
