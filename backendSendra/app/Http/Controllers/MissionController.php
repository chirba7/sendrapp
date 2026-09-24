<?php

namespace App\Http\Controllers;

use App\Models\Mission;
use App\Models\MissionRemoval;
use App\Support\ImageOptimizer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

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
            ->with([
                'agents' => fn ($query) => $query->where('users.id', $userId),
                'commune', 'trucks', 'vehicles', 'removals.photos', 'removals.vehicle',
                'removals.dispatch', 'dispatches',
            ])
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

    public function show(Request $request, Mission $mission): JsonResponse
    {
        $this->assertVisibleToAgent($request, $mission);
        $mission->load($this->agentRelations($request->user()->id));
        return response()->json(['data' => $this->serializeForAgent($mission)]);
    }

    public function storeRemoval(Request $request, Mission $mission): JsonResponse
    {
        $this->assertCheckedIn($request, $mission);
        $data = $request->validate([
            'car_position_id' => ['nullable', 'integer', Rule::exists('mission_vehicle', 'car_position_id')->where('mission_id', $mission->id)],
            'mission_truck_id' => ['required', 'integer', Rule::exists('mission_trucks', 'id')->where('mission_id', $mission->id)],
            'vehicle_label' => ['nullable', 'string', 'max:255'],
            'plate' => ['nullable', 'string', 'max:100'],
            'front' => ['required', 'image', 'max:10240'],
            'back' => ['required', 'image', 'max:10240'],
            'left' => ['required', 'image', 'max:10240'],
            'right' => ['required', 'image', 'max:10240'],
        ]);
        if ($mission->type === 'brute' && ! empty($data['car_position_id'])) {
            abort(422, 'Une mission directe ne contient pas de véhicule présélectionné.');
        }

        $removal = DB::transaction(function () use ($request, $mission, $data) {
            $removal = MissionRemoval::create([
                'mission_id' => $mission->id,
                'car_position_id' => $data['car_position_id'] ?? null,
                'mission_truck_id' => $data['mission_truck_id'],
                'vehicle_label' => $data['vehicle_label'] ?? null,
                'plate' => $data['plate'] ?? null,
                'created_by' => $request->user()->id,
            ]);
            foreach (['front', 'back', 'left', 'right'] as $angle) {
                $removal->photos()->create(['angle' => $angle, 'path' => $this->storeImage($request->file($angle), "missions/{$mission->id}/enlevements/{$removal->id}")]);
            }
            return $removal;
        });

        $mission->load($this->agentRelations($request->user()->id));
        return response()->json(['message' => 'Enlèvement enregistré.', 'data' => $this->serializeForAgent($mission)], 201);
    }

    public function storeRemovalDestination(Request $request, Mission $mission, MissionRemoval $removal): JsonResponse
    {
        $this->assertCheckedIn($request, $mission);
        abort_unless($removal->mission_id === $mission->id, 404);
        $data = $request->validate([
            'pound_name' => ['required', 'string', 'max:255'],
            'sheet' => ['required', 'image', 'max:10240'],
        ]);
        if (! empty($mission->pounds) && ! in_array($data['pound_name'], $mission->pounds, true)) {
            abort(422, 'Cette fourrière ne fait pas partie de la mission.');
        }

        $removal->update([
            'pound_name' => $data['pound_name'],
            'sheet_photo_path' => $this->storeImage($request->file('sheet'), "missions/{$mission->id}/enlevements/{$removal->id}"),
        ]);

        $mission->load($this->agentRelations($request->user()->id));
        return response()->json(['message' => 'Fourrière et fiche du véhicule enregistrées.', 'data' => $this->serializeForAgent($mission)]);
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
            'provider_name' => $mission->provider_name,
            'pounds' => $checkedIn ? ($mission->pounds ?? []) : [],
            'trucks' => $checkedIn ? $mission->trucks->map(fn ($truck) => [
                'id' => $truck->id, 'trailer_brand' => $truck->trailer_brand, 'registration' => $truck->registration,
                'driver_name' => $truck->driver_name, 'seats' => $truck->seats,
            ])->values() : [],
            'checked_in' => $checkedIn,
            'vehicles' => $checkedIn ? $mission->vehicles->map(fn ($vehicle) => [
                'id' => $vehicle->id,
                'label' => trim(($vehicle->marque ?? '').' '.($vehicle->model ?? '')) ?: ($vehicle->title ?? 'Véhicule'),
                'plate' => $vehicle->numero_vehicule,
            ])->values() : [],
            'removals' => $checkedIn ? $mission->removals->map(fn ($removal) => [
                'id' => $removal->id, 'car_position_id' => $removal->car_position_id,
                'vehicle_label' => $removal->vehicle_label ?: trim(($removal->vehicle?->marque ?? '').' '.($removal->vehicle?->model ?? '')) ?: 'Véhicule',
                'plate' => $removal->plate ?: $removal->vehicle?->numero_vehicule,
                'mission_truck_id' => $removal->mission_truck_id,
                'dispatch_id' => $removal->mission_dispatch_id,
                'pound_name' => $removal->pound_name ?: $removal->dispatch?->pound_name,
                'sheet_photo_url' => $removal->sheet_photo_path
                    ? request()->getSchemeAndHttpHost().Storage::url($removal->sheet_photo_path)
                    : null,
                'photos' => $removal->photos->mapWithKeys(fn ($photo) => [$photo->angle => request()->getSchemeAndHttpHost().Storage::url($photo->path)]),
            ])->values() : [],
            'dispatches' => $checkedIn ? $mission->dispatches->map(fn ($dispatch) => [
                'id' => $dispatch->id, 'mission_truck_id' => $dispatch->mission_truck_id,
                'pound_name' => $dispatch->pound_name, 'departed_at' => $dispatch->departed_at?->toIso8601String(),
                'sheet_photo_url' => request()->getSchemeAndHttpHost().Storage::url($dispatch->sheet_photo_path),
            ])->values() : [],
        ];
    }

    private function agentRelations(int $userId): array
    {
        return ['agents' => fn ($query) => $query->where('users.id', $userId), 'vehicles', 'commune', 'trucks', 'removals.photos', 'removals.vehicle', 'removals.dispatch', 'dispatches'];
    }

    private function assertVisibleToAgent(Request $request, Mission $mission): void
    {
        $assigned = $mission->agents()->where('users.id', $request->user()->id)->exists();
        $availableDirect = $mission->type === 'brute' && ! $mission->agents()->exists();
        abort_unless($assigned || $availableDirect, 403, 'Cette mission ne vous est pas affectée.');
    }

    private function assertCheckedIn(Request $request, Mission $mission): void
    {
        $checkedIn = $mission->agents()->where('users.id', $request->user()->id)->wherePivotNotNull('checked_in_at')->exists();
        abort_unless($checkedIn, 403, 'Vous devez pointer avant de commencer les enlèvements.');
    }

    private function storeImage($file, string $directory): string
    {
        $optimized = ImageOptimizer::resize(file_get_contents($file->getRealPath()), 1800, 86);
        $path = $directory.'/'.uniqid('', true).'.'.$optimized['extension'];
        Storage::disk('public')->put($path, $optimized['binary']);
        return $path;
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
