<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AttendanceEnrollment extends Model
{
    protected $fillable = ['user_id', 'status', 'approved_by', 'approved_at'];
    protected $casts = ['approved_at' => 'datetime'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
