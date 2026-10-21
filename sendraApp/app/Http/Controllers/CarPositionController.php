<?php

namespace App\Http\Controllers;

use App\Http\Requests\ConstationCarPositionRequest;
use App\Http\Requests\StoreCarPositionRequest;
use App\Http\Requests\UpdateCarPositionRequest;
use App\Http\Resources\SignalementRessource;
use App\Models\CarPhoto;
use App\Models\CarPosition;
use App\Support\HistoriqueSignalement;
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
        // Correction perf : aucun ORDER BY n'était précisé — MySQL renvoyait
        // les lignes dans un ordre non garanti (en pratique l'ordre naturel
        // du PK, donc du plus ancien au plus récent). Tri explicite sur
        // created_at (indexé, voir migration add_perf_indexes) pour un
        // résultat déterministe et conserver le comportement observé.
        $signalements = CarPosition::where(
            [
                ['is_deleted', false],
                ['etat', 'SIGNALE']
            ]
        )
            ->whereNull('non_removed_at')
            ->with('photo')
            ->orderBy('created_at')
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
            ->orderBy('created_at')
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
            ->whereNull('non_removed_at')
            ->with('photo')
            ->orderBy('created_at')
            ->paginate(5);
        return view('carPosition.encours', compact('signalements'));
    }

    public function nonResolus()
    {
        $signalements = CarPosition::where('is_deleted', false)
            ->whereIn('etat', ['SIGNALE', 'EN COURS'])
            ->whereNotNull('non_removed_at')
            ->with('photo')
            ->orderByDesc('non_removed_at')
            ->paginate(10);
        return view('carPosition.non_resolus', compact('signalements'));
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
        // Toutes les photos du signalement (une par angle depuis l'app avec
        // mode hors ligne), vue d'ensemble d'abord.
        $allPhotos = CarPhoto::where('card_id', $carPosition->id)->orderBy('id')->get();
        $photos = $allPhotos->where('position', '!=', 'agent_constat')->values();
        $agentPhotos = $allPhotos->where('position', 'agent_constat')->values();
        $photo = $photos->first();
        // Le binding de route fournit déjà le bon signalement. Appeler
        // first() sur une nouvelle requête repartait de toute la table et
        // affichait systématiquement le signalement n° 1 avec la photo du
        // signalement demandé.
        $carPosition->load(['user', 'agent']);
        return view('carPosition.show', compact('carPosition', 'photo', 'photos', 'agentPhotos'));
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
        abort_if((int) Auth::user()->role_id === 2 && !empty($carPosition->dommage_image), 403, 'Signalement transmis : modification interdite.');
        $carPosition->numero_vehicule = strtoupper($request->numero_vehicule);
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
        abort_if((int) Auth::user()->role_id === 2 && !empty($carPosition->dommage_image), 403, 'Signalement transmis : modification interdite.');
        $request->validate([
            'adresse_precise' => 'required|string|max:255',
            'motif_infraction' => 'required|string|max:255',
            'lieu' => 'required|in:PUBLIC,PRIVE',
            'moment' => 'required|in:jour,nuit,pluie',
        ]);


        $carPosition->adresse_precise = $request->input('adresse_precise');
        $carPosition->motif_infraction = $request->input('motif_infraction');
        $carPosition->lieu = $request->input('lieu');
        $carPosition->nuit = $request->input('moment') === 'nuit';
        $carPosition->pluie = $request->input('moment') === 'pluie';

        $carPosition->update();

        return redirect()->back()->with('success', 'Les données ont été mises à jour avec succès.');
    }
    public function enlevement(ConstationCarPositionRequest $request, CarPosition $carPosition)
    {
        // Correction API-M-2 (même bug dupliqué côté back-office) :
        // l'onglet est masqué côté vue tant que non approuvé, mais rien ne
        // l'empêchait côté serveur en appelant directement la route.
        if (!$carPosition->is_approve) {
            return redirect()->back()->withErrors(['approbation' => 'Ce signalement n\'a pas été approuvé, l\'enlèvement ne peut pas être enregistré.']);
        }

        $carPosition->motif_enlevement = $request->motif_enlevement;
        $carPosition->date_enlevement = $request->date_enlevement;
        $carPosition->lieu_enlevement = $request->lieu_enlevement;
        $carPosition->nom_responsable_mef = $request->nom_responsable_mef;
        $carPosition->etat = "ENLEVE";
        $carPosition->non_removal_reason = null;
        $carPosition->non_removed_at = null;
        $carPosition->update();

        HistoriqueSignalement::enregistrer($carPosition, 'enleve', $request->motif_enlevement);

        return redirect()->back()->with('success', 'Les données ont été mises à jour avec succès.');
    }

    public function approbations(Request $request)
    {
        $filtre = $request->query('filtre', 'attente');
        $recherche = trim((string) $request->query('q', ''));
        abort_unless(in_array($filtre, ['attente', 'approuves', 'refuses'], true), 404);
        $query = CarPosition::query()->where('is_deleted', false)
            ->whereNotNull('dommage_image')->with(['user', 'agent', 'photo']);
        if ($filtre === 'attente') {
            $query->where('is_approve', false)->where('etat', '!=', 'REJETE');
        } elseif ($filtre === 'approuves') {
            $query->where('is_approve', true);
        } else {
            $query->where('etat', 'REJETE');
        }
        if ($recherche !== '') {
            $query->where(function ($q) use ($recherche) {
                if (ctype_digit($recherche)) $q->orWhere('id', (int) $recherche);
                $q->orWhere('commune', 'like', '%'.$recherche.'%')
                  ->orWhere('numero_vehicule', 'like', '%'.$recherche.'%');
            });
        }
        $signalements = $query->orderByDesc('updated_at')->paginate(30)->withQueryString();
        $enAttente = CarPosition::where('is_deleted', false)->whereNotNull('dommage_image')
            ->where('is_approve', false)->where('etat', '!=', 'REJETE')->count();
        return view('carPosition.approbations', compact('signalements', 'filtre', 'enAttente', 'recherche'));
    }

    public function approbation(Request $request, CarPosition $carPosition)
    {
        $request->validate([
            'approbation' => 'required|in:OUI,NON',
            'motife_approbation' => 'required_if:approbation,NON|nullable|string|max:225',
        ]);

        abort_if(empty($carPosition->dommage_image), 422, 'Constatation non transmise.');
        abort_if($carPosition->is_approve || $carPosition->etat === 'REJETE', 409, 'Décision déjà enregistrée.');

        // Correction API-M-1 (même bug dupliqué côté back-office) : l'état
        // était forcé à "EN COURS" même en cas de refus.
        if ($request->approbation == "OUI") {
            $carPosition->is_approve = true;
            $carPosition->etat = "EN COURS";
        } elseif ($request->approbation == "NON") {
            $carPosition->is_approve = false;
            $carPosition->etat = "REJETE";
        }
        $carPosition->motife_approbation = $request->motife_approbation;

        $carPosition->update();

        HistoriqueSignalement::enregistrer(
            $carPosition,
            $request->approbation == 'OUI' ? 'approuve' : 'rejete',
            $request->motife_approbation
        );

        return redirect()->route('approbations.index')->with('success', 'Décision enregistrée.');
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
        $carPosition->load(['agent', 'photo']);
        $pdf = Pdf::loadView('carPosition.pdf.constation', compact('carPosition'));

        return $pdf->stream("$carPosition->numero_vehicule.pdf");
    }
    public function infos()
    {
        // Correction perf (même anti-pattern qu'API-M-3 dans l'API mobile) :
        // count(->get()) hydrate toute la table en modèles Eloquent rien que
        // pour la compter en PHP. ->count() fait l'agrégation en SQL, sans
        // rapatrier ni instancier la moindre ligne.
        $signalements = CarPosition::count();
        $signales = CarPosition::where('etat', 'SIGNALE')->whereNull('non_removed_at')->count();
        $enleves = CarPosition::where('etat', 'ENLEVE')->count();
        $encours = CarPosition::where('etat', 'EN COURS')->whereNull('non_removed_at')->count();
        $nonResolus = CarPosition::whereIn('etat', ['SIGNALE', 'EN COURS'])->whereNotNull('non_removed_at')->count();
        $approbationsEnAttente = CarPosition::where('is_deleted', false)
            ->whereNotNull('dommage_image')->where('is_approve', false)
            ->where('etat', '!=', 'REJETE')->count();
        $signalement = CarPosition::where('is_deleted', false)
            ->with('photo')
            ->orderBy('created_at', 'desc')
            ->take(5)
            ->get();
        return view('welcome', compact('signales', 'signalements', 'enleves', 'encours', 'nonResolus', 'signalement', 'approbationsEnAttente'));
    }


    public function signaturestore(Request $request, CarPosition $carPosition)
    {
        abort_if((int) Auth::user()->role_id === 2 && !empty($carPosition->dommage_image), 403, 'Signalement transmis : modification interdite.');
        // Correction WEB-M-4 : aucune validation de format/taille avant —
        // un payload malformé faisait planter explode(), un payload énorme
        // pouvait remplir le stockage sans limite.
        $request->validate([
            'signature' => ['required', 'string', 'max:2097152', 'regex:/^data:image\/(png|jpeg);base64,/'],
        ]);

        $dataUrl = $request->input('signature');

        list($type, $data) = explode(';', $dataUrl, 2);
        list(, $data) = explode(',', $data, 2);

        $imageBinary = base64_decode($data, true);

        if ($imageBinary === false || @getimagesizefromstring($imageBinary) === false) {
            return redirect()->back()->withErrors(['signature' => 'La signature fournie n\'est pas une image valide.']);
        }

        // Générez un nom de fichier unique
        $filename = uniqid('dommages') . '.png';
        // 11/09/2026 : écrite dans le stockage du backend, là où la fiche et
        // l'application mobile la lisent (disque `backend`, config/filesystems.php).
        // Sur le disque `public` de sendraApp, elle n'était visible nulle part.
        // Écriture vérifiée : une signature non écrite ne doit pas laisser en
        // base une référence vers un fichier qui n'existe pas.
        if (! Storage::disk('backend')->put('dommages/' . $filename, $imageBinary)) {
            return redirect()->back()->withErrors(['signature' => 'La signature n\'a pas pu être enregistrée. Réessayez ou prévenez l\'administrateur.']);
        }
        $carPosition->dommage_image = $filename;
        $carPosition->update();

        return redirect()->back()->with('success', 'Les données ont été mises à jour avec succès.');
    }
}
