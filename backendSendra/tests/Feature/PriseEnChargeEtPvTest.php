<?php

namespace Tests\Feature;

use App\Models\CarPhoto;
use App\Models\CarPosition;
use App\Models\User;
use App\Support\ImageOptimizer;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * Demandes du 23/10/2026 : signalement par type de véhicule, signalements
 * des autres citoyens, prise en charge exclusive par un agent, quatre photos
 * de constatation au plus, procès-verbal signé, avancement en cinq états,
 * photos redressées selon l'EXIF.
 */
class PriseEnChargeEtPvTest extends TestCase
{
    use RefreshDatabase;

    private const PNG = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
        Storage::fake('local');
    }

    private function jeton(string $telephone): array
    {
        $token = $this->postJson('/api/login', ['telephone' => $telephone, 'password' => 'password'])->json('token');

        return ['Authorization' => "Bearer {$token}"];
    }

    private function signalement(array $headers, array $extra = []): CarPosition
    {
        $this->postJson('/api/faireSignalement', array_merge([
            'vehicle_kind' => 'Camion',
            'description' => 'Devant la pharmacie',
            'commune' => 'Yoff',
            'latitude' => 14.75,
            'longitude' => -17.47,
            'photos' => [['position' => 'vue_ensemble', 'image' => self::PNG]],
        ], $extra), $headers)->assertOk()->assertJsonPath('message', 'Signalisation effectuée avec succès');

        return CarPosition::latest('id')->firstOrFail();
    }

    public function test_signalement_par_type_sans_titre(): void
    {
        User::factory()->create(['telephone' => '770000001', 'role_id' => 5]);
        $s = $this->signalement($this->jeton('770000001'));

        $this->assertSame('Camion', $s->vehicle_kind);
        $this->assertSame('Camion', $s->title);

        // Type inconnu refusé (erreur de validation du contrat v1 : HTTP 200 + 422).
        $this->postJson('/api/faireSignalement', [
            'vehicle_kind' => 'Avion', 'latitude' => 1, 'longitude' => 1,
            'photos' => [['position' => 'vue_ensemble', 'image' => self::PNG]],
        ], $this->jeton('770000001'))->assertJsonPath('status_code', 422);
    }

    public function test_citoyen_voit_les_signalements_des_autres_en_donnees_reduites(): void
    {
        User::factory()->create(['telephone' => '770000001', 'role_id' => 5]);
        User::factory()->create(['telephone' => '770000002', 'role_id' => 5]);
        $a = $this->jeton('770000001');
        $this->signalement($a);
        $this->signalement($this->jeton('770000002'), ['description' => 'secret']);

        $liste = $this->getJson('/api/signalementsCommunaute', $a)->assertOk()->json();
        $this->assertCount(2, $liste);
        $this->assertEqualsCanonicalizing([true, false], array_column($liste, 'est_mien'));
        $this->assertArrayNotHasKey('description', $liste[0]);
        $this->assertArrayNotHasKey('adresse_precise', $liste[0]);
        $this->assertSame('SIGNALE', $liste[0]['etat']);
        $this->assertCount(5, $liste[0]['avancement']);
    }

    public function test_prise_en_charge_exclusive(): void
    {
        User::factory()->create(['telephone' => '770000001', 'role_id' => 5]);
        $agent1 = User::factory()->create(['telephone' => '770000011', 'role_id' => 2, 'first_name' => 'Awa', 'last_name' => 'Diop']);
        User::factory()->create(['telephone' => '770000012', 'role_id' => 2]);
        $s = $this->signalement($this->jeton('770000001'));
        $h1 = $this->jeton('770000011');
        $h2 = $this->jeton('770000012');

        $this->postJson("/api/signalements/{$s->id}/prise-en-charge", [], $h1)
            ->assertOk()->assertJsonPath('pris_en_charge_par_moi', true);
        // Idempotent pour le même agent.
        $this->postJson("/api/signalements/{$s->id}/prise-en-charge", [], $h1)->assertOk();

        $this->postJson("/api/signalements/{$s->id}/prise-en-charge", [], $h2)
            ->assertStatus(409)->assertJsonPath('pris_en_charge_par', 'Awa Diop');

        // Le second agent ne peut rien saisir.
        $this->putJson("/api/infraction/{$s->id}", ['motif_infraction' => 'Épave'], $h2)->assertStatus(409);
        $this->putJson("/api/vehicule/{$s->id}", [
            'numero_vehicule' => 'X', 'marque' => 'X', 'type' => 'X', 'model' => 'X', 'categorie' => 'X',
            'couleur' => 'X', 'entretien' => 'BON', 'pays_etranger' => 'NON', 'vehicle_kind' => 'Camion',
        ], $h2)->assertStatus(409);

        $detail = $this->getJson("/api/listerSignalement/{$s->id}", $h2)->json('data.0');
        $this->assertFalse($detail['pris_en_charge_par_moi']);
        $this->assertSame('Awa Diop', $detail['pris_en_charge_par']);

        // Libération puis reprise par l'autre agent.
        $this->deleteJson("/api/signalements/{$s->id}/prise-en-charge", [], $h2)->assertStatus(409);
        $this->deleteJson("/api/signalements/{$s->id}/prise-en-charge", [], $h1)->assertOk();
        $this->postJson("/api/signalements/{$s->id}/prise-en-charge", [], $h2)->assertOk();
        $this->assertDatabaseHas('signalement_status_history', ['car_position_id' => $s->id, 'event' => 'pris_en_charge']);
        $this->assertSame($agent1->id === $s->fresh()->agent_id, false);
    }

    public function test_adresse_precise_non_modifiable_par_l_agent(): void
    {
        User::factory()->create(['telephone' => '770000001', 'role_id' => 5]);
        User::factory()->create(['telephone' => '770000011', 'role_id' => 2]);
        $s = $this->signalement($this->jeton('770000001'), ['adresse_precise' => 'Rue 10, Yoff']);
        $h = $this->jeton('770000011');

        $this->putJson("/api/infraction/{$s->id}", [
            'adresse_precise' => 'Autre adresse', 'motif_infraction' => 'Épave',
        ], $h)->assertOk();
        $this->assertSame('Rue 10, Yoff', $s->fresh()->adresse_precise);

        // Sans adresse envoyée : plus d'erreur de validation.
        $this->putJson("/api/infraction/{$s->id}", ['motif_infraction' => 'Épave'], $h)->assertOk();
    }

    public function test_quatre_photos_agent_au_plus_et_suppression(): void
    {
        User::factory()->create(['telephone' => '770000001', 'role_id' => 5]);
        User::factory()->create(['telephone' => '770000011', 'role_id' => 2]);
        $s = $this->signalement($this->jeton('770000001'));
        $h = $this->jeton('770000011');

        $ids = [];
        for ($i = 0; $i < 4; $i++) {
            $ids[] = $this->post("/api/constatation/{$s->id}/photos", [
                'photo' => UploadedFile::fake()->image("p$i.jpg", 40, 30),
            ], $h)->assertStatus(201)->json('id');
        }
        $this->post("/api/constatation/{$s->id}/photos", [
            'photo' => UploadedFile::fake()->image('p5.jpg', 40, 30),
        ], $h)->assertStatus(422);

        $this->deleteJson("/api/constatation/{$s->id}/photos/{$ids[0]}", [], $h)->assertOk();
        $this->assertSame(3, CarPhoto::where('card_id', $s->id)->where('position', 'agent_constat')->count());
        $photosAgent = $this->getJson("/api/listerSignalement/{$s->id}", $h)->json('data.0.photos_agent');
        $this->assertSame($ids[1], $photosAgent[0]['id']);
    }

    public function test_pv_signe_puis_telechargeable_par_lien_signe(): void
    {
        User::factory()->create(['telephone' => '770000001', 'role_id' => 5]);
        User::factory()->create(['telephone' => '770000011', 'role_id' => 2, 'first_name' => 'Awa', 'last_name' => 'Diop']);
        $s = $this->signalement($this->jeton('770000001'), ['adresse_precise' => 'Rue 10, Yoff']);
        $h = $this->jeton('770000011');

        $this->postJson("/api/signalements/{$s->id}/prise-en-charge", [], $h)->assertOk();
        // Pas de PV avant l'envoi pour approbation.
        $this->postJson("/api/signalements/{$s->id}/pv/signer", ['signature' => 'data:image/png;base64,'.self::PNG], $h)
            ->assertStatus(422);

        $this->putJson("/api/enregistrerDommages/{$s->id}", [
            'signature' => 'data:image/png;base64,'.self::PNG,
            'pieces_manquantes' => 'Roue avant gauche, rétroviseur',
        ], $h)->assertOk();

        $reponse = $this->postJson("/api/signalements/{$s->id}/pv/signer", [
            'signature' => 'data:image/png;base64,'.self::PNG,
        ], $h)->assertOk()->assertJsonPath('pv_signe', true);

        $s->refresh();
        $this->assertNotNull($s->pv_signe_at);
        $this->assertStringStartsWith('PV-', $s->pv_numero);
        Storage::disk('local')->assertExists($s->pv_path);
        $pdf = Storage::disk('local')->get($s->pv_path);
        $this->assertStringStartsWith('%PDF-1.4', $pdf);
        $this->assertStringContainsString('%%EOF', $pdf);

        // Deuxième signature refusée.
        $this->postJson("/api/signalements/{$s->id}/pv/signer", ['signature' => 'data:image/png;base64,'.self::PNG], $h)
            ->assertStatus(409);

        // Lien signé : téléchargeable sans jeton, refusé sans signature.
        $url = $reponse->json('pv_url_telechargement');
        $chemin = parse_url($url, PHP_URL_PATH).'?'.parse_url($url, PHP_URL_QUERY);
        $this->get($chemin)->assertOk()->assertHeader('Content-Type', 'application/pdf');
        $this->get("/api/pv/{$s->id}/telecharger")->assertStatus(403);

        $detail = $this->getJson("/api/listerSignalement/{$s->id}", $h)->json('data.0');
        $this->assertTrue($detail['pv_signe']);
        $this->assertSame('actuel', $detail['avancement'][2]['statut']);
        $this->assertSame('EN COURS', $detail['etat']);
    }

    public function test_avancement_parcours_complet(): void
    {
        User::factory()->create(['telephone' => '770000001', 'role_id' => 5]);
        $h = $this->jeton('770000001');
        $s = $this->signalement($h);

        $voir = fn () => $this->getJson('/api/voirSignalements', $h)->json('0');
        $statuts = fn () => collect($voir()['avancement'])->pluck('statut')->all();

        $this->assertSame(['signale', 'constate', 'approbation', 'enlevement', 'issue'],
            collect($voir()['avancement'])->pluck('etape')->all());
        $this->assertSame(['fait', 'a_venir', 'a_venir', 'a_venir', 'a_venir'], $statuts());
        $this->assertSame('SIGNALE', $voir()['etat']);

        // Envoi pour approbation : « En cours » dans le filtre, attente d'approbation.
        $s->update(['soumis_approbation_at' => now(), 'dommage_image' => 'd.png']);
        $this->assertSame('EN COURS', $voir()['etat']);
        $this->assertSame(['fait', 'fait', 'actuel', 'a_venir', 'a_venir'], $statuts());

        $s->update(['etat' => 'EN COURS', 'is_approve' => true]);
        $this->assertSame(['fait', 'fait', 'fait', 'actuel', 'a_venir'], $statuts());
        $this->assertSame('En attente d’enlèvement', $voir()['avancement'][3]['libelle']);

        $s->update(['non_removed_at' => now(), 'non_removal_reason' => 'Propriétaire absent']);
        $this->assertSame(['fait', 'fait', 'fait', 'echec', 'echec'], $statuts());
        $this->assertSame('Motif : Propriétaire absent', $voir()['avancement'][3]['detail']);
        $this->assertSame('NON RESOLU', $voir()['etat']);

        $s->update(['etat' => 'ENLEVE', 'non_removed_at' => null]);
        $this->assertSame(['fait', 'fait', 'fait', 'fait', 'fait'], $statuts());

        $s->update(['etat' => 'REJETE', 'is_approve' => false, 'motife_approbation' => 'Hors périmètre']);
        $this->assertSame(['fait', 'fait', 'echec', 'saute', 'saute'], $statuts());
        $this->assertSame('Motif : Hors périmètre', $voir()['avancement'][2]['detail']);
    }

    public function test_photo_redressee_selon_l_orientation_exif(): void
    {
        if (!function_exists('imagejpeg')) {
            $this->markTestSkipped('GD sans JPEG.');
        }
        // JPEG 40×20 étiqueté « orientation 6 » (à tourner de 90°).
        $img = imagecreatetruecolor(40, 20);
        ob_start();
        imagejpeg($img);
        $jpeg = ob_get_clean();
        $tiff = 'MM'.pack('n', 42).pack('N', 8).pack('n', 1)
            .pack('n', 0x0112).pack('n', 3).pack('N', 1).pack('n', 6).pack('n', 0).pack('N', 0);
        $app1 = "\xFF\xE1".pack('n', strlen($tiff) + 8)."Exif\0\0".$tiff;
        $jpeg = substr($jpeg, 0, 2).$app1.substr($jpeg, 2);

        $this->assertSame(6, ImageOptimizer::orientationExif($jpeg));
        $sortie = ImageOptimizer::resize($jpeg);
        [$w, $h] = getimagesizefromstring($sortie['binary']);
        $this->assertSame([20, 40], [$w, $h]);
    }
}
