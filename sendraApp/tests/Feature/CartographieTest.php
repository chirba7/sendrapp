<?php

namespace Tests\Feature;

use App\Models\CarPhoto;
use App\Models\CarPosition;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Carte du back-office (audit du 29/10/2026) : seulement les signalements
 * visibles, colonnes réduites, titre du citoyen échappé dans la bulle.
 */
class CartographieTest extends TestCase
{
    use RefreshDatabase;

    public function test_la_carte_n_affiche_que_les_signalements_visibles(): void
    {
        $admin = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);
        $visible = CarPosition::factory()->create(['is_deleted' => false, 'title' => 'Épave visible', 'etat' => 'SIGNALE']);
        CarPosition::factory()->create(['is_deleted' => true, 'title' => 'Épave supprimée']);
        CarPhoto::forceCreate(['card_id' => $visible->id, 'filepath' => 'signalement/photo/b.jpg']);
        CarPhoto::forceCreate(['card_id' => $visible->id, 'filepath' => 'signalement/photo/a-seconde.jpg']);

        $reponse = $this->actingAs($admin)->get('/dashboard/cartographie')->assertOk();

        $marqueurs = json_decode(json_encode($reponse->viewData('initialMarkers')), true);
        $this->assertCount(1, $marqueurs);
        $this->assertSame('Épave visible', $marqueurs[0]['titre']);
        // Première photo enregistrée, comme avant.
        $this->assertSame('signalement/photo/b.jpg', $marqueurs[0]['image']);
        $this->assertSame(
            ['signalementId', 'latitude', 'longitude', 'titre', 'commune', 'etat', 'formatted_date', 'image_url', 'image'],
            array_keys($marqueurs[0])
        );
        $reponse->assertDontSee('Épave supprimée');
    }

    public function test_le_titre_est_echappe_dans_la_bulle(): void
    {
        $admin = User::factory()->create(['role_id' => 1, 'is_enabled' => true]);
        CarPosition::factory()->create(['is_deleted' => false, 'title' => '<img src=x onerror=alert(1)>']);

        $this->actingAs($admin)->get('/dashboard/cartographie')
            ->assertOk()
            ->assertSee('${echapper(data.titre)}', false)
            ->assertDontSee('<img src=x onerror', false);
    }
}
