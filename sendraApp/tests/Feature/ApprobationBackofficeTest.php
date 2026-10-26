<?php

namespace Tests\Feature;

use App\Models\CarPosition;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * 26/10/2026 : fiche du signalement depuis les approbations (bouton retour,
 * décision intégrée, véhicule à côté du titre), recherche par plaque, PV avec
 * la signature de l'agent.
 */
class ApprobationBackofficeTest extends TestCase
{
    use RefreshDatabase;

    private function autorite(): User
    {
        return User::factory()->create(['role_id' => 3, 'is_enabled' => true]);
    }

    private function aDecider(array $attributs = []): CarPosition
    {
        return CarPosition::factory()->create($attributs + [
            'etat' => 'SIGNALE', 'is_approve' => false, 'dommage_image' => 'd.png',
            'marque' => 'Audi', 'model' => 'A4', 'numero_vehicule' => 'AA-573-LP',
        ]);
    }

    public function test_fiche_depuis_les_approbations(): void
    {
        $s = $this->aDecider();
        $this->actingAs($this->autorite())
            ->get("/dashboard/signalement/{$s->id}?depuis=approbations&filtre=attente")
            ->assertOk()
            ->assertSee('Retour aux approbations')
            ->assertSee('Audi A4 · AA-573-LP')
            ->assertSee('Enregistrer la décision')
            ->assertDontSee('Informations de base')
            ->assertDontSee('id="signature-form"', false);

        // Sans passer par les approbations : pas de bouton retour.
        $this->actingAs($this->autorite())->get("/dashboard/signalement/{$s->id}")
            ->assertDontSee('Retour aux approbations');
    }

    public function test_decision_depuis_la_fiche(): void
    {
        $s = $this->aDecider();
        $this->actingAs($this->autorite())
            ->patch("/dashboard/approbation/{$s->id}", ['approbation' => 'NON', 'motife_approbation' => 'Hors périmètre'])
            ->assertRedirect(route('approbations.index'));
        $this->assertSame('REJETE', $s->fresh()->etat);

        $this->actingAs($this->autorite())->get("/dashboard/signalement/{$s->id}")
            ->assertSee('Signalement rejeté')->assertSee('Hors périmètre')
            ->assertDontSee('Enregistrer la décision');
    }

    public function test_recherche_par_plaque_sans_tirets(): void
    {
        $this->aDecider();
        $this->aDecider(['numero_vehicule' => 'DK-1234-AB', 'marque' => 'Toyota', 'model' => 'Corolla']);

        foreach (['aa573lp', 'AA-573', 'aa 573 lp'] as $q) {
            $this->actingAs($this->autorite())->get('/dashboard/approbations?'.http_build_query(['q' => $q]))
                ->assertOk()->assertSee('AA-573-LP')->assertDontSee('DK-1234-AB');
        }
    }

    public function test_pv_du_back_office_avec_la_signature_de_l_agent(): void
    {
        $racine = sys_get_temp_dir().'/sendra-backend-'.uniqid();
        mkdir($racine.'/public', 0777, true);
        mkdir($racine.'/pv/signatures', 0777, true);
        config(['filesystems.disks.backend.root' => $racine.'/public']);
        file_put_contents($racine.'/pv/signatures/pv_1_x.png', base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII='));

        $s = $this->aDecider(['pv_signature' => 'pv/signatures/pv_1_x.png', 'pv_signe_at' => now(), 'pv_numero' => 'PV-2026-000001']);
        $this->assertStringStartsWith('data:image/png;base64,', \App\Support\SignatureAgent::dataUri($s));
        $this->actingAs($this->autorite())->get("/signalements/{$s->id}/pdf_constation")->assertOk();

        // Chemin malveillant ignoré.
        $s->pv_signature = '../../etc/passwd';
        $this->assertNull(\App\Support\SignatureAgent::dataUri($s));
    }
}
