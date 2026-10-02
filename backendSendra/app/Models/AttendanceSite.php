<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AttendanceSite extends Model
{
    protected $fillable = ['name', 'address', 'latitude', 'longitude', 'radius_meters', 'max_accuracy_meters', 'timezone', 'active'];
    protected $casts = ['latitude' => 'float', 'longitude' => 'float', 'active' => 'boolean'];

    public function assignments()
    {
        return $this->hasMany(AttendanceAssignment::class);
    }
}
