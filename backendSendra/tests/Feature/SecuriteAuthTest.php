<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\UserVerificationCode;
use App\Services\OrangeSmsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Mockery;
use Tests\TestCase;
use Tymon\JWTAuth\Facades\JWTAuth;

/**
 * Corrections de sécurité de l'audit du 29/10/2026 :
 *  1. jetons JWT avec expiration, compte archivé refusé même avec un ancien
 *     jeton, période de transition pour les jetons émis sans expiration ;
 *  2. nombre d'essais limité sur le code OTP ;
 *  3. envoi de SMS plafonné par numéro et globalement.
 */
class SecuriteAuthTest extends TestCase
{
    use RefreshDatabase;

    // ---------------------------------------------------------------- 1. JWT

    public function test_un_jeton_de_connexion_expire_apres_trente_jours(): void
    {
        User::factory()->create(['telephone' => '771110001', 'role_id' => 5]);

        $jeton = $this->postJson('/api/login', ['telephone' => '771110001', 'password' => 'password'])
            ->assertOk()->json('token');

        $exp = JWTAuth::setToken($jeton)->getPayload()->get('exp');
        $this->assertNotNull($exp, 'le jeton doit porter une date d’expiration');
        $this->assertEqualsWithDelta(now()->addDays(30)->timestamp, $exp, 60);

        $this->travel(31)->days();
        auth()->forgetGuards();
        $this->withToken($jeton)->postJson('/api/me')->assertStatus(401);
    }

    public function test_un_compte_archive_apres_connexion_perd_l_acces_et_son_jeton(): void
    {
        $user = User::factory()->create(['telephone' => '771110002', 'role_id' => 2]);
        $jeton = $this->postJson('/api/login', ['telephone' => '771110002', 'password' => 'password'])->json('token');

        $this->withToken($jeton)->postJson('/api/me')->assertOk();

        // Archivage depuis le back-office pendant que la session est ouverte.
        $user->forceFill(['deleted' => true])->save();
        auth()->forgetGuards();
        $this->withToken($jeton)->getJson('/api/listerSignalements')
            ->assertForbidden()
            ->assertJsonPath('message', 'Ce compte a été désactivé.');

        // Le jeton est sur liste noire : même réactivé, il ne sert plus.
        $user->forceFill(['deleted' => null])->save();
        auth()->forgetGuards();
        $this->withToken($jeton)->postJson('/api/me')->assertStatus(401);
    }

    public function test_les_comptes_historiques_a_deleted_null_ne_sont_pas_bloques(): void
    {
        $user = User::factory()->create(['telephone' => '771110003', 'role_id' => 5, 'deleted' => null]);

        $this->withToken(JWTAuth::fromUser($user))->postJson('/api/me')->assertOk();
    }

    public function test_jeton_sans_expiration_accepte_pendant_la_transition_puis_refuse(): void
    {
        $user = User::factory()->create(['telephone' => '771110004', 'role_id' => 5]);

        // Jeton tel qu'émis avant la correction (ttl null : pas de `exp`).
        JWTAuth::factory()->setTTL(null);
        $ancien = JWTAuth::fromUser($user);
        JWTAuth::factory()->setTTL(43200)->setDefaultClaims(['iss', 'iat', 'exp', 'nbf', 'jti']);
        $this->assertArrayNotHasKey('exp', json_decode(base64_decode(strtr(explode('.', $ancien)[1], '-_', '+/')), true));

        // Transition : accepté tant que la date de coupure est vide.
        auth()->forgetGuards();
        $this->withToken($ancien)->postJson('/api/me')->assertOk();

        // Date de coupure renseignée (mise en service de JWT_TTL) : refusé.
        $this->travel(2)->days();
        config(['jwt.refuser_jetons_emis_avant' => now()->subDay()->toDateString()]);
        auth()->forgetGuards();
        $this->withToken($ancien)->postJson('/api/me')
            ->assertStatus(401)
            ->assertJsonPath('message', 'Session expirée, veuillez vous reconnecter.');

        // Un jeton émis après la coupure n'est pas concerné.
        $nouveau = $this->postJson('/api/login', ['telephone' => '771110004', 'password' => 'password'])->json('token');
        auth()->forgetGuards();
        $this->withToken($nouveau)->postJson('/api/me')->assertOk();
    }

    // ---------------------------------------------------------------- 2. OTP

    private function code(string $telephone, string $code = '123456'): void
    {
        UserVerificationCode::create([
            'phone' => $telephone,
            'code' => $code,
            'expires_at' => now()->addMinutes(10),
        ]);
    }

    public function test_le_code_est_detruit_apres_cinq_mauvais_essais(): void
    {
        $this->code('771110010');

        foreach ([4, 3, 2, 1] as $restants) {
            $this->postJson('/api/verify-code', ['telephone' => '771110010', 'code' => '000000'])
                ->assertStatus(400)
                ->assertJsonPath('essais_restants', $restants);
        }

        $this->postJson('/api/verify-code', ['telephone' => '771110010', 'code' => '000000'])
            ->assertStatus(429)
            ->assertJsonPath('essais_restants', 0);

        $this->assertDatabaseMissing('user_verification_codes', ['phone' => '771110010']);

        // Même le bon code ne passe plus : il faut en redemander un.
        $this->postJson('/api/verify-code', ['telephone' => '771110010', 'code' => '123456'])
            ->assertNotFound();

        // Et le mot de passe ne peut pas être réinitialisé.
        User::factory()->create(['telephone' => '771110010']);
        $this->postJson('/api/reset-password', [
            'telephone' => '771110010', 'password' => 'nouveau1', 'password_confirmation' => 'nouveau1',
        ])->assertStatus(400);
    }

