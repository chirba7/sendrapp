<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\CarPosition>
 */
class CarPositionFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'latitude' => fake()->latitude(),
            'longitude' => fake()->longitude(),
            'title' => fake()->sentence(3),
            'commune' => fake()->city(),
        ];
    }
}
