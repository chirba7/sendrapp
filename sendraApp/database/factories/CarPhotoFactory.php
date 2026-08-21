<?php

namespace Database\Factories;

use App\Models\CarPosition;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\CarPhoto>
 */
class CarPhotoFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'card_id' => CarPosition::factory(),
            'filepath' => 'signalement/photo/' . fake()->uuid() . '.png',
        ];
    }
}
