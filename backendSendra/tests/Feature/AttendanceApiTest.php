<?php

namespace Tests\Feature;

use App\Models\AttendanceAssignment;
use App\Models\AttendanceEnrollment;
use App\Models\AttendanceSession;
use App\Models\AttendanceSite;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Str;
use Tests\TestCase;
use Tymon\JWTAuth\Facades\JWTAuth;

class AttendanceApiTest extends TestCase
{
    private User $employee;
    private AttendanceSite $site;
    private AttendanceAssignment $assignment;

    protected function setUp(): void
    {
        parent::setUp();
        // Base isolée : aucune dépendance à MySQL ni aux migrations historiques des missions.
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:',
            'jwt.secret' => str_repeat('attendance-test-only-', 4),
            ]);
        DB::purge('sqlite');
        foreach (['2013_02_16_125654_create_roles_table.php', '2014_10_12_000000_create_users_table.php'] as $migration) {
            (require database_path('migrations/'.$migration))->up();
        }
        $this->seed(\Database\Seeders\RoleSeeder::class);
        foreach (['2026_09_28_000001_create_attendance_tables.php',
            '2026_09_28_000002_create_attendance_enrollments.php',
            '2026_10_01_000001_create_attendance_face_tables.php',
            '2026_10_01_000002_create_attendance_device_tables.php'] as $migration) {
            (require database_path('migrations/'.$migration))->up();
        }
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-09-28T08:08:00Z'));
        $this->employee = User::factory()->create(['role_id' => 2, 'is_enabled' => true]);
        AttendanceEnrollment::create(['user_id' => $this->employee->id, 'status' => 'approved']);
        $this->site = AttendanceSite::create(['name' => 'Dépôt Dakar', 'latitude' => 14.7167,
            'longitude' => -17.4677, 'radius_meters' => 100, 'max_accuracy_meters' => 30,
            'timezone' => 'Africa/Dakar', 'active' => true]);
        $this->assignment = AttendanceAssignment::create(['user_id' => $this->employee->id,
            'attendance_site_id' => $this->site->id, 'weekdays' => [1,2,3,4,5], 'starts_at' => '08:00:00',
            'ends_at' => '17:00:00', 'late_tolerance_minutes' => 5, 'active' => true]);
        $this->withToken(JWTAuth::fromUser($this->employee));
    }

    protected function tearDown(): void
    {
        CarbonImmutable::setTestNow();
        parent::tearDown();
    }

    private function payload(array $overrides = [], ?User $user = null): array
    {
        $data = array_merge(['request_id' => (string) Str::uuid(), 'type' => 'arrival',
            'site_id' => $this->site->id, 'latitude' => 14.7167, 'longitude' => -17.4677,
            'accuracy_meters' => 10, 'measured_at' => CarbonImmutable::now('UTC')->toIso8601String()], $overrides);
        $userId = ($user ?? $this->employee)->id;
        $secret = str_repeat('ab', 32);
        $device = DB::table('attendance_devices')->where('user_id', $userId)->first();
        $deviceId = $device?->device_id ?? (string) Str::uuid();
        if (!$device) DB::table('attendance_devices')->insert(['user_id' => $userId,
            'device_id' => $deviceId, 'encrypted_secret' => Crypt::encryptString($secret),
            'created_at' => now(), 'updated_at' => now()]);
        $challengeId = (string) Str::uuid();
        DB::table('attendance_device_challenges')->insert(['id' => $challengeId,
            'user_id' => $userId, 'device_id' => $deviceId,
            'purpose' => $data['type'], 'request_id' => $data['request_id'],
            'expires_at' => now()->addMinutes(2), 'created_at' => now(), 'updated_at' => now()]);
        return array_merge($data, ['device_id' => $deviceId, 'challenge_id' => $challengeId,
            'device_signature' => hash_hmac('sha256', implode('|', [$challengeId, $data['request_id'], $data['type']]), hex2bin($secret))]);
    }

    public function test_records_server_time_late_arrival_and_idempotent_retry(): void
    {
        $payload = $this->payload(['arrived_at' => '2026-09-28T07:00:00Z']);
        $response = $this->postJson('/api/pointage/pointer', $payload)->assertOk()
            ->assertJsonPath('session.arrival_status', 'late')->assertJsonPath('session.late_minutes', 8);
        $id = $response->json('session.id');
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-09-28T08:20:00Z'));
        $this->postJson('/api/pointage/pointer', $payload)->assertOk()->assertJsonPath('session.id', $id);
        $this->assertSame(1, AttendanceSession::count());
        $this->assertSame('08:08:00', AttendanceSession::first()->arrived_at->format('H:i:s'));
        $this->postJson('/api/pointage/pointer', $this->payload())->assertUnprocessable();
    }

    public function test_device_proof_is_required_and_bound_to_account(): void
    {
        $payload = $this->payload();
        $this->postJson('/api/pointage/pointer', array_diff_key($payload, ['device_signature' => true]))
            ->assertUnprocessable();
        $this->postJson('/api/pointage/pointer', array_merge($payload,
            ['device_id' => (string) Str::uuid()]))->assertForbidden();
        $this->postJson('/api/pointage/pointer', array_merge($payload,
            ['device_signature' => str_repeat('0', 64)]))->assertForbidden();
        $this->postJson('/api/pointage/pointer', array_merge($payload,
            ['challenge_id' => (string) Str::uuid()]))->assertForbidden();
        $this->assertSame(0, AttendanceSession::count());
    }

    public function test_rejects_outside_radius_imprecise_stale_future_and_invalid_coordinates(): void
    {
        foreach ([['latitude' => 14.72], ['accuracy_meters' => 31], ['accuracy_meters' => 0],
            ['measured_at' => '2026-09-28T08:06:59Z'], ['measured_at' => '2026-09-28T08:08:11Z'],
            ['measured_at' => '2026-09-28 08:08:00'], ['latitude' => 91]] as $invalid) {
            $this->postJson('/api/pointage/pointer', $this->payload($invalid))->assertUnprocessable();
        }
        $this->assertSame(0, AttendanceSession::count());
    }

    public function test_rejects_unassigned_disabled_site_and_non_working_day(): void
    {
        $this->assignment->update(['active' => false]);
        $this->postJson('/api/pointage/pointer', $this->payload())->assertUnprocessable();
        $this->assignment->update(['active' => true]);
        $this->site->update(['active' => false]);
        $this->postJson('/api/pointage/pointer', $this->payload())->assertUnprocessable();
        $this->site->update(['active' => true]);
        $this->assignment->update(['weekdays' => [2]]);
        $this->postJson('/api/pointage/pointer', $this->payload())->assertUnprocessable();
    }

    public function test_citizen_disabled_and_archived_accounts_are_rejected(): void
    {
        foreach ([['role_id' => 5], ['is_enabled' => false], ['deleted' => true]] as $attributes) {
            $user = User::factory()->create(array_merge(['role_id' => 2, 'is_enabled' => true], $attributes));
            auth()->guard()->forgetUser();
            $this->withToken(JWTAuth::fromUser($user))->getJson('/api/pointage/configuration')->assertForbidden();
        }
    }

    public function test_departure_requires_arrival_and_valid_position_and_preserves_schedule(): void
    {
        $this->postJson('/api/pointage/pointer', $this->payload(['type' => 'departure']))->assertUnprocessable();
        $this->postJson('/api/pointage/pointer', $this->payload())->assertOk();
        $this->assignment->update(['ends_at' => '20:00:00', 'active' => false]);
        $this->site->update(['latitude' => 0, 'active' => false]);
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-09-28T16:45:00Z'));
        $this->postJson('/api/pointage/pointer', $this->payload(['type' => 'departure', 'latitude' => 0]))->assertUnprocessable();
        $payload = $this->payload(['type' => 'departure']);
        $this->postJson('/api/pointage/pointer', $payload)->assertUnprocessable();
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-09-28T17:00:00Z'));
        $payload = $this->payload(['type' => 'departure']);
        $this->postJson('/api/pointage/pointer', $payload)->assertOk()->assertJsonPath('session.early_departure_minutes', 0);
        $this->postJson('/api/pointage/pointer', $payload)->assertOk();
        $this->postJson('/api/pointage/pointer', $this->payload(['type' => 'departure']))->assertUnprocessable();
    }

    public function test_overnight_shift_uses_start_day_and_departure_after_midnight(): void
    {
        $this->assignment->update(['starts_at' => '22:00:00', 'ends_at' => '06:00:00', 'weekdays' => [1]]);
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-09-29T00:10:00Z'));
        $this->postJson('/api/pointage/pointer', $this->payload())->assertOk()->assertJsonPath('session.work_date', '2026-09-28');
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-09-29T06:01:00Z'));
        $this->postJson('/api/pointage/pointer', $this->payload(['type' => 'departure']))->assertOk()
            ->assertJsonPath('session.early_departure_minutes', 0);
    }

    public function test_early_arrival_before_midnight_uses_next_work_day(): void
    {
        $this->assignment->update(['starts_at' => '00:30:00', 'ends_at' => '08:00:00', 'weekdays' => [2]]);
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-09-28T23:30:00Z'));
        $this->postJson('/api/pointage/pointer', $this->payload())->assertOk()
            ->assertJsonPath('session.work_date', '2026-09-29')->assertJsonPath('session.arrival_status', 'early');
    }

    public function test_tolerance_boundary_and_site_timezone(): void
    {
        $this->site->update(['timezone' => 'Indian/Reunion']);
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-09-28T04:05:00Z'));
        $this->postJson('/api/pointage/pointer', $this->payload())->assertOk()
            ->assertJsonPath('session.arrival_status', 'on_time')->assertJsonPath('session.late_minutes', 5);
    }

    public function test_arrival_is_accepted_before_or_after_schedule_on_work_day(): void
    {
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-09-28T03:00:00Z'));
        $this->postJson('/api/pointage/pointer', $this->payload())->assertOk()
            ->assertJsonPath('session.arrival_status', 'early');
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-09-28T17:00:00Z'));
        $this->postJson('/api/pointage/pointer', $this->payload(['type' => 'departure']))->assertOk();
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-09-29T20:00:00Z'));
        $this->postJson('/api/pointage/pointer', $this->payload())->assertOk()
            ->assertJsonPath('session.arrival_status', 'late');
    }

    public function test_history_is_private_and_request_id_cannot_change_operation(): void
    {
        $payload = $this->payload();
        $this->postJson('/api/pointage/pointer', $payload)->assertOk();
        $this->postJson('/api/pointage/pointer', array_merge($payload, ['type' => 'departure']))->assertForbidden();
        $user = User::factory()->create(['role_id' => 2, 'is_enabled' => true]);
        AttendanceEnrollment::create(['user_id' => $user->id, 'status' => 'approved']);
        auth()->guard()->forgetUser();
        $this->withToken(JWTAuth::fromUser($user))->getJson('/api/pointage/historique')->assertOk()->assertJsonCount(0, 'data');
        $this->getJson('/api/pointage/configuration')->assertOk()->assertJsonPath('assignment', null)->assertJsonPath('open_session', null);
    }

    public function test_second_completed_session_same_day_is_refused(): void
    {
        $this->postJson('/api/pointage/pointer', $this->payload())->assertOk();
        CarbonImmutable::setTestNow(CarbonImmutable::parse('2026-09-28T17:00:00Z'));
        $this->postJson('/api/pointage/pointer', $this->payload(['type' => 'departure']))->assertOk();
        $this->postJson('/api/pointage/pointer', $this->payload())->assertUnprocessable();
    }

    public function test_approved_pointage_app_user_can_use_attendance_api(): void
    {
        $roleId = DB::table('roles')->where('nomRole', 'Employe pointage')->value('id');
        $mobileUser = User::factory()->create(['role_id' => $roleId, 'is_enabled' => true]);
        AttendanceEnrollment::create(['user_id' => $mobileUser->id, 'status' => 'approved']);
        AttendanceAssignment::create(['user_id' => $mobileUser->id,
            'attendance_site_id' => $this->site->id, 'weekdays' => [1,2,3,4,5],
            'starts_at' => '08:00:00', 'ends_at' => '17:00:00',
            'late_tolerance_minutes' => 5, 'active' => true]);
        auth()->guard()->forgetUser();
        $this->withToken(JWTAuth::fromUser($mobileUser));
        $this->getJson('/api/pointage/configuration')->assertOk()
            ->assertJsonPath('assignment.user_id', $mobileUser->id);
        $this->postJson('/api/pointage/pointer', $this->payload([], $mobileUser))->assertOk();
        $this->assertSame($mobileUser->id, AttendanceSession::firstOrFail()->user_id);
    }
}
