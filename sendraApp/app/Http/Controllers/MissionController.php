<?php

namespace App\Http\Controllers;

use App\Models\CarPosition;
use App\Models\Commune;
use App\Models\Mission;
use App\Models\Pound;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class MissionController extends Controller
{
    public function index()
    {
        // L'historique est la vue par défaut (demande de la direction) : on
        // arrive sur les missions déjà clôturées, et « Missions ouvertes »
        // bascule explicitement avec ?historique=0.
        // Historique complet par défaut (missions ouvertes comprises), avec
        // l'état de chaque mission ; filtre ?etat=ouvertes|terminees.
        $etat = in_array(request('etat'), ['ouvertes', 'terminees'], true) ? request('etat') : 'toutes';
        // Compatibilité avec les anciens liens ?historique=0 / 1.
        if (request()->has('historique') && ! request()->has('etat')) {
            $etat = request()->boolean('historique') ? 'terminees' : 'ouvertes';
        }
        $missions = Mission::with(['agents', 'vehicles', 'creator', 'commune', 'trucks', 'receptionAgent', 'removals.reception'])
            ->when($etat === 'ouvertes', fn ($q) => $q->whereNotIn('status', ['terminee', 'annulee']))
            ->when($etat === 'terminees', fn ($q) => $q->whereIn('status', ['terminee', 'annulee']))
            ->orderByDesc('scheduled_at')->orderByDesc('id')->paginate(15);
        $compteurs = [
            'toutes' => Mission::count(),
            'ouvertes' => Mission::whereNotIn('status', ['terminee', 'annulee'])->count(),
            'terminees' => Mission::whereIn('status', ['terminee', 'annulee'])->count(),
        ];
        return view('missions.index', compact('missions', 'etat', 'compteurs'));
    }

    public function create()
    {
        return $this->form(new Mission());
    }

    public function store(Request $request)
    {
        $data = $this->validateData($request);
        $mission = DB::transaction(function () use ($data, $request) {
            $mission = new Mission();
            $this->saveMission($mission, $data, $request->user()->id);
            return $mission;
        });
        return redirect()->route('missions.show', $mission)->with('success', 'Mission créée sous le code '.$mission->code.'.');
    }

    public function show(Mission $mission)
    {
        $mission->load(['commune', 'agents', 'vehicles.photo', 'trucks', 'creator', 'receptionAgent', 'receptionPound', 'removals.photos', 'removals.truck', 'removals.vehicle.photo', 'removals.reception']);
        $readyPounds = collect($mission->pounds ?? [])
            ->push($mission->receptionPound?->name)
            ->filter()
            ->unique()
            ->values();
        $vehicleJourneys = $mission->vehicles->map(fn ($vehicle) => [
            'key' => 'vehicle-'.$vehicle->id,
            'vehicle' => $vehicle,
            'removal' => $mission->removals->firstWhere('car_position_id', $vehicle->id),
        ]);
        $mission->removals
            ->whereNotIn('car_position_id', $mission->vehicles->pluck('id'))
            ->each(fn ($removal) => $vehicleJourneys->push([
                'key' => 'removal-'.$removal->id,
                'vehicle' => $removal->vehicle,
                'removal' => $removal,
            ]));
        return view('missions.show', compact('mission', 'readyPounds', 'vehicleJourneys'));
    }

    public function edit(Mission $mission)
    {
        $mission->load(['agents', 'vehicles', 'trucks']);
        return $this->form($mission);
    }

    public function update(Request $request, Mission $mission)
    {
        $data = $this->validateData($request);
        $hasCheckIn = $mission->agents()->wherePivotNotNull('checked_in_at')->exists();
        if ($hasCheckIn && ($mission->commune_id != ($data['commune_id'] ?? null) || $mission->type !== $data['type'])) {
            return back()->withErrors(['type' => 'Le type et la commune sont verrouillés après le premier pointage.'])->withInput();
        }
        DB::transaction(fn () => $this->saveMission($mission, $data, $request->user()->id));
        return redirect()->route('missions.show', $mission)->with('success', 'Mission modifiée.');
    }

    public function destroy(Mission $mission)
    {
        if ($mission->agents()->wherePivotNotNull('checked_in_at')->exists()) {
            return back()->with('error', 'Cette mission a déjà été pointée et ne peut plus être supprimée.');
        }
        $mission->delete();
        return redirect()->route('missions.index')->with('success', 'Mission supprimée.');
    }

    private function validateData(Request $request): array
    {
        return $request->validate([
            'title' => ['nullable', 'string', 'max:255'],
            'type' => ['required', 'in:programmee,brute'],
            'commune_id' => ['nullable', 'integer', 'exists:communes,id'],
            'provider_name' => ['nullable', 'string', 'max:255'],
            'reception_agent_id' => ['required', 'integer', 'exists:users,id'],
            'reception_pound_id' => ['required', 'integer', 'exists:pounds,id'],
            'scheduled_at' => ['nullable', 'date'],
            'pounds' => ['nullable', 'array'],
            'pounds.*' => ['nullable', 'string', 'max:255'],
            'agents' => ['nullable', 'array'],
            'agents.*' => ['integer', 'exists:users,id'],
            'vehicles' => ['nullable', 'array'],
            'vehicles.*' => ['integer', 'exists:car_positions,id'],
            'trucks' => ['nullable', 'array'],
            'trucks.*.id' => ['nullable', 'integer'],
            'trucks.*.trailer_brand' => ['nullable', 'string', 'max:255'],
            'trucks.*.registration' => ['nullable', 'string', 'max:100'],
            'trucks.*.driver_name' => ['nullable', 'string', 'max:255'],
            'trucks.*.seats' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);
    }

    private function saveMission(Mission $mission, array $data, int $userId): void
    {
        $agents = array_unique($data['agents'] ?? []);
        if ($mission->exists) {
            $checkedInAgents = $mission->agents()->wherePivotNotNull('checked_in_at')->pluck('users.id')->all();
            $agents = array_values(array_unique(array_merge($agents, $checkedInAgents)));
        }
        $vehicles = array_unique($data['vehicles'] ?? []);
        if (User::whereIn('id', $agents)->where('role_id', 2)->count() !== count($agents)) {
            throw ValidationException::withMessages(['agents' => 'La sélection contient un compte qui n’est pas un agent.']);
        }
        if ($data['type'] === 'programmee' && empty($agents)) {
            throw ValidationException::withMessages(['agents' => 'Au moins un agent est obligatoire pour une mission programmée.']);
        }
        if ($data['type'] === 'programmee' && empty($vehicles)) {
            throw ValidationException::withMessages(['vehicles' => 'Au moins un véhicule est obligatoire pour une mission programmée.']);
        }
        if (! empty($data['reception_agent_id']) && ! User::where('id',$data['reception_agent_id'])->where('role_id',2)->exists()) {
            throw ValidationException::withMessages(['reception_agent_id'=>'Le réceptionnaire doit être un agent.']);
        }
        // Un agent est soit sur le terrain, soit à la réception : pas les deux.
        if (! empty($data['reception_agent_id']) && in_array((int) $data['reception_agent_id'], array_map('intval', $agents), true)) {
            throw ValidationException::withMessages(['reception_agent_id' => 'L’agent de réception ne peut pas faire partie de l’équipe terrain.']);
        }
        // Un véhicule ne peut appartenir qu'à une seule mission (non annulée) :
        // déjà programmé, enlevé ou en fourrière, il n'est plus disponible.
        $dejaPris = self::vehiculesPris($mission->exists ? $mission->id : null)
            ->intersect(array_map('intval', $vehicles));
        if ($dejaPris->isNotEmpty()) {
            throw ValidationException::withMessages(['vehicles' => 'Véhicule(s) déjà affecté(s) à une autre mission : n° '.$dejaPris->join(', n° ').'.']);
        }

        $commune = isset($data['commune_id']) ? Commune::find($data['commune_id']) : null;
        $receptionPound = Pound::find($data['reception_pound_id']);
        $readyPounds = collect($data['pounds'] ?? [])
            ->push($receptionPound?->name)
            ->map(fn ($value) => trim((string) $value))
            ->filter()
            ->unique()
            ->values()
            ->all();

        $mission->fill([
            'title' => ($data['title'] ?? null) ?: ($commune ? 'Mission '.$commune->nomCommune : 'Mission ponctuelle'),
            'commune_id' => $commune?->id,
            'type' => $data['type'],
            'status' => $mission->status ?: 'planifiee',
            'provider_name' => $data['provider_name'] ?? null,
            'reception_agent_id' => $data['reception_agent_id'] ?? null,
            'reception_pound_id' => $data['reception_pound_id'] ?? null,
            'scheduled_at' => $data['scheduled_at'] ?? null,
            'address' => $commune?->nomCommune,
            'latitude' => $commune?->latitude,
            'longitude' => $commune?->longitude,
            'check_in_radius_meters' => $commune?->geofence_margin_meters ?? 500,
            'pounds' => $readyPounds,
            'created_by' => $mission->created_by ?: $userId,
        ]);
        $mission->save();
        if (! $mission->code) {
            $ascii = iconv('UTF-8', 'ASCII//TRANSLIT', $commune?->nomCommune ?? 'DIRECTE');
            $prefix = trim(preg_replace('/[^A-Z0-9]+/', '-', strtoupper($ascii)), '-');
            $mission->code = $prefix.'-'.now()->format('Ymd').'-'.str_pad((string) $mission->id, 3, '0', STR_PAD_LEFT);
            $mission->save();
        }
        $mission->agents()->sync($agents);
        $mission->vehicles()->sync($vehicles);
        $keptTruckIds = [];
        foreach ($data['trucks'] ?? [] as $truck) {
            if (collect($truck)->filter(fn ($v) => $v !== null && $v !== '')->isNotEmpty()) {
                $truckId = $truck['id'] ?? null;
                unset($truck['id']);
                $truck['registration'] = strtoupper($truck['registration'] ?? '');
                $model = $truckId ? $mission->trucks()->whereKey($truckId)->first() : null;
                if ($model) { $model->update($truck); } else { $model = $mission->trucks()->create($truck); }
                $keptTruckIds[] = $model->id;
            }
        }
        $mission->trucks()->whereNotIn('id', $keptTruckIds)->whereDoesntHave('removals')->delete();
    }

    /** Identifiants des véhicules déjà affectés à une mission non annulée (hors $sauf). */
    public static function vehiculesPris(?int $sauf = null)
    {
        return DB::table('mission_vehicle')
            ->join('missions', 'missions.id', '=', 'mission_vehicle.mission_id')
            ->where('missions.status', '!=', 'annulee')
            ->when($sauf, fn ($q) => $q->where('mission_vehicle.mission_id', '!=', $sauf))
            ->pluck('mission_vehicle.car_position_id')
            ->map(fn ($id) => (int) $id)
            ->unique()
            ->values();
    }

    private function form(Mission $mission)
    {
        $agents = User::where('role_id', 2)->nonArchives()->orderBy('first_name')->get();
        // Véhicules approuvés encore libres : ceux d'une autre mission (même
        // enlevés ou déjà en fourrière) n'apparaissent plus. Ceux de la
        // mission modifiée restent visibles.
        $vehicles = CarPosition::where('is_deleted', false)
            ->where('is_approve', true)
            ->whereNotIn('etat', ['ENLEVE', 'REJETE'])
            ->whereNotIn('id', self::vehiculesPris($mission->exists ? $mission->id : null))
            ->orderByDesc('created_at')
            ->get();
        $communes = Commune::orderBy('nomCommune')->get();
        $poundOptions = Pound::orderBy('name')->get();
        return view('missions.create', compact('mission', 'agents', 'vehicles', 'communes', 'poundOptions'));
    }
}
