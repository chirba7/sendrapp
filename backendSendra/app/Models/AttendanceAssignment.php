<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AttendanceAssignment extends Model
{
    protected $fillable = ['user_id', 'attendance_site_id', 'weekdays', 'starts_at', 'ends_at', 'late_tolerance_minutes', 'active'];
    protected $casts = ['weekdays' => 'array', 'active' => 'boolean'];

    public function site()
    {
        return $this->belongsTo(AttendanceSite::class, 'attendance_site_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
