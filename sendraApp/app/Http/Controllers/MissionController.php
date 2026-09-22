<?php

namespace App\Http\Controllers;

use App\Models\CarPosition;
use App\Models\Mission;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MissionController extends Controller
{
    public function index()
    {
        $missions = Mission::with(['agents', 'vehicles', 'creator'])
            ->orderByDesc('scheduled_at')
            ->paginate(15);

        return view('missions.index', compact('missions'));
    }

    public function create()
    {
        $agents = User::where('role_id', 2)->nonArchives()->orderBy('first_name')->get();
        $vehicles = CarPosition::where('is_deleted', false)
            ->whereIn('etat', ['SIGNALE', 'EN COURS'])
            ->orderByDesc('created_at')
            ->get();

        return view('missions.create', compact('agents', 'vehicles'));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'type' => ['required', 'in:programmee,brute'],
            'scheduled_at' => ['required', 'date'],
            'address' => ['required', 'string', 'max:255'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'check_in_radius_meters' => ['required', 'integer', 'between:100,200'],
            'trailer_brand' => ['nullable', 'string', 'max:255'],
            'trailer_plate' => ['nullable', 'string', 'max:100'],
            'pounds' => ['nullable', 'string', 'max:3000'],
            'agents' => ['required', 'array', 'min:1'],
            'agents.*' => ['integer', 'exists:users,id'],
            'vehicles' => ['nullable', 'array'],
            'vehicles.*' => ['integer', 'exists:car_positions,id'],
        ]);

        $validAgentCount = User::whereIn('id', $data['agents'])->where('role_id', 2)->count();
        if ($validAgentCount !== count(array_unique($data['agents']))) {
            return back()->withErrors(['agents' => 'La sélection contient un compte qui n’est pas un agent.'])->withInput();
        }
        if ($data['type'] === 'programmee' && empty($data['vehicles'])) {
            return back()->withErrors(['vehicles' => 'Sélectionnez au moins un véhicule pour une mission programmée.'])->withInput();
        }

        $pounds = collect(preg_split('/\R/', $data['pounds'] ?? ''))
            ->map(fn ($value) => trim($value))->filter()->unique()->values()->all();

        DB::transaction(function () use ($data, $pounds, $request) {
            $mission = Mission::create([
                'title' => $data['title'],
                'type' => $data['type'],
                'status' => 'planifiee',
                'scheduled_at' => $data['scheduled_at'],
                'address' => $data['address'],
                'latitude' => $data['latitude'],
                'longitude' => $data['longitude'],
                'check_in_radius_meters' => $data['check_in_radius_meters'],
                'trailer_brand' => $data['trailer_brand'] ?? null,
                'trailer_plate' => strtoupper($data['trailer_plate'] ?? ''),
                'pounds' => $pounds,
                'created_by' => $request->user()->id,
            ]);
            $mission->agents()->sync(array_unique($data['agents']));
            if ($data['type'] === 'programmee') {
                $mission->vehicles()->sync(array_unique($data['vehicles'] ?? []));
            }
        });

        return redirect()->route('missions.index')->with('success', 'Mission créée et transmise aux agents.');
    }

    public function destroy(Mission $mission)
    {
        if ($mission->agents()->wherePivotNotNull('checked_in_at')->exists()) {
            return back()->with('error', 'Cette mission a déjà été pointée et ne peut plus être supprimée.');
        }
        $mission->delete();

        return back()->with('success', 'Mission supprimée.');
    }
}
