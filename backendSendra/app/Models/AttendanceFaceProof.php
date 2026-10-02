<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AttendanceFaceProof extends Model
{
    public $incrementing = false;
    protected $keyType = 'string';
    protected $fillable = ['id', 'user_id', 'purpose', 'request_id', 'expires_at', 'consumed_at'];
    protected $casts = ['expires_at' => 'datetime', 'consumed_at' => 'datetime'];
}
