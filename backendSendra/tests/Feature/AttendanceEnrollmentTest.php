<?php

namespace Tests\Feature;

use App\Models\AttendanceEnrollment;
use App\Models\User;
use App\Models\UserVerificationCode;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;
use Tymon\JWTAuth\Facades\JWTAuth;

class AttendanceEnrollmentTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'jwt.secret' => str_repeat('attendance-enrollment-test-only-', 3)]);
        DB::purge('sqlite');
        foreach (['2013_02_16_125654_create_roles_table.php', '2014_10_12_000000_create_users_table.php',
            '2025_01_17_164623_create_user_verification_codes_table.php',
            '2026_08_12_000001_add_columns_to_user_verification_codes_table.php'] as $migration) {
            (require database_path('migrations/'.$migration))->up();
        }
        $this->seed(\Database\Seeders\RoleSeeder::class);
        foreach (['2026_09_28_000001_create_attendance_tables.php',
            '2026_09_28_000002_create_attendance_enrollments.php',
            '2026_10_01_000001_create_attendance_face_tables.php',
            '2026_10_01_000002_create_attendance_device_tables.php'] as $migration) {
            (require database_path('migrations/'.$migration))->up();
        }
    }

    private function registration(): array
    {
        return ['first_name' => 'Awa', 'last_name' => 'Diop', 'telephone' => '778765432',
            'password' => 'MotdepasseSecurise123', 'password_confirmation' => 'MotdepasseSecurise123'];
    }

    public function test_mobile_registration_requires_verified_sms_and_creates_pending_account(): void
    {
        UserVerificationCode::create(['phone' => '778765432', 'code' => '123456',
            'expires_at' => now()->addMinutes(10)]);
        $this->postJson('/api/pointage/inscription', $this->registration())->assertUnprocessable();
        UserVerificationCode::where('phone', '778765432')->update(['verified_at' => now()]);
        $this->postJson('/api/pointage/inscription', $this->registration())->assertCreated()
            ->assertJsonPath('status', 'pending');
        $user = User::where('telephone', '778765432')->firstOrFail();
        $this->assertSame('Employe pointage', DB::table('roles')->where('id', $user->role_id)->value('nomRole'));
        $this->assertFalse((bool) $user->is_enabled);
        $this->assertTrue($user->attendanceEnrollment()->where('status', 'pending')->exists());
        $this->assertNull(UserVerificationCode::where('phone', '778765432')->first());
        $this->postJson('/api/pointage/inscription', $this->registration())->assertUnprocessable();
        $this->withToken(JWTAuth::fromUser($user))->getJson('/api/pointage/statut')->assertOk()
            ->assertJsonPath('status', 'pending');
        $this->getJson('/api/pointage/configuration')->assertForbidden();
    }

    public function test_existing_account_requests_access_from_pointage_app(): void
    {
        $user = User::factory()->create(['role_id' => 2, 'is_enabled' => true]);
        $this->withToken(JWTAuth::fromUser($user));
        $this->getJson('/api/pointage/statut')->assertOk()->assertJsonPath('status', 'not_registered');
        $this->postJson('/api/pointage/adhesion')->assertOk()->assertJsonPath('status', 'pending');
        $this->postJson('/api/pointage/adhesion')->assertOk()->assertJsonPath('status', 'pending');
        $this->assertSame(1, AttendanceEnrollment::count());
        $this->getJson('/api/pointage/configuration')->assertForbidden();
    }

    public function test_archived_user_cannot_request_access(): void
    {
        $user = User::factory()->create(['deleted' => true, 'role_id' => 2]);
        $this->withToken(JWTAuth::fromUser($user))->postJson('/api/pointage/adhesion')->assertForbidden();
    }

    public function test_pending_user_can_bind_one_device_and_only_that_device_gets_challenge(): void
    {
        $user = User::factory()->create(['role_id' => 2, 'is_enabled' => true]);
        $enrollment = AttendanceEnrollment::create(['user_id' => $user->id, 'status' => 'pending']);
        $this->withToken(JWTAuth::fromUser($user));
        $deviceId = (string) \Illuminate\Support\Str::uuid();
        $secret = str_repeat('ab', 32);
        $this->postJson('/api/pointage/appareil/enregistrer',
            ['device_id' => $deviceId, 'secret' => $secret])->assertOk();
        $this->postJson('/api/pointage/appareil/enregistrer',
            ['device_id' => (string) \Illuminate\Support\Str::uuid(), 'secret' => $secret])->assertStatus(409);
        $this->getJson('/api/pointage/statut')->assertJsonPath('registered_device_id', $deviceId);
        $enrollment->update(['status' => 'approved']);
        $this->postJson('/api/pointage/appareil/defi', ['device_id' => (string) \Illuminate\Support\Str::uuid(),
            'request_id' => (string) \Illuminate\Support\Str::uuid(), 'purpose' => 'arrival'])->assertForbidden();
        $this->postJson('/api/pointage/appareil/defi', ['device_id' => $deviceId,
            'request_id' => (string) \Illuminate\Support\Str::uuid(), 'purpose' => 'arrival'])->assertOk()
            ->assertJsonStructure(['challenge_id']);
    }
}
