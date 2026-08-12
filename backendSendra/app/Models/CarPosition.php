<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CarPosition extends Model
{
    use HasFactory;
    protected $guarded = [];

    public function photo()
    {
        return $this->hasMany(CarPhoto::class, 'card_id');
    }
}
