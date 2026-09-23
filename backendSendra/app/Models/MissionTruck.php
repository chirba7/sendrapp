<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MissionTruck extends Model
{
    protected $fillable = ['trailer_brand', 'registration', 'driver_name', 'seats'];
}
