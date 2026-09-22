<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Mission extends Model
{
    use HasFactory;

    protected $fillable = [
        'title', 'type', 'status', 'scheduled_at', 'address', 'latitude',
        'longitude', 'check_in_radius_meters', 'trailer_brand',
        'trailer_plate', 'pounds', 'created_by',
    ];

    protected $casts = [
        'scheduled_at' => 'datetime',
        'pounds' => 'array',
        'latitude' => 'float',
        'longitude' => 'float',
    ];

    public function agents()
    {
        return $this->belongsToMany(User::class)
            ->withPivot(['checked_in_at', 'check_in_latitude', 'check_in_longitude', 'check_in_accuracy', 'check_in_distance'])
            ->withTimestamps();
    }

    public function vehicles()
    {
        return $this->belongsToMany(CarPosition::class, 'mission_vehicle')->withTimestamps();
    }
}
