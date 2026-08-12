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

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
    public function agent()
    {
        return $this->belongsTo(User::class, 'agent_id');
    }
}
