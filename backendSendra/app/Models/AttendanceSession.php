<?php

namespace App\Models;

use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Model;

class AttendanceSession extends Model
{
    protected $guarded = ['id'];
    protected $casts = [
        'work_date' => 'date:Y-m-d', 'schedule_snapshot' => 'array',
        'scheduled_start' => 'immutable_datetime', 'scheduled_end' => 'immutable_datetime',
        'arrived_at' => 'immutable_datetime', 'departed_at' => 'immutable_datetime',
        'arrival_position' => 'array', 'departure_position' => 'array',
        'break_started_at' => 'immutable_datetime', 'break_ended_at' => 'immutable_datetime',
        'break_start_position' => 'array', 'break_end_position' => 'array',
    ];

    public function isCurrentAt(CarbonImmutable $now): bool
    {
        $local = $now->setTimezone($this->timezone);
        $workDate = $this->work_date->format('Y-m-d');
        if ($workDate === $local->toDateString()) return true;
        // Une arrivée anticipée peut appartenir au service du lendemain.
        if ($workDate === $local->addDay()->toDateString()) return true;
        // Après minuit, un service de nuit reste actif jusqu'à deux heures après sa fin prévue.
        return $workDate === $local->subDay()->toDateString()
            && $this->scheduled_end->setTimezone($this->timezone)->toDateString() === $local->toDateString()
            && $now->lessThanOrEqualTo($this->scheduled_end->addHours(2));
    }

    public function site()
    {
        return $this->belongsTo(AttendanceSite::class, 'attendance_site_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
