<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MissionRemovalPhoto extends Model
{
    protected $fillable = ['angle', 'path'];
    public function removal() { return $this->belongsTo(MissionRemoval::class); }
}
