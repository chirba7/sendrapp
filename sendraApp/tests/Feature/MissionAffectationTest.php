<?php

namespace Tests\Feature;

use App\Models\CarPosition;
use App\Models\Commune;
use App\Models\Mission;
use App\Models\Pound;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Missions (26/10/2026) : un véhicule n'appartient qu'à une mission, un agent
 * est soit sur le terrain soit à la réception, l'historique liste toutes les
 * missions avec leur état.
 */
class MissionAffectationTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;
    private array $base;

    protected function setUp(): void
    {
        parent::setUp();
        // Table du backend (propriétaire du schéma des enlèvements), absente
        // des migrations du back-office : recréée ici pour les tests.
        if (! \Illuminate\Support\Facades\Schema::hasTable('mission_removals')) {
            \Illuminate\Support\Facades\Schema::create('mission_removals', function ($t) {
                $t->id(); $t->foreignId('mission_id'); $t->foreignId('car_position_id')->nullable();
                $t->foreignId('mission_truck_id')->nullable(); $t->string('vehicle_label')->nullable();
                $t->string('plate')->nullable(); $t->foreignId('created_by')->nullable(); $t->timestamps();
            });
        }
        $this->admin = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);
        $commune = Commune::forceCreate(['user_id' => $this->admin->id, 'nomCommune' => 'Yoff', 'latitude' => '14.75', 'longitude' => '-17.47']);
        $pound = Pound::forceCreate(['name' => 'Fourrière Yoff', 'latitude' => 14.7, 'longitude' => -17.4, 'geofence' => json_encode([])]);
        $this->base = ['type' => 'programmee', 'commune_id' => $commune->id, 'reception_pound_id' => $pound->id, 'scheduled_at' => now()->addDay()->format('Y-m-d H:i')];
    }

    private function agent(): User
    {
        return User::factory()->create(['role_id' => 2, 'is_enabled' => true]);
    }

    private function vehicule(): CarPosition
    {
        return CarPosition::factory()->create(['etat' => 'EN COURS', 'is_approve' => true]);
    }

    public function test_un_vehicule_ne_va_que_dans_une_mission(): void
    {
        [$a1, $a2, $r] = [$this->agent(), $this->agent(), $this->agent()];
        $v = $this->vehicule();
        $libre = $this->vehicule();

        $this->actingAs($this->admin)->post('/dashboard/missions', $this->base + [
            'agents' => [$a1->id], 'reception_agent_id' => $r->id, 'vehicles' => [$v->id],
        ])->assertSessionHasNoErrors();
        $premiere = Mission::firstOrFail();

        // Plus proposé à la création d'une autre mission…
        $this->actingAs($this->admin)->get('/dashboard/missions/creer')
            ->assertOk()->assertDontSee('#'.$v->id.' ·', false)->assertSee('#'.$libre->id.' ·', false);
        // … mais toujours visible quand on modifie sa propre mission.
        $this->actingAs($this->admin)->get("/dashboard/missions/{$premiere->id}/modifier")
            ->assertSee('#'.$v->id.' ·', false);

        // Refusé côté serveur même si on force le formulaire.
        $this->actingAs($this->admin)->post('/dashboard/missions', $this->base + [
            'agents' => [$a2->id], 'reception_agent_id' => $r->id, 'vehicles' => [$v->id],
        ])->assertSessionHasErrors('vehicles');

        // Mission annulée : le véhicule redevient disponible.
        $premiere->update(['status' => 'annulee']);
        $this->actingAs($this->admin)->post('/dashboard/missions', $this->base + [
            'agents' => [$a2->id], 'reception_agent_id' => $r->id, 'vehicles' => [$v->id],
        ])->assertSessionHasNoErrors();
    }

    public function test_agent_terrain_ou_reception_pas_les_deux(): void
    {
        $a = $this->agent();
        $this->actingAs($this->admin)->post('/dashboard/missions', $this->base + [
            'agents' => [$a->id], 'reception_agent_id' => $a->id, 'vehicles' => [$this->vehicule()->id],
        ])->assertSessionHasErrors('reception_agent_id');
    }

    public function test_historique_avec_missions_ouvertes_et_etat(): void
    {
        [$a, $r] = [$this->agent(), $this->agent()];
        foreach (['Ouverte' => 'planifiee', 'Finie' => 'terminee'] as $titre => $statut) {
            $this->actingAs($this->admin)->post('/dashboard/missions', $this->base + [
                'title' => $titre, 'agents' => [$a->id], 'reception_agent_id' => $r->id, 'vehicles' => [$this->vehicule()->id],
            ])->assertSessionHasNoErrors();
            Mission::where('title', $titre)->update(['status' => $statut]);
        }

        $this->actingAs($this->admin)->get('/dashboard/missions')
            ->assertOk()->assertSee('Ouverte')->assertSee('Finie')
            ->assertSee('Planifiée')->assertSee('Non terminée')->assertSee('Terminée le', false);
        $this->actingAs($this->admin)->get('/dashboard/missions?etat=ouvertes')
            ->assertSee('Ouverte')->assertDontSee('Finie');
        $this->actingAs($this->admin)->get('/dashboard/missions?etat=terminees')
            ->assertSee('Finie')->assertDontSee('>Ouverte<', false);
    }
}
