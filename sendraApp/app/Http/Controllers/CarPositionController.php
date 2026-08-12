<?php

namespace App\Http\Controllers;

use App\Http\Requests\ConstationCarPositionRequest;
use App\Http\Requests\StoreCarPositionRequest;
use App\Http\Requests\UpdateCarPositionRequest;
use App\Http\Resources\SignalementRessource;
use App\Models\CarPhoto;
use App\Models\CarPosition;
use Barryvdh\DomPDF\Facade\Pdf;
use Dompdf\Dompdf;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\View;

class CarPositionController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $signalements = CarPosition::where(
            [
                ['is_deleted', false],
                ['etat', 'SIGNALE']
            ]
        )
            ->with('photo')
            ->paginate(5);

        return view('carPosition.signales', compact('signalements'));
    }

    public function index2()
    {
        $signalements = CarPosition::where(
            [
                ['is_deleted', false],
                ['etat', 'ENLEVE']
            ]
        )
            ->with('photo')
            ->paginate(5);
        return view('carPosition.enleves', compact('signalements'));
    }
    public function index3()
    {
        $signalements = CarPosition::where(
            [
                ['is_deleted', false],
                ['etat', 'EN COURS']
            ]
        )
            ->with('photo')
            ->paginate(5);
        return view('carPosition.encours', compact('signalements'));
    }
    /**
     * Show the form for creating a new resource.
     */
    public function maps()
    {
        $signalement = CarPosition::with('photo')->get();
        $initialMarkers = SignalementRessource::collection($signalement);
        return view('carPosition.map', compact('initialMarkers'));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreCarPositionRequest $request)
    {
        $carPosition = new CarPosition();
        $carPosition->latitude = $request->latitude;
        $carPosition->longitude = $request->longitude;
        $carPosition->title = $request->titre;
        $carPosition->commune = $request->commune;
        $carPosition->user_id = Auth::user()->id;

        if ($carPosition->save()) {
            $carPhoto = new CarPhoto();

            $path = $request->file('image')->store('signalement/photo', 'public');

            $carPhoto->card_id =  $carPosition->id;
            $carPhoto->filepath = $path;

            $carPhoto->save();
        }

        return response()->json(['Signalisation effectuée avec success']);
    }

    /**
     * Display the specified resource.
     */
    public function show(CarPosition $carPosition)
    {
        $photo = CarPhoto::where('card_id', $carPosition->id)->first();
        $carPosition = $carPosition->with('user')->first();
        return view('carPosition.show', compact('carPosition', 'photo'));
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(CarPosition $carPosition)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function vehicule(UpdateCarPositionRequest $request, CarPosition $carPosition)
    {
        $carPosition->numero_vehicule = $request->numero_vehicule;
        $carPosition->motif_infraction = $request->motif_infraction;
        $carPosition->marque = $request->marque;
        $carPosition->model = $request->model;
        $carPosition->type_car = $request->type;
        $carPosition->categorie = $request->categorie;
        $carPosition->couleur = $request->couleur;
        $carPosition->entretien = $request->entretien;
        $carPosition->pays_etranger = $request->pays_etranger;
        $carPosition->defaut_controle_technique = $request->has('defaut_controle_technique');
        $carPosition->pneumatiques_manquantes = $request->has('pneumatiques_manquantes');
        $carPosition->vehicule_immerge = $request->has('vehicule_immerge');
        $carPosition->defauts_techniques_irreversibles = $request->has('defauts_techniques_irreversibles');
        $carPosition->vehicule_non_identifiable = $request->has('vehicule_non_identifiable');
        $carPosition->vehicule_brule = $request->has('vehicule_brule');
        $carPosition->chassis_non_reparable = $request->has('chassis_non_reparable');
        $carPosition->agent_id = Auth::user()->id;
        $carPosition->etat = "EN COURS";

        $carPosition->update();
        return redirect()->back()->with('success', 'Les données ont été mises à jour avec succès.');
    }

    public function infraction(Request $request, CarPosition $carPosition)
    {
        $request->validate([
            'adresse_precise' => 'required|string|max:255',
            'motif_infraction' => 'required|string|max:255',
            'lieu' => 'required|in:PUBLIC,PRIVE',
        ]);


        $carPosition->adresse_precise = $request->input('adresse_precise');
        $carPosition->motif_infraction = $request->input('motif_infraction');
        $carPosition->lieu = $request->input('lieu');
        $carPosition->nuit = $request->has('meteo') && in_array('nuit', $request->input('meteo', []));
        $carPosition->pluie = $request->has('meteo') && in_array('pluie', $request->input('meteo', []));

        $carPosition->update();

        return redirect()->back()->with('success', 'Les données ont été mises à jour avec succès.');
    }
    public function enlevement(ConstationCarPositionRequest $request, CarPosition $carPosition)
    {
        $carPosition->motif_enlevement = $request->motif_enlevement;
        $carPosition->date_enlevement = $request->date_enlevement;
        $carPosition->lieu_enlevement = $request->lieu_enlevement;
        $carPosition->nom_responsable_mef = $request->nom_responsable_mef;
        $carPosition->etat = "ENLEVE";
        $carPosition->update();

        return redirect()->back()->with('success', 'Les données ont été mises à jour avec succès.');
    }

    public function approbation(Request $request, CarPosition $carPosition)
    {
        $request->validate([
            'approbation' => 'required',
            'motife_approbation' => 'nullable|string|max:225',
        ]);

        if ($request->approbation == "OUI") {
            $carPosition->is_approve = true;
        } elseif ($request->approbation == "NON") {
            $carPosition->is_approve = false;
        }
        $carPosition->etat = "EN COURS";
        $carPosition->motife_approbation = $request->motife_approbation;

        $carPosition->update();

        return redirect()->back()->with('success', 'Les données ont été mises à jour avec succès.');
    }
    public function locatlisation(CarPosition $carPosition)
    {

        $signalement = CarPosition::where('id', $carPosition->id)->with('photo')->get();
        $initialMarkers = SignalementRessource::collection($signalement);

        return view('carPosition.map', compact('initialMarkers'));
    }


    public function pdf(CarPosition $carPosition)
    {
        $pdf = Pdf::loadView('carPosition.pdf', compact('carPosition'));

        return $pdf->stream("$carPosition->numero_vehicule.pdf");
    }

    public function pdf_constation(CarPosition $carPosition)
    {
        $carPosition = $carPosition->with('agent')->first();
        $pdf = Pdf::loadView('carPosition.pdf.constation', compact('carPosition'));

        return $pdf->stream("$carPosition->numero_vehicule.pdf");
    }
    public function infos()
    {
        $signalements = count(CarPosition::all());
        $signales = count(CarPosition::where('etat', 'SIGNALE')->get());
        $enleves = count(CarPosition::where('etat', 'ENLEVE')->get());
        $encours = count(CarPosition::where('etat', 'EN COURS')->get());
        $signalement = CarPosition::where('is_deleted', false)
            ->with('photo')
            ->orderBy('created_at', 'desc')
            ->take(5)
            ->get();
        return view('welcome', compact('signales', 'signalements', 'enleves', 'encours', 'signalement'));
    }


    public function signatureshow()
    {
        return view('carPosition.pdf.dommage');
    }

    public function signaturestore(Request $request, CarPosition $carPosition)
    {
        $dataUrl = $request->input('signature');

        list($type, $data) = explode(';', $dataUrl);
        list(, $data) = explode(',', $data);

        $imageBinary = base64_decode($data);

        // Générez un nom de fichier unique
        $filename = uniqid('dommages') . '.png';
        // Enregistrez l'image dans le stockage Laravel (dans ce cas, public/storage)
        Storage::disk('public')->put('dommages/' . $filename, $imageBinary);
        $carPosition->dommage_image = $filename;
        $carPosition->update();

        return redirect()->back()->with('success', 'Les données ont été mises à jour avec succès.');
    }
}
