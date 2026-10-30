<?php

namespace Tests\Feature;

use App\Models\CarPhoto;
use App\Models\CarPosition;
use App\Models\Mission;
use App\Models\User;
use App\Support\HistoriqueSignalement;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;
use Tymon\JWTAuth\Facades\JWTAuth;

/**
 * Optimisations de l'audit du 29/10/2026 : moins de requêtes SQL, même
 * contenu de réponse.
 */
class PerformanceRequetesTest extends TestCase
{
    use RefreshDatabase;

    private array $dernieresRequetes = [];

    private const PNG = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

    private function signalements(User $auteur, int $n): void
    {
        for ($i = 0; $i < $n; $i++) {
            $s = CarPosition::factory()->create(['user_id' => $auteur->id, 'is_deleted' => false, 'created_at' => now()->subMinutes($n - $i)]);
            CarPhoto::forceCreate(['card_id' => $s->id, 'filepath' => "signalement/photo/p{$i}.jpg", 'position' => 'vue_ensemble', 'source' => 'citoyen']);
            DB::table('signalement_status_history')->insert([
                ['car_position_id' => $s->id, 'event' => 'cree', 'etat' => 'SIGNALE', 'is_approve' => null, 'motif' => null, 'user_id' => $auteur->id, 'created_at' => now()->subMinutes(10)],
                ['car_position_id' => $s->id, 'event' => 'pris_en_charge', 'etat' => 'SIGNALE', 'is_approve' => null, 'motif' => "m{$i}", 'user_id' => $auteur->id, 'created_at' => now()->subMinutes(5)],
            ]);
        }
    }

    /** @return array{0: mixed, 1: int} réponse et nombre de requêtes SQL */
    private function mesurer(callable $appel): array
    {
        DB::flushQueryLog();
        DB::enableQueryLog();
        $reponse = $appel();
        $n = count(DB::getQueryLog());
        $this->dernieresRequetes = array_column(DB::getQueryLog(), 'query');
        DB::disableQueryLog();

        return [$reponse, $n];
    }

    // ---------------------------------------------------- 1. historique

    public function test_voir_signalements_ne_fait_plus_une_requete_par_signalement(): void
    {
        $citoyen = User::factory()->create(['role_id' => 5]);
        $this->signalements($citoyen, 25);
        $entetes = ['Authorization' => 'Bearer '.JWTAuth::fromUser($citoyen)];

        [$r, $requetes] = $this->mesurer(fn () => $this->getJson('/api/voirSignalements', $entetes));

        $r->assertOk()->assertJsonCount(25);
        // jeton + signalements + photos + agents + historique (et non 25 de plus)
        $this->assertLessThanOrEqual(6, $requetes, "$requetes requêtes");

        // Même historique qu'une lecture signalement par signalement.
        foreach ($r->json() as $ligne) {
            $attendu = HistoriqueSignalement::pour(CarPosition::find($ligne['signalementId']));
            $this->assertSame(json_decode(json_encode($attendu), true), $ligne['historique']);
            $this->assertSame(['cree', 'pris_en_charge'], array_column($ligne['historique'], 'event'));
        }
    }

    public function test_lister_signalements_du_personnel_precharge_aussi_l_historique(): void
    {
        $citoyen = User::factory()->create(['role_id' => 5]);
        $this->signalements($citoyen, 12);
        $agent = User::factory()->create(['role_id' => 2]);
        $entetes = ['Authorization' => 'Bearer '.JWTAuth::fromUser($agent)];

        [$r, $requetes] = $this->mesurer(fn () => $this->getJson('/api/listerSignalements', $entetes));

        $r->assertOk()->assertJsonCount(10, 'data');
        $this->assertLessThanOrEqual(7, $requetes, "$requetes requêtes");
        $this->assertSame('m11', $r->json('data.0.historique.1.motif'));
    }

    // ---------------------------------------------------- 2. cache public

    public function test_la_liste_publique_est_mise_en_cache_et_est_mien_reste_personnel(): void
    {
        $alice = User::factory()->create(['role_id' => 5]);
        $bob = User::factory()->create(['role_id' => 5]);
        $this->signalements($alice, 3);
        $hA = ['Authorization' => 'Bearer '.JWTAuth::fromUser($alice)];
        $hB = ['Authorization' => 'Bearer '.JWTAuth::fromUser($bob)];

        [$r1, $q1] = $this->mesurer(fn () => $this->getJson('/api/signalementsCommunaute', $hA));
        auth()->guard()->forgetUser();
        [$r2, $q2] = $this->mesurer(fn () => $this->getJson('/api/signalementsCommunaute', $hB));

        $r1->assertOk()->assertJsonCount(3);
        $this->assertTrue($r1->json('0.est_mien'));
        $this->assertFalse($r2->json('0.est_mien'));
        // Second appel : plus aucune lecture des signalements ni des photos,
        // seulement l'utilisateur du jeton.
        $this->assertSame([], array_values(array_filter($this->dernieresRequetes,
            fn ($q) => str_contains($q, 'car_positions') || str_contains($q, 'car_photos'))));
        $this->assertGreaterThan($q2, $q1);

        // Jamais l'auteur dans la réponse, mêmes clés qu'avant.
        $this->assertSame(
            ['signalementId', 'latitude', 'longitude', 'titre', 'vehicle_kind', 'commune', 'etat', 'formatted_date', 'image_url', 'est_mien', 'public', 'avancement'],
            array_keys($r2->json('0'))
        );
    }

