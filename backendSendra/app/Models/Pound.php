<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Pound extends Model
{
    protected $fillable = ['name','department','latitude','longitude','geofence','geofence_margin_meters','created_by'];
    protected $casts = ['geofence'=>'array','latitude'=>'float','longitude'=>'float'];
    public function missions() { return $this->hasMany(Mission::class, 'reception_pound_id'); }
}
