<?php

namespace App\Services;

use App\Models\AttendanceAssignment;
use App\Models\AttendanceSession;
use App\Models\AttendanceSite;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class AttendanceService
{
    public function record(User $user, array $data): AttendanceSession
    {
        return DB::transaction(function () use ($user, $data) {
            // Sérialise les requêtes d'un même employé, y compris deux arrivées simultanées.
            $employee = User::whereKey($user->id)->lockForUpdate()->firstOrFail();
            abort_unless($employee->is_enabled && !$employee->deleted
                && $employee->attendanceEnrollment()->where('status', 'approved')->exists(),
                403, 'Inscription Pointage non approuvée.');

            $previous = AttendanceSession::where('user_id', $user->id)
                ->where(fn ($q) => $q->where('arrival_request_id', $data['request_id'])
                    ->orWhere('departure_request_id', $data['request_id']))->first();
            if ($previous) {
                $kind = $previous->arrival_request_id === $data['request_id'] ? 'arrival' : 'departure';
                if ($kind !== $data['type'] || $previous->attendance_site_id != $data['site_id']) {
                    $this->reject('request_id', 'Cet identifiant correspond à un autre pointage.');
                }
                return $previous;
            }

            $now = CarbonImmutable::now('UTC');
            $open = AttendanceSession::where('user_id', $user->id)->whereNull('departed_at')->first();
            if ($data['type'] === 'departure') {
                if (!$open) {
                    $this->reject('type', 'Aucune arrivée à clôturer.');
                }
                if ($open->attendance_site_id != $data['site_id']) {
                    $this->reject('site_id', 'Le départ doit être pointé sur le site de votre arrivée.');
                }
                if ($now->lessThan($open->scheduled_end)) {
                    $this->reject('type', 'Le départ est possible à partir de l’heure de fin prévue.');
                }
                // Une modification du planning ne change pas une journée déjà commencée.
                $position = $this->position($data, $open->schedule_snapshot, $now);
                $open->update([
                    'departed_at' => $now, 'departure_request_id' => $data['request_id'],
                    'departure_position' => $position,
                    'early_departure_minutes' => max(0, (int) ceil(($open->scheduled_end->timestamp - $now->timestamp) / 60)),
                ]);
                return $open->refresh();
            }
            if ($open) {
                $this->reject('type', 'Une arrivée est déjà ouverte. Pointez votre départ avant une nouvelle arrivée.');
            }
            $assignment = AttendanceAssignment::where('user_id', $user->id)->where('active', true)->first();
            if (!$assignment || $assignment->attendance_site_id != $data['site_id']) {
                $this->reject('site_id', 'Vous n’êtes pas affecté à ce site.');
            }
            $site = AttendanceSite::whereKey($data['site_id'])->where('active', true)->first();
            if (!$site) {
                $this->reject('site_id', 'Ce site de pointage est désactivé.');
            }
            $local = $now->setTimezone($site->timezone);
            [$date, $start, $end] = $this->schedule($assignment, $local);
            if (AttendanceSession::where('user_id', $user->id)->whereDate('work_date', $date->toDateString())->exists()) {
                $this->reject('type', 'Cette journée a déjà été pointée.');
            }
            $snapshot = array_merge($site->only(['name', 'latitude', 'longitude', 'radius_meters', 'max_accuracy_meters']), [
                'starts_at' => $assignment->starts_at, 'ends_at' => $assignment->ends_at,
                'late_tolerance_minutes' => $assignment->late_tolerance_minutes,
            ]);
            $position = $this->position($data, $snapshot, $now);
            $late = max(0, (int) ceil(($now->timestamp - $start->timestamp) / 60));
            return AttendanceSession::create([
                'user_id' => $user->id, 'attendance_site_id' => $site->id,
                'work_date' => $date->toDateString(), 'timezone' => $site->timezone,
                'scheduled_start' => $start->utc(), 'scheduled_end' => $end->utc(),
                'schedule_snapshot' => $snapshot, 'arrived_at' => $now,
                'arrival_request_id' => $data['request_id'], 'arrival_position' => $position,
                'arrival_status' => $now->lessThan($start) ? 'early' : ($late > $assignment->late_tolerance_minutes ? 'late' : 'on_time'),
                'late_minutes' => $late,
            ]);
        });
    }

    private function schedule(AttendanceAssignment $assignment, CarbonImmutable $local): array
    {
        // Une arrivée est admise à toute heure du jour prévu. Un service de nuit
        // garde sa date de début après minuit ; une arrivée juste avant minuit
        // peut être rattachée au service du lendemain.
        foreach ([-1, 1, 0] as $offset) {
            $date = $local->startOfDay()->addDays($offset);
            $start = $date->setTimeFromTimeString($assignment->starts_at);
            $end = $date->setTimeFromTimeString($assignment->ends_at);
            if ($end->lessThanOrEqualTo($start)) {
                $end = $end->addDay();
            }
            if (!in_array($date->dayOfWeekIso, array_map('intval', $assignment->weekdays), true)) {
                continue;
            }
            if (($offset === -1 && $end->toDateString() !== $date->toDateString() && $local->lessThan($end))
                || ($offset === 1 && $local->greaterThanOrEqualTo($start->subHours(2)))
                || $offset === 0) {
                return [$date, $start, $end];
            }
        }
        $this->reject('type', 'Aucun jour de travail prévu pour ce pointage.');
    }

    private function position(array $data, array $site, CarbonImmutable $now): array
    {
        $measured = CarbonImmutable::parse($data['measured_at'])->utc();
        if ($measured->lessThan($now->subSeconds(60)) || $measured->greaterThan($now->addSeconds(10))) {
            $this->reject('measured_at', 'La position est périmée ou datée dans le futur. Relancez la localisation.');
        }
        if ($data['accuracy_meters'] > $site['max_accuracy_meters']) {
            $this->reject('accuracy_meters', 'Position trop imprécise. Déplacez-vous vers un endroit dégagé et réessayez.');
        }
        $lat1 = deg2rad((float) $site['latitude']);
        $lat2 = deg2rad((float) $data['latitude']);
        $a = sin(($lat2 - $lat1) / 2) ** 2 + cos($lat1) * cos($lat2)
            * sin(deg2rad((float) $data['longitude'] - (float) $site['longitude']) / 2) ** 2;
        $distance = 6371000 * 2 * asin(sqrt(min(1, max(0, $a))));
        if ($distance > $site['radius_meters']) {
            $this->reject('position', 'Pointage refusé : vous êtes hors du rayon autorisé.');
        }
        return [
            'latitude' => (float) $data['latitude'], 'longitude' => (float) $data['longitude'],
            'accuracy_meters' => (float) $data['accuracy_meters'], 'distance_meters' => round($distance, 2),
            'measured_at' => $measured->toIso8601String(),
        ];
    }

    private function reject(string $field, string $message): never
    {
        throw ValidationException::withMessages([$field => $message]);
    }
}
