<?php

namespace App\Http\Controllers;

use App\Models\Commune;
use Illuminate\Http\Request;

class CommuneController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $communes = Commune::withCount('missions')->orderBy('nomCommune')->paginate(15);
        return view('communes.index', compact('communes'));
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        return view('communes.form', ['commune' => new Commune()]);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $data = $this->validateData($request);
        $data['user_id'] = $request->user()->id;
        Commune::create($data);
        return redirect()->route('communes.index')->with('success', 'Commune créée.');
    }

    /**
     * Display the specified resource.
     */
    public function show(Commune $commune)
    {
        $commune->loadCount('missions');
        return view('communes.show', compact('commune'));
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Commune $commune)
    {
        return view('communes.form', compact('commune'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Commune $commune)
    {
        $commune->update($this->validateData($request));
        return redirect()->route('communes.show', $commune)->with('success', 'Commune modifiée.');
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Commune $commune)
    {
        if ($commune->missions()->exists()) {
            return back()->with('error', 'Cette commune est utilisée par une mission.');
        }
        $commune->delete();
        return redirect()->route('communes.index')->with('success', 'Commune supprimée.');
    }

    private function validateData(Request $request): array
    {
        $data = $request->validate([
            'nomCommune' => ['required', 'string', 'max:254'],
            'departement' => ['nullable', 'string', 'max:254'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'geofence' => ['required', 'json'],
            'geofence_margin_meters' => ['required', 'integer', 'in:500,1000'],
        ]);
        $data['geofence'] = json_decode($data['geofence'], true, 512, JSON_THROW_ON_ERROR);
        return $data;
    }
}
