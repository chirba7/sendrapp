<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AttendanceFaceProfile extends Model
{
    protected $fillable = ['user_id', 'encrypted_embedding', 'model_version'];
    protected $hidden = ['encrypted_embedding'];
}