    public function test_un_nouveau_signalement_vide_le_cache(): void
    {
        $alice = User::factory()->create(['role_id' => 5]);
        $bob = User::factory()->create(['role_id' => 5]);
        $this->signalements($alice, 2);
        $hB = ['Authorization' => 'Bearer '.JWTAuth::fromUser($bob)];

        $this->getJson('/api/signalementsCommunaute', $hB)->assertJsonCount(2);

        $this->postJson('/api/faireSignalement', [
            'vehicle_kind' => 'Voiture', 'latitude' => 14.7, 'longitude' => -17.4,
            'photos' => [['position' => 'vue_ensemble', 'image' => self::PNG]],
        ], $hB)->assertOk();

        auth()->guard()->forgetUser();
        $this->getJson('/api/signalementsCommunaute', $hB)->assertJsonCount(3)->assertJsonPath('0.est_mien', true);
    }

    // ---------------------------------------------------- 3. taille des photos

    public function test_une_photo_de_plus_de_4_mo_est_refusee(): void
    {
        $citoyen = User::factory()->create(['role_id' => 5]);
        $h = ['Authorization' => 'Bearer '.JWTAuth::fromUser($citoyen)];

        $this->postJson('/api/faireSignalement', [
            'vehicle_kind' => 'Voiture', 'latitude' => 14.7, 'longitude' => -17.4,
            'photos' => [['position' => 'vue_ensemble', 'image' => str_repeat('A', 5600001)]],
        ], $h)->assertJsonPath('errorList.0', null)->assertJsonStructure(['errorList' => ['photos.0.image']]);

        $this->assertSame(0, CarPosition::count());
    }

    // ---------------------------------------------------- 4. missions

    private function mission(User $agent, array $attributs, int $vehicules): Mission
    {
        $m = Mission::forceCreate(array_merge([
            'title' => 'M', 'type' => 'brute', 'status' => 'en_cours', 'scheduled_at' => now(),
            'address' => 'Yoff', 'latitude' => 14.7, 'longitude' => -17.4, 'created_by' => $agent->id,
        ], $attributs));
        $m->agents()->attach($agent->id, ['checked_in_at' => now()]);
        $citoyen = User::factory()->create(['role_id' => 5]);
        for ($i = 0; $i < $vehicules; $i++) {
            $s = CarPosition::factory()->create(['user_id' => $citoyen->id]);
            CarPhoto::forceCreate(['card_id' => $s->id, 'filepath' => "p{$i}.jpg", 'position' => 'vue_ensemble', 'source' => 'citoyen']);
            $m->vehicles()->attach($s->id);
        }

        return $m;
    }

    public function test_missions_photos_chargees_d_avance_et_vieilles_missions_terminees_masquees(): void
    {
        $agent = User::factory()->create(['role_id' => 2]);
        $h = ['Authorization' => 'Bearer '.JWTAuth::fromUser($agent)];

        $enCours = $this->mission($agent, [], 2);
        $recente = $this->mission($agent, ['status' => 'terminee', 'completed_at' => now()->subDays(10)], 1);
        $vieille = $this->mission($agent, ['status' => 'terminee', 'completed_at' => now()->subDays(40)], 1);

        [$r, $avec2] = $this->mesurer(fn () => $this->getJson('/api/missions', $h));
        $ids = array_column($r->assertOk()->json('data'), 'id');
        $this->assertContains($enCours->id, $ids);
        $this->assertContains($recente->id, $ids);
        $this->assertNotContains($vieille->id, $ids);
        $m = collect($r->json('data'))->firstWhere('id', $enCours->id);
        $this->assertCount(2, $m['vehicles']);
        $this->assertCount(1, $m['vehicles'][0]['photos_signalement']);
        $this->assertNotNull($m['vehicles'][0]['thumbnail_url']);

        // Dix véhicules de plus : le nombre de requêtes ne bouge pas.
        $citoyen = User::factory()->create(['role_id' => 5]);
        for ($i = 0; $i < 10; $i++) {
            $s = CarPosition::factory()->create(['user_id' => $citoyen->id]);
            CarPhoto::forceCreate(['card_id' => $s->id, 'filepath' => "q{$i}.jpg", 'position' => 'vue_ensemble', 'source' => 'citoyen']);
            $enCours->vehicles()->attach($s->id);
        }
        auth()->guard()->forgetUser();
        [, $avec12] = $this->mesurer(fn () => $this->getJson('/api/missions', $h));
        $this->assertSame($avec2, $avec12, "$avec2 requêtes avant, $avec12 après");

        // La vieille mission reste consultable une à une.
        $this->getJson("/api/missions/{$vieille->id}", $h)->assertOk();
    }

    // ---------------------------------------------------- 6. index

    public function test_index_sur_uuid(): void
    {
        $index = collect(DB::select("SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = 'car_positions'"))->pluck('name');
        $this->assertContains('car_positions_uuid_index', $index);
        $this->assertTrue(Schema::hasColumn('car_positions', 'uuid'));
    }
}
