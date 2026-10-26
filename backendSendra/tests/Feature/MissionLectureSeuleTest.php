<?php

namespace Tests\Feature;

use App\Models\Mission;
use App\Models\MissionRemoval;
use App\Models\MissionTruck;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * 26/10/2026 : une fois l'enlèvement validé, l'agent de terrain ne peut plus
 * que consulter ; une fois la mission terminée, le réceptionniste non plus.
 */
class MissionLectureSeuleTest extends TestCase
{
    use RefreshDatabase;

    private function jeton(User $u): array
    {
        $t = $this->postJson('/api/login', ['telephone' => $u->telephone, 'password' => 'password'])->json('token');

        return ['Authorization' => "Bearer {$t}"];
    }

    public function test_lecture_seule_apres_validation_puis_fin_de_mission(): void
    {
        Storage::fake('public');
        $terrain = User::factory()->create(['telephone' => '771110001', 'role_id' => 2]);
        $recep = User::factory()->create(['telephone' => '771110002', 'role_id' => 2]);
        $mission = Mission::forceCreate([
            'title' => 'M', 'type' => 'brute', 'status' => 'en_cours', 'scheduled_at' => now(),
            'address' => 'Yoff', 'latitude' => 14.7, 'longitude' => -17.4, 'created_by' => $terrain->id,
            'reception_agent_id' => $recep->id, 'pounds' => ['Fourrière'],
        ]);
        $mission->agents()->attach($terrain->id, ['checked_in_at' => now()]);
        $camion = MissionTruck::forceCreate(['mission_id' => $mission->id, 'registration' => 'DK-1']);
        $removal = MissionRemoval::forceCreate(['mission_id' => $mission->id, 'mission_truck_id' => $camion->id, 'created_by' => $terrain->id, 'vehicle_label' => 'Épave']);
        $ht = $this->jeton($terrain);
        $hr = $this->jeton($recep);

        $this->getJson("/api/missions/{$mission->id}", $ht)->assertOk()->assertJsonPath('data.read_only', false);

        $mission->update(['removal_validated_at' => now(), 'reception_checked_in_at' => now()]);

        $this->getJson("/api/missions/{$mission->id}", $ht)->assertJsonPath('data.read_only', true);
        $this->getJson("/api/missions/{$mission->id}", $hr)->assertJsonPath('data.read_only', false);
        $this->post("/api/missions/{$mission->id}/enlevements/{$removal->id}/modifier", ['mission_truck_id' => $camion->id], $ht)->assertStatus(423);
        $this->postJson("/api/missions/{$mission->id}/camions/{$camion->id}/destination", ['pound_name' => 'Fourrière'], $ht)->assertStatus(423);

        // Le réceptionniste travaille encore…
        $photos = collect(['front', 'back', 'left', 'right', 'sheet'])->mapWithKeys(fn ($k) => [$k => UploadedFile::fake()->image("$k.jpg", 20, 20)])->all();
        $this->post("/api/missions/{$mission->id}/receptions/{$removal->id}", $photos, $hr)->assertOk();

        // … puis plus rien une fois la mission terminée.
        $mission->update(['status' => 'terminee', 'completed_at' => now()]);
        $this->getJson("/api/missions/{$mission->id}", $hr)->assertJsonPath('data.read_only', true);
        $this->post("/api/missions/{$mission->id}/receptions/{$removal->id}", $photos, $hr)->assertStatus(423);
        $this->postJson("/api/missions/{$mission->id}/terminer", [], $hr)->assertStatus(423);
    }
}
