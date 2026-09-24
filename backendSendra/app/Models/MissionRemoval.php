<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MissionRemoval extends Model
{
    protected $fillable = ['mission_id', 'car_position_id', 'mission_truck_id', 'mission_dispatch_id', 'vehicle_label', 'plate', 'pound_name', 'sheet_photo_path', 'created_by'];

    public function photos() { return $this->hasMany(MissionRemovalPhoto::class); }
    public function truck() { return $this->belongsTo(MissionTruck::class, 'mission_truck_id'); }
    public function vehicle() { return $this->belongsTo(CarPosition::class, 'car_position_id'); }
    public function dispatch() { return $this->belongsTo(MissionDispatch::class, 'mission_dispatch_id'); }
}
