<?php

namespace Tests\Feature;

use App\Models\AttendanceAssignment;
use App\Models\AttendanceEnrollment;
use App\Models\AttendanceSite;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class AttendanceBackofficeTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        config(['database.default' => 'sqlite', 'database.connections.sqlite.database' => ':memory:']);
        DB::purge('sqlite');
        foreach (['2013_02_16_125654_create_roles_table.php', '2014_10_12_000000_create_users_table.php',
            '2014_10_12_200000_add_two_factor_columns_to_users_table.php'] as $migration) {
            (require database_path('migrations/'.$migration))->up();
        }
        $this->seed(\Database\Seeders\RoleSeeder::class);
        foreach (['2026_09_28_000001_create_attendance_tables.php',
            '2026_09_28_000002_create_attendance_enrollments.php',
            '2026_10_01_000001_create_attendance_face_tables.php',
            '2026_10_01_000002_create_attendance_device_tables.php'] as $migration) {
            (require database_path('migrations/'.$migration))->up();
        }
        $this->actingAs(User::factory()->create(['role_id' => 1, 'is_enabled' => true]));
    }

    private function siteData(array $overrides = []): array
    {
        return array_merge(['name' => 'Dépôt', 'latitude' => 14.7, 'longitude' => -17.4,
            'radius_meters' => 100, 'max_accuracy_meters' => 30, 'timezone' => 'Africa/Dakar', 'active' => 1], $overrides);
    }

    private function registerDevice(User $user): void
    {
        DB::table('attendance_devices')->insert(['user_id' => $user->id,
            'device_id' => (string) \Illuminate\Support\Str::uuid(), 'encrypted_secret' => 'test-only',
            'created_at' => now(), 'updated_at' => now()]);
    }

    public function test_admin_creates_and_edits_site_and_renders_all_pages(): void
    {
        $this->post('/dashboard/pointage/sites', $this->siteData())->assertRedirect(route('attendance.sites'));
        $site = AttendanceSite::firstOrFail();
        foreach (['/dashboard/pointage', '/dashboard/pointage/sites', '/dashboard/pointage/sites/creer',
            '/dashboard/pointage/sites/'.$site->id.'/modifier', '/dashboard/pointage/affectations'] as $url) {
            $this->get($url)->assertOk()->assertSee('Pointage');
        }
        $this->put('/dashboard/pointage/sites/'.$site->id, $this->siteData(['active' => 0]))->assertRedirect();
        $this->assertFalse($site->refresh()->active);
    }

    public function test_rejects_invalid_site_configuration(): void
    {
        foreach ([['latitude' => 91], ['radius_meters' => 0], ['max_accuracy_meters' => 101], ['timezone' => 'Inconnu']] as $invalid) {
            $this->postJson('/dashboard/pointage/sites', $this->siteData($invalid))->assertUnprocessable();
        }
        $this->assertSame(0, AttendanceSite::count());
    }

    public function test_non_admin_cannot_view_or_change_attendance(): void
    {
        $this->actingAs(User::factory()->create(['role_id' => 2, 'is_enabled' => true]));
        $this->get('/dashboard/pointage')->assertForbidden();
        $this->post('/dashboard/pointage/sites', $this->siteData())->assertForbidden();
    }

    public function test_assignment_replaces_schedule_and_excludes_citizens(): void
    {
        $site = AttendanceSite::create($this->siteData());
        $employee = User::factory()->create(['role_id' => 2, 'is_enabled' => true]);
        $enrollment = AttendanceEnrollment::create(['user_id' => $employee->id, 'status' => 'pending']);
        $this->registerDevice($employee);
        $this->patch('/dashboard/pointage/inscriptions/'.$enrollment->id.'/valider', ['identity_checked' => '1'])->assertRedirect();
        $payload = ['user_id' => $employee->id, 'attendance_site_id' => $site->id, 'weekdays' => [1,2,3,4,5],
            'starts_at' => '08:00', 'ends_at' => '17:00', 'late_tolerance_minutes' => 5];
        $this->post('/dashboard/pointage/affectations', $payload)->assertRedirect();
        $this->post('/dashboard/pointage/affectations', array_merge($payload, ['starts_at' => '09:00']))->assertRedirect();
        $this->assertSame(1, AttendanceAssignment::count());
        $this->assertStringStartsWith('09:00', AttendanceAssignment::first()->starts_at);
        $this->get('/dashboard/pointage/affectations')->assertOk()->assertSee($employee->first_name);
        $this->patch('/dashboard/pointage/affectations/'.AttendanceAssignment::first()->id.'/desactiver')->assertRedirect();
        $this->assertFalse(AttendanceAssignment::first()->active);
        $citizen = User::factory()->create(['role_id' => 5, 'is_enabled' => true]);
        $this->postJson('/dashboard/pointage/affectations', array_merge($payload, ['user_id' => $citizen->id]))->assertUnprocessable();
        $this->postJson('/dashboard/pointage/affectations', array_merge($payload, ['ends_at' => '08:00']))->assertUnprocessable();
    }

    public function test_only_approved_app_enrollments_can_be_assigned(): void
    {
        $site = AttendanceSite::create($this->siteData());
        $registered = User::factory()->create(['role_id' => 5, 'is_enabled' => false]);
        $unregistered = User::factory()->create(['role_id' => 2, 'is_enabled' => true]);
        $enrollment = AttendanceEnrollment::create(['user_id' => $registered->id, 'status' => 'pending']);
        $this->registerDevice($registered);
        $payload = ['attendance_site_id' => $site->id, 'weekdays' => [1,2,3,4,5],
            'starts_at' => '08:00', 'ends_at' => '17:00', 'late_tolerance_minutes' => 5];
        $this->postJson('/dashboard/pointage/affectations', $payload + ['user_id' => $registered->id])->assertUnprocessable();
        $this->postJson('/dashboard/pointage/affectations', $payload + ['user_id' => $unregistered->id])->assertUnprocessable();
        $this->patch('/dashboard/pointage/inscriptions/'.$enrollment->id.'/valider', ['identity_checked' => '1'])->assertRedirect();
        // Le compte citoyen préexistant ne devient pas automatiquement un compte personnel.
        $this->assertFalse((bool) $registered->refresh()->is_enabled);
        $this->postJson('/dashboard/pointage/affectations', $payload + ['user_id' => $registered->id])->assertUnprocessable();
        $registered->is_enabled = true;
        $registered->save();
        $this->post('/dashboard/pointage/affectations', $payload + ['user_id' => $registered->id])->assertRedirect();
        $this->patch('/dashboard/pointage/inscriptions/'.$enrollment->id.'/desactiver')->assertRedirect();
        $this->assertFalse(AttendanceAssignment::where('user_id', $registered->id)->firstOrFail()->active);
        $this->postJson('/dashboard/pointage/affectations', $payload + ['user_id' => $registered->id])->assertUnprocessable();
    }

    public function test_approval_activates_a_new_pointage_app_account(): void
    {
        $roleId = DB::table('roles')->where('nomRole', 'Employe pointage')->value('id');
        $employee = User::factory()->create(['role_id' => $roleId, 'is_enabled' => false]);
        $enrollment = AttendanceEnrollment::create(['user_id' => $employee->id, 'status' => 'pending']);
        $this->patch('/dashboard/pointage/inscriptions/'.$enrollment->id.'/valider', ['identity_checked' => '1'])->assertStatus(422);
        $this->registerDevice($employee);
        $this->get('/dashboard/pointage/affectations')->assertOk()
            ->assertSee($employee->first_name)->assertSee('En attente');
        $this->patch('/dashboard/pointage/inscriptions/'.$enrollment->id.'/valider', ['identity_checked' => '1'])->assertRedirect();
        $this->assertTrue((bool) $employee->refresh()->is_enabled);
        $this->assertSame('approved', $enrollment->refresh()->status);
        $this->get('/dashboard/pointage/affectations')->assertOk()->assertSee($employee->telephone);
    }

    public function test_admin_can_archive_pointage_account_without_deleting_history(): void
    {
        $roleId = DB::table('roles')->where('nomRole', 'Employe pointage')->value('id');
        $employee = User::factory()->create(['role_id' => $roleId, 'is_enabled' => true]);
        $enrollment = AttendanceEnrollment::create(['user_id' => $employee->id, 'status' => 'approved']);
        $this->delete('/dashboard/pointage/inscriptions/'.$enrollment->id)->assertRedirect(route('attendance.assignments'));
        $this->assertTrue((bool) $employee->refresh()->deleted);
        $this->assertFalse((bool) $employee->is_enabled);
        $this->assertSame('disabled', $enrollment->refresh()->status);
        $this->get('/dashboard/pointage/affectations')->assertDontSee($employee->telephone);
    }

    public function test_reset_device_suspends_pointage_until_new_enrollment(): void
    {
        $employee = User::factory()->create(['role_id' => 2, 'is_enabled' => true]);
        $enrollment = AttendanceEnrollment::create(['user_id' => $employee->id, 'status' => 'approved']);
        $this->registerDevice($employee);
        $this->patch('/dashboard/pointage/inscriptions/'.$enrollment->id.'/reinitialiser-telephone')
            ->assertRedirect(route('attendance.assignments'));
        $this->assertSame('pending', $enrollment->refresh()->status);
        $this->assertFalse(DB::table('attendance_devices')->where('user_id', $employee->id)->exists());
    }

    public function test_shared_sendra_account_cannot_be_deleted_from_pointage(): void
    {
        $employee = User::factory()->create(['role_id' => 2, 'is_enabled' => true]);
        $enrollment = AttendanceEnrollment::create(['user_id' => $employee->id, 'status' => 'approved']);
        $this->deleteJson('/dashboard/pointage/inscriptions/'.$enrollment->id)->assertStatus(422);
        $this->assertFalse((bool) $employee->refresh()->deleted);
    }
}
