<?php

namespace Tests\Feature;

// use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    /**
     * '/' est volontairement bloquée (abort(403)) — cette API n'expose
     * aucune page publique à la racine.
     */
    public function test_the_root_route_is_forbidden(): void
    {
        $response = $this->get('/');

        $response->assertStatus(403);
    }
}
