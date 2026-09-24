<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MissionDispatch extends Model
{
    protected $fillable = ['mission_id', 'mission_truck_id', 'pound_name', 'sheet_photo_path', 'created_by', 'departed_at'];
    protected $casts = ['departed_at' => 'datetime'];
    public function removals() { return $this->hasMany(MissionRemoval::class); }
}
