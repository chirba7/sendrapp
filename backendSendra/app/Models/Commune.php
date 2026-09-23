<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Commune extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'nomCommune', 'departement', 'latitude', 'longitude', 'geofence', 'geofence_margin_meters'];

    protected $casts = ['geofence' => 'array', 'latitude' => 'float', 'longitude' => 'float'];
}
