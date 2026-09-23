<?php

namespace App\Http\Controllers;

use App\Models\Mission;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MissionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()->id;
        $missions = Mission::query()
            ->where(function ($query) use ($userId) {
                $query->whereHas('agents', fn ($agents) => $agents->where('users.id', $userId))
                    ->orWhere(function ($direct) {
                        $direct->where('type', 'brute')->doesntHave('agents');
                    });
            })
            ->with(['agents' => fn ($query) => $query->where('users.id', $userId), 'commune', 'trucks'])
            ->whereNotIn('status', ['brouillon', 'annulee'])
            ->orderByRaw('scheduled_at IS NULL, scheduled_at')
            ->get()->map(fn (Mission $mission) => $this->serializeForAgent($mission));

        return response()->json(['data' => $missions]);
    }

    public function checkIn(Request $request, Mission $mission): JsonResponse
    {
        $data = $request->validate([
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'accuracy' => ['required', 'numeric', 'min:0', 'max:1000'],
        ]);

        $mission->load('commune');
        abort_unless($mission->commune, 422, 'La commune doit être renseignée avant le pointage.');
        $distance = $this->distanceFromGeofence(
            (float) $data['latitude'], (float) $data['longitude'], $mission->commune->geofence ?? []
        );
        $margin = (int) $mission->commune->geofence_margin_meters;
        if ($distance > $margin) {
            return response()->json([
                'message' => 'Vous êtes à '.round($distance).' m de la zone de la commune. Rapprochez-vous à moins de '.$margin.' m.',
                'distance_meters' => round($distance, 2),
            ], 422);
        }

        $mission = DB::transaction(function () use ($mission, $request) {
            $locked = Mission::with(['agents', 'commune'])->lockForUpdate()->findOrFail($mission->id);
            $assigned = $locked->agents->contains('id', $request->user()->id);
            if (! $assigned && $locked->type === 'brute' && $locked->agents->isEmpty()) {
                $locked->agents()->attach($request->user()->id);
                $locked->load('agents');
                return $locked;
            }
            abort_unless($assigned, 403, 'Cette mission a déjà été prise en charge ou ne vous est pas affectée.');
            return $locked;
        });

        $mission->agents()->updateExistingPivot($request->user()->id, [
            'checked_in_at' => now(), 'check_in_latitude' => $data['latitude'],
            'check_in_longitude' => $data['longitude'], 'check_in_accuracy' => $data['accuracy'],
            'check_in_distance' => $distance,
        ]);
        $mission->load(['agents' => fn ($query) => $query->where('users.id', $request->user()->id), 'vehicles', 'commune', 'trucks']);
        return response()->json(['message' => 'Présence confirmée.', 'data' => $this->serializeForAgent($mission)]);
    }

    private function serializeForAgent(Mission $mission): array
    {
        $assignment = $mission->agents->first();
        $checkedIn = (bool) optional($assignment?->pivot)->checked_in_at;
        if ($checkedIn && ! $mission->relationLoaded('vehicles')) $mission->load('vehicles');

        return [
            'id' => $mission->id, 'code' => $mission->code, 'title' => $mission->title,
            'type' => $mission->type === 'brute' ? 'directe' : $mission->type,
            'status' => $mission->status, 'scheduled_at' => $mission->scheduled_at?->toIso8601String(),
            'commune' => $mission->commune?->nomCommune, 'address' => $mission->commune?->nomCommune,
            'latitude' => $mission->commune?->latitude, 'longitude' => $mission->commune?->longitude,
            'check_in_radius_meters' => $mission->commune?->geofence_margin_meters,
            'provider_name' => $mission->provider_name, 'pounds' => $mission->pounds ?? [],
            'trucks' => $mission->trucks->map(fn ($truck) => [
                'trailer_brand' => $truck->trailer_brand, 'registration' => $truck->registration,
                'driver_name' => $truck->driver_name, 'seats' => $truck->seats,
            ])->values(),
            'checked_in' => $checkedIn,
            'vehicles' => $checkedIn ? $mission->vehicles->map(fn ($vehicle) => [
                'id' => $vehicle->id,
                'label' => trim(($vehicle->marque ?? '').' '.($vehicle->model ?? '')) ?: ($vehicle->title ?? 'Véhicule'),
                'plate' => $vehicle->numero_vehicule,
            ])->values() : [],
        ];
    }

    private function distanceFromGeofence(float $lat, float $lon, array $geometry): float
    {
        $ring = $geometry['coordinates'][0] ?? [];
        if (count($ring) < 3) return INF;
        $inside = false;
        for ($i = 0, $j = count($ring) - 1; $i < count($ring); $j = $i++) {
            [$xi, $yi] = $ring[$i]; [$xj, $yj] = $ring[$j];
            if ((($yi > $lat) !== ($yj > $lat)) && ($lon < ($xj - $xi) * ($lat - $yi) / (($yj - $yi) ?: 1e-12) + $xi)) $inside = ! $inside;
        }
        if ($inside) return 0;
        $minimum = INF;
        for ($i = 1; $i < count($ring); $i++) {
            $minimum = min($minimum, $this->pointSegmentDistance($lat, $lon, $ring[$i - 1][1], $ring[$i - 1][0], $ring[$i][1], $ring[$i][0]));
        }
        return $minimum;
    }

    private function pointSegmentDistance(float $lat, float $lon, float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $scaleX = 111320 * cos(deg2rad($lat)); $scaleY = 110540;
        $px = $lon * $scaleX; $py = $lat * $scaleY; $ax = $lon1 * $scaleX; $ay = $lat1 * $scaleY; $bx = $lon2 * $scaleX; $by = $lat2 * $scaleY;
        $dx = $bx - $ax; $dy = $by - $ay; $length = $dx * $dx + $dy * $dy;
        $t = $length > 0 ? max(0, min(1, (($px - $ax) * $dx + ($py - $ay) * $dy) / $length)) : 0;
        return hypot($px - ($ax + $t * $dx), $py - ($ay + $t * $dy));
    }
}