    public function test_le_bon_code_apres_quelques_erreurs_passe_et_remet_le_compteur_a_zero(): void
    {
        $this->code('771110011');

        $this->postJson('/api/verify-code', ['telephone' => '771110011', 'code' => '000000'])->assertStatus(400);
        $this->postJson('/api/verify-code', ['telephone' => '771110011', 'code' => '111111'])->assertStatus(400);
        $this->postJson('/api/verify-code', ['telephone' => '771110011', 'code' => '123456'])->assertOk();

        $this->assertNotNull(UserVerificationCode::where('phone', '771110011')->value('verified_at'));
    }

    public function test_les_essais_sont_comptes_par_numero(): void
    {
        $this->code('771110012');
        $this->code('771110013');

        for ($i = 0; $i < 4; $i++) {
            $this->postJson('/api/verify-code', ['telephone' => '771110012', 'code' => '000000'])->assertStatus(400);
        }

        $this->postJson('/api/verify-code', ['telephone' => '771110013', 'code' => '000000'])
            ->assertStatus(400)
            ->assertJsonPath('essais_restants', 4);
    }

    // ---------------------------------------------------------------- 3. SMS

    private function smsReussis(int $fois): void
    {
        $sms = Mockery::mock(OrangeSmsService::class);
        $sms->shouldReceive('sendSms')->times($fois)->andReturn(['success' => true]);
        $this->app->instance(OrangeSmsService::class, $sms);
    }

    public function test_code_genere_a_six_chiffres_et_nouveau_quota_d_essais(): void
    {
        $this->smsReussis(1);
        $this->code('771110020');
        for ($i = 0; $i < 4; $i++) {
            $this->postJson('/api/verify-code', ['telephone' => '771110020', 'code' => '000000']);
        }

        $this->postJson('/api/send-verification-code', ['telephone' => '771110020'])->assertOk();

        $code = UserVerificationCode::where('phone', '771110020')->value('code');
        $this->assertMatchesRegularExpression('/^\d{6}$/', (string) $code);

        $faux = $code === '000000' ? '111111' : '000000';
        $this->postJson('/api/verify-code', ['telephone' => '771110020', 'code' => $faux])
            ->assertJsonPath('essais_restants', 4);
    }

    public function test_pas_de_renvoi_avant_soixante_secondes(): void
    {
        $this->smsReussis(2);

        $this->postJson('/api/send-verification-code', ['telephone' => '771110021'])->assertOk();
        $this->postJson('/api/send-verification-code', ['telephone' => '771110021'])
            ->assertStatus(429)
            ->assertHeader('Retry-After');

        $this->travel(61)->seconds();
        $this->postJson('/api/send-verification-code', ['telephone' => '771110021'])->assertOk();
    }

    public function test_cinq_sms_maximum_par_numero_et_par_jour(): void
    {
        // 5 envois aujourd'hui + 1 demain ; le 6e du jour n'atteint pas Orange.
        $this->smsReussis(6);

        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/send-verification-code', ['telephone' => '771110022'])->assertOk();
            $this->travel(61)->seconds();
        }

        $this->postJson('/api/send-verification-code', ['telephone' => '771110022'])
            ->assertStatus(429)
            ->assertJsonPath('message', 'Nombre maximal de codes atteint pour ce numéro. Réessayez demain.');

        // Le lendemain, le numéro peut à nouveau recevoir un code.
        $this->travel(1)->days();
        $this->postJson('/api/send-verification-code', ['telephone' => '771110022'])->assertOk();
    }

    public function test_le_plafond_global_suspend_les_envois(): void
    {
        config(['otp.max_global_par_jour' => 2]);
        $this->smsReussis(2);

        $this->postJson('/api/send-verification-code', ['telephone' => '771110023'])->assertOk();
        $this->postJson('/api/send-verification-code', ['telephone' => '771110024'])->assertOk();
        $this->postJson('/api/send-verification-code', ['telephone' => '771110025'])
            ->assertStatus(503)
            ->assertJson(['success' => false]);

        $this->assertDatabaseMissing('user_verification_codes', ['phone' => '771110025']);
    }

    public function test_le_numero_doit_avoir_neuf_chiffres_sans_indicatif(): void
    {
        $sms = Mockery::mock(OrangeSmsService::class);
        $sms->shouldNotReceive('sendSms');
        $this->app->instance(OrangeSmsService::class, $sms);

        foreach (['701234', '2217712345678', '+221771234567', '77 123 45 67', '7712345678'] as $numero) {
            $this->postJson('/api/send-verification-code', ['telephone' => $numero])->assertStatus(422);
        }
    }

    public function test_aucun_prefixe_n_est_refuse(): void
    {
        $sms = Mockery::mock(OrangeSmsService::class);
        $sms->shouldReceive('sendSms')->with(Mockery::any(), Mockery::any(), '221711234567', Mockery::any())
            ->once()->andReturn(['success' => true]);
        $this->app->instance(OrangeSmsService::class, $sms);

        $this->postJson('/api/send-verification-code', ['telephone' => '711234567'])->assertOk();
    }
}
