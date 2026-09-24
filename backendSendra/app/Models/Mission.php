<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Mission extends Model
{
    use HasFactory;

    protected $fillable = [
        'code', 'title', 'commune_id', 'type', 'status', 'provider_name', 'scheduled_at', 'address', 'latitude',
        'longitude', 'check_in_radius_meters', 'trailer_brand',
        'trailer_plate', 'pounds', 'created_by', 'reception_agent_id', 'reception_pound_id',
        'removal_validated_at', 'removal_validated_by', 'reception_checked_in_at',
        'reception_check_in_latitude', 'reception_check_in_longitude', 'completed_at',
    ];

    protected $casts = [
        'scheduled_at' => 'datetime',
        'pounds' => 'array',
        'latitude' => 'float',
        'longitude' => 'float',
        'removal_validated_at' => 'datetime', 'reception_checked_in_at' => 'datetime', 'completed_at' => 'datetime',
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

    public function commune()
    {
        return $this->belongsTo(Commune::class);
    }

    public function trucks()
    {
        return $this->hasMany(MissionTruck::class);
    }

    public function removals()
    {
        return $this->hasMany(MissionRemoval::class);
    }

    public function dispatches()
    {
        return $this->hasMany(MissionDispatch::class);
    }
    public function receptionAgent() { return $this->belongsTo(User::class, 'reception_agent_id'); }
    public function receptionPound() { return $this->belongsTo(Pound::class, 'reception_pound_id'); }
    public function receptions() { return $this->hasMany(MissionReception::class); }
}
