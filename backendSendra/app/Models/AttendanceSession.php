<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AttendanceSession extends Model
{
    protected $guarded = ['id'];
    protected $casts = [
        'work_date' => 'date:Y-m-d', 'schedule_snapshot' => 'array',
        'scheduled_start' => 'immutable_datetime', 'scheduled_end' => 'immutable_datetime',
        'arrived_at' => 'immutable_datetime', 'departed_at' => 'immutable_datetime',
        'arrival_position' => 'array', 'departure_position' => 'array',
    ];

    public function site()
    {
        return $this->belongsTo(AttendanceSite::class, 'attendance_site_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
