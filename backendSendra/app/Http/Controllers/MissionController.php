<?php

namespace App\Http\Controllers;

use App\Models\Mission;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MissionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $missions = Mission::query()
            ->whereHas('agents', fn ($query) => $query->where('users.id', $request->user()->id))
            ->with(['agents' => fn ($query) => $query->where('users.id', $request->user()->id)])
            ->whereNotIn('status', ['brouillon', 'annulee'])
            ->orderBy('scheduled_at')
            ->get()
            ->map(fn (Mission $mission) => $this->serializeForAgent($mission));

        return response()->json(['data' => $missions]);
    }

    public function checkIn(Request $request, Mission $mission): JsonResponse
    {
        $data = $request->validate([
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'accuracy' => ['required', 'numeric', 'min:0', 'max:1000'],
        ]);

        $assignment = $mission->agents()->where('users.id', $request->user()->id)->first();
        abort_unless($assignment, 403, 'Cette mission ne vous est pas affectée.');

        $distance = $this->distanceInMeters(
            (float) $data['latitude'],
            (float) $data['longitude'],
            (float) $mission->latitude,
            (float) $mission->longitude,
        );

        if ($distance > $mission->check_in_radius_meters) {
            return response()->json([
                'message' => 'Vous êtes à '.round($distance).' m du lieu. Rapprochez-vous à moins de '.$mission->check_in_radius_meters.' m.',
                'distance_meters' => round($distance, 2),
            ], 422);
        }

        $mission->agents()->updateExistingPivot($request->user()->id, [
            'checked_in_at' => now(),
            'check_in_latitude' => $data['latitude'],
            'check_in_longitude' => $data['longitude'],
            'check_in_accuracy' => $data['accuracy'],
            'check_in_distance' => $distance,
        ]);

        $mission->load(['agents' => fn ($query) => $query->where('users.id', $request->user()->id), 'vehicles']);

        return response()->json([
            'message' => 'Présence confirmée.',
            'data' => $this->serializeForAgent($mission),
        ]);
    }

    private function serializeForAgent(Mission $mission): array
    {
        $assignment = $mission->agents->first();
        $checkedIn = (bool) optional($assignment?->pivot)->checked_in_at;

        if ($checkedIn && ! $mission->relationLoaded('vehicles')) {
            $mission->load('vehicles');
        }

        return [
            'id' => $mission->id,
            'title' => $mission->title,
            'type' => $mission->type,
            'status' => $mission->status,
            'scheduled_at' => $mission->scheduled_at?->toIso8601String(),
            'address' => $mission->address,
            'latitude' => $mission->latitude,
            'longitude' => $mission->longitude,
            'check_in_radius_meters' => $mission->check_in_radius_meters,
            'trailer_brand' => $mission->trailer_brand,
            'trailer_plate' => $mission->trailer_plate,
            'pounds' => $mission->pounds ?? [],
            'checked_in' => $checkedIn,
            'vehicles' => $checkedIn
                ? $mission->vehicles->map(fn ($vehicle) => [
                    'id' => $vehicle->id,
                    'label' => trim(($vehicle->marque ?? '').' '.($vehicle->model ?? '')) ?: ($vehicle->title ?? 'Véhicule'),
                    'plate' => $vehicle->numero_vehicule,
                  ])->values()
                : [],
        ];
    }

    private function distanceInMeters(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadius = 6371000;
        $deltaLat = deg2rad($lat2 - $lat1);
        $deltaLon = deg2rad($lon2 - $lon1);
        $a = sin($deltaLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($deltaLon / 2) ** 2;

        return $earthRadius * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }
}
