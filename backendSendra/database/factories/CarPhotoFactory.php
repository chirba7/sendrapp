<?php

namespace Database\Factories;

use App\Models\CarPosition;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\CarPhoto>
 */
class CarPhotoFactory extends Factory
{
    public function definition(): array
    {
        return [
            'card_id' => CarPosition::factory(),
            'filepath' => 'signalement/photo/' . fake()->uuid() . '.png',
        ];
    }
}
