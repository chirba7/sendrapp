<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class MissionRemoval extends Model
{
    public function photos() { return $this->hasMany(MissionRemovalPhoto::class); }
    public function truck() { return $this->belongsTo(MissionTruck::class, 'mission_truck_id'); }
    public function vehicle() { return $this->belongsTo(CarPosition::class, 'car_position_id'); }
    public function reception() { return $this->hasOne(MissionReception::class); }
}
