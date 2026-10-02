@extends('layouts.master')
@section('session')
<style>
    .sendra-choice-grid { display:grid; grid-template-columns:repeat(2,minmax(130px,1fr)); gap:12px; max-width:520px; }
    .sendra-choice-input { position:absolute; opacity:0; pointer-events:none; }
    .sendra-choice-card { min-height:76px; border:2px solid #dce5df; border-radius:16px; display:flex; align-items:center; justify-content:center; gap:10px; cursor:pointer; font-weight:700; transition:.18s ease; }
    .sendra-choice-input:checked + .sendra-choice-card { border-color:#198754; box-shadow:0 5px 14px rgba(25,135,84,.2); }
    .sendra-day { background:#62b8ed; color:#fff; }
    .sendra-night { background:#101722; color:#fff; position:relative; overflow:hidden; }
    .sendra-night::before { content:'•  ·  •'; position:absolute; color:#fff; top:5px; right:15px; letter-spacing:5px; }
    .sendra-rain { background:#4a6572; color:#fff; }
    .sendra-color-grid { display:flex; flex-wrap:wrap; gap:9px; }
    .sendra-color-card { width:62px; padding:8px 4px; border:2px solid #dce5df; border-radius:14px; text-align:center; cursor:pointer; background:#fff; }
    .sendra-color-input { position:absolute; opacity:0; pointer-events:none; }
    .sendra-color-input:checked + .sendra-color-card { border-color:#198754; background:#e8f5ed; }
    .sendra-color-dot { width:30px; height:30px; margin:0 auto 5px; border-radius:50%; border:1px solid rgba(0,0,0,.25); display:block; }
    .sendra-damage-wrap { max-width:900px; }
    #signature-canvas { display:block; width:100%; max-width:760px; height:auto; border:1px solid #dce5df; border-radius:14px; touch-action:none; }
    @media(max-width:767px) { .sendra-choice-grid{grid-template-columns:1fr 1fr}.sendra-choice-card{min-height:68px}.sendra-actions{gap:10px}.sendra-actions>div{text-align:left!important} }
</style>
<section class="tab-components">
    <div class="container-fluid">
        <div class="title-wrapper pt-30">
            <div class="row align-items-center">
                <div class="col-md-6">
                    <a class="main-btn success-btn btn-hover mb-4" href="{{route('locatlisation', [$carPosition->id])}}">
                        <i class="lni lni-map-marker"></i> Localisation
                    </a>
                </div>
            </div>
            @if (session('success'))
            <div class="row alert-box success-alert">
                <div class="col-12 alert">
                    <p class="text-medium">{{ session('success') }}</p>
                </div>
            </div>
            @endif
            @if(count($errors) > 0)
            <div class="row alert-box danger-alert">
                <div class="col-12 alert">
                    <p class="text-medium">Une erreur s'est produite !!</p>
                </div>
            </div>
            @endif
        </div>

        <div class="form-elements-wrapper">
            <div class="card-style">
                <div class="card-header">
                    <ul class="nav nav-pills card-header-pills" id="myTab" role="tablist">
                        <li class="nav-item" role="presentation">
                            <a class="nav-link active" id="info-tab" data-bs-toggle="tab" href="#info" role="tab" aria-controls="info" aria-selected="true">Informations de base</a>
                        </li>
                        <li class="nav-item" role="presentation">
                            <a class="nav-link" id="vehicule-tab" data-bs-toggle="tab" href="#vehicule" role="tab" aria-controls="vehicule" aria-selected="false">Vehicule</a>
                        </li>
                        <li class="nav-item" role="presentation">
                            <a class="nav-link" id="infraction-tab" data-bs-toggle="tab" href="#infraction" role="tab" aria-controls="infraction" aria-selected="false">Infraction</a>
                        </li>
                        <li class="nav-item" role="presentation">
                            <a class="nav-link" id="dommages-tab" data-bs-toggle="tab" href="#dommages" role="tab" aria-controls="dommages" aria-selected="false">Dommages</a>
                        </li>
                        <li class="nav-item" role="presentation">
                            <a class="nav-link" id="approval-tab" data-bs-toggle="tab" href="#approval" role="tab" aria-controls="approval" aria-selected="false">Approbation</a>
                        </li>
                        @if($carPosition->is_approve)
                        <li class="nav-item" role="presentation">
                            <a class="nav-link" id="removal-tab" data-bs-toggle="tab" href="#removal" role="tab" aria-controls="removal" aria-selected="false">Enlévement</a>
                        </li>
                        @endif
                    </ul>
                </div>
                <hr>
                <div class="tab-content" id="myTabContent">
                    <!-- Informations de base form -->
                    <div class="tab-pane fade show active" id="info" role="tabpanel" aria-labelledby="info-tab">
                        <div class="card-body">
                            <div class="white_card_body">
                                <div class="box_header ">
                                    <div class="main-title">
                                        <h2 class="m-0 mb-1">Informations de base</h2>
                                    </div>
                                </div>
                                <div class="card-body">
                                    <div class="row justify-content-center align-items-center g-2">
                                        <div class="col-md-6">
                                            <div class="profile_card_5 mb-1">
                                                @php
                                                    $anglesPhotos = [
                                                        'vue_ensemble' => "Vue d'ensemble", 'devant' => 'Devant',
                                                        'derriere' => 'Derrière', 'cote_gauche' => 'Côté gauche', 'cote_droit' => 'Côté droit',
                                                    ];
                                                @endphp
                                                @if ($photos->isEmpty())
                                                    <p class="text-muted text-center my-4">Aucune photo pour ce signalement.</p>
                                                @elseif ($photos->count() === 1)
                                                    <img class="circle-rounded" src="{{ config('services.backend.storage_url') . '/' . $photo->filepath }}" alt="{{ $anglesPhotos[$photo->position] ?? 'Photo du signalement' }}" width="90%" height="90%">
                                                @else
                                                    {{-- Plusieurs photos (une par angle) : carrousel défilant. --}}
                                                    <div id="carrouselPhotos" class="carousel slide" data-bs-ride="false" data-bs-touch="true">
                                                        <div class="carousel-indicators">
                                                            @foreach ($photos as $p)
                                                                <button type="button" data-bs-target="#carrouselPhotos" data-bs-slide-to="{{ $loop->index }}" @class(['active' => $loop->first]) @if ($loop->first) aria-current="true" @endif aria-label="Photo {{ $loop->iteration }}"></button>
                                                            @endforeach
                                                        </div>
                                                        <div class="carousel-inner rounded">
                                                            @foreach ($photos as $p)
                                                                <div @class(['carousel-item', 'active' => $loop->first])>
                                                                    <a href="{{ config('services.backend.storage_url') . '/' . $p->filepath }}" target="_blank" rel="noopener">
                                                                        <img class="d-block w-100" style="max-height: 420px; object-fit: contain; background: #000;" src="{{ config('services.backend.storage_url') . '/' . $p->filepath }}" alt="{{ $anglesPhotos[$p->position] ?? 'Photo ' . $loop->iteration }}">
                                                                    </a>
                                                                    <div class="carousel-caption py-1 px-2 rounded" style="background: rgba(0,0,0,.55); bottom: 2.5rem;">
                                                                        {{ $anglesPhotos[$p->position] ?? 'Photo' }} · {{ $loop->iteration }}/{{ $photos->count() }}
                                                                    </div>
                                                                </div>
                                                            @endforeach
                                                        </div>
                                                        <button class="carousel-control-prev" type="button" data-bs-target="#carrouselPhotos" data-bs-slide="prev">
                                                            <span class="carousel-control-prev-icon" aria-hidden="true"></span>
                                                            <span class="visually-hidden">Précédente</span>
                                                        </button>
                                                        <button class="carousel-control-next" type="button" data-bs-target="#carrouselPhotos" data-bs-slide="next">
                                                            <span class="carousel-control-next-icon" aria-hidden="true"></span>
                                                            <span class="visually-hidden">Suivante</span>
                                                        </button>
                                                    </div>
                                                @endif
                                            </div>
                                        </div>
                                        <div class="col-md-6">
                                            <div class="row mb-3">
                                                <div class="col-md-12">
                                                    <label class="form-label" for="inputEmail4">Titre</label>
                                                    <input type="email" class="form-control" id="inputEmail4" value="{{$carPosition->title}}" readonly>
                                                </div>
                                                <div class=" col-md-6">
                                                    <label class="form-label" for="inputPassword4">Date de Signalement</label>
                                                    <input type="text" class="form-control" id="inputPassword4" value="{{$carPosition->created_at->format('d F Y')}}" readonly>
                                                </div>
                                                <div class=" col-md-6">
                                                    <label class="form-label" for="inputPassword4">heure de Signalement</label>
                                                    <input type="text" class="form-control" id="inputPassword4" value="{{$carPosition->created_at->format('H\hi')}}" readonly>
                                                </div>
                                            </div>
                                            <div class="row mb-3">
                                                <div class="col-md-12">
                                                    <label class="form-label" for="inputEmail4">Nom Auteur</label>
                                                    <input type="email" class="form-control" id="inputEmail4" value="{{$carPosition->user->first_name}}" readonly>
                                                </div>
                                                <div class=" col-md-12">
                                                    <label class="form-label" for="inputPassword4">Prenom Auteur</label>
                                                    <input type="text" class="form-control" id="inputPassword4" value="{{$carPosition->user->last_name}}" readonly>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- infraction form -->
                    <div class="tab-pane fade  " id="infraction" role="tabpanel" aria-labelledby="infraction-tab">
                        <div class="card-body">
                            <div class="white_card_body">
                                <div class="box_header ">
                                    <div class="main-title">
                                        <h2 class="m-0 mb-1">infraction</h2>
                                    </div>
                                </div>
                                <div class="card-body">
                                    <form action="{{ route('infraction', $carPosition->id) }}" method="post">
                                        @method('patch')
                                        @csrf
                                        <div class="table-responsive">
                                            <table class="table top-selling-table">
                                                <tbody>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Addresse precise</h6>
                                                        </td>
                                                        <td>
                                                            <input type="text" class="form-control @error('adresse_precise') is-invalid @enderror" id="inputPassword4" name="adresse_precise" value="{{$carPosition->adresse_precise}}">
                                                            @error('adresse_precise')
                                                            <div class="invalid-feedback">{{ $message }}</div>
                                                            @enderror
                                                        </td>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Motif Infraction</h6>
                                                        </td>
                                                        <td>
                                                            <input type="text" class="form-control @error('motif_infraction') is-invalid @enderror" id="inputPassword4" value="{{ old('motif_infraction', $carPosition->motif_infraction) }}" name="motif_infraction">
                                                            @error('motif_infraction')
                                                            <div class="invalid-feedback">{{ $message }}</div>
                                                            @enderror
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Moment du constat</h6>
                                                        </td>
                                                        <td>
                                                            @php
                                                                $momentDefault = $carPosition->pluie ? 'pluie' : ($carPosition->nuit ? 'nuit' : 'jour');
                                                                $momentValue = old('moment', $momentDefault);
                                                            @endphp
                                                            <div class="sendra-choice-grid" style="grid-template-columns:repeat(3,minmax(100px,1fr))">
                                                                <div>
                                                                    <input class="sendra-choice-input" type="radio" name="moment" id="moment-jour" value="jour" {{ $momentValue === 'jour' ? 'checked' : '' }}>
                                                                    <label class="sendra-choice-card sendra-day" for="moment-jour"><span style="font-size:28px">☀️</span> Jour</label>
                                                                </div>
                                                                <div>
                                                                    <input class="sendra-choice-input" type="radio" name="moment" id="moment-nuit" value="nuit" {{ $momentValue === 'nuit' ? 'checked' : '' }}>
                                                                    <label class="sendra-choice-card sendra-night" for="moment-nuit"><span style="font-size:28px;color:#fff">☾</span> Nuit</label>
                                                                </div>
                                                                <div>
                                                                    <input class="sendra-choice-input" type="radio" name="moment" id="moment-pluie" value="pluie" {{ $momentValue === 'pluie' ? 'checked' : '' }}>
                                                                    <label class="sendra-choice-card sendra-rain" for="moment-pluie"><span style="font-size:28px">🌧️</span> Pluie</label>
                                                                </div>
                                                            </div>
                                                            @error('moment')
                                                            <div class="invalid-feedback">{{ $message }}</div>
                                                            @enderror
                                                        <td>
                                                            <h6 class="text-sm text-medium">Lieu</h6>
                                                        </td>
                                                        <td>
                                                            <div class="d-flex align-items-center">
                                                                <div class="form-check me-3">
                                                                    <input class="form-check-input @error('lieu') is-invalid @enderror" type="radio" name="lieu" id="lieu1" value="PUBLIC" {{ old('lieu', $carPosition->lieu) == 'PUBLIC' ? 'checked' : '' }}>
                                                                    <label class="form-label form-check-label" for="lieu1">🏛️ PUBLIC</label>
                                                                </div>
                                                                <div class="form-check">
                                                                    <input class="form-check-input @error('lieu') is-invalid @enderror" type="radio" name="lieu" id="lieu2" value="PRIVE" {{ old('lieu', $carPosition->lieu) == 'PRIVE' ? 'checked' : '' }}>
                                                                    <label class="form-label form-check-label" for="lieu2">🔒 PRIVÉ</label>
                                                                </div>
                                                            </div>
                                                            @error('lieu')
                                                            <div class="invalid-feedback">{{ $message }}</div>
                                                            @enderror
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td colspan="4">
                                                            <div class="row justify-content-center align-items-center g-2">
                                                                <div class="col-md-6">
                                                                    @if (Auth::user()->role->nomRole != 'Autorite commune' || Auth::user()->role->nomRole != 'Autorite prefecture')
                                                                    <button type="submit mb-3" class="main-btn success-btn-light btn-hover">
                                                                        <i class="lni lni-checkmark"></i> Enregistrer
                                                                    </button>
                                                                    @endif
                                                                </div>
                                                                <div class="col-md-6 text-end">
                                                                    @if($carPosition->etat == "EN COURS")
                                                                    <a href="{{route('pdf_constation', [$carPosition->id])}}" class="main-btn success-btn-light btn-hover " target="_blank">
                                                                        <i class="lni lni-empty-file"></i> Imprimer le PV
                                                                    </a>
                                                                    @endif
                                                                </div>
                                                            </div>
                                                        </td>
                                                    </tr>
                                                </tbody>
                                            </table>
                                        </div>
                                    </form>

                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- vehicule form -->
                    <div class="tab-pane fade  " id="vehicule" role="tabpanel" aria-labelledby="vehicule-tab">
                        <div class="card-body">
                            <div class="white_card_body">
                                <div class="box_header ">
                                    <div class="main-title">
                                        <h2 class="m-0 mb-1">vehicule</h2>
                                    </div>
                                </div>
                                <div class="card-body">
                                    @php
                                        $vehicleBrands = config('vehicle_brands');
                                    @endphp
                                    <div class="mb-4">
                                        <h6 class="text-sm text-medium mb-2">Type de véhicule</h6>
                                        <div class="sendra-choice-grid" style="max-width:340px">
                                            <div>
                                                <input class="sendra-choice-input vehicle-kind-choice" type="radio" name="vehicule_kind_ui" id="kind-voiture" value="voiture" checked>
                                                <label class="sendra-choice-card" for="kind-voiture">🚗 Voiture</label>
                                            </div>
                                            <div>
                                                <input class="sendra-choice-input vehicle-kind-choice" type="radio" name="vehicule_kind_ui" id="kind-moto" value="moto">
                                                <label class="sendra-choice-card" for="kind-moto">🏍️ Moto</label>
                                            </div>
                                        </div>
                                        <p class="text-sm text-muted mt-2 mb-0">Filtre seulement les marques suggérées ci-dessous — pas enregistré séparément.</p>
                                    </div>
                                    <form action="{{route('vehicule', [$carPosition->id])}}" method="post">
                                        @method('patch')
                                        @csrf
                                        <div class="table-responsive">
                                            <table class="table top-selling-table">
                                                <tbody>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Numéro du véhicule</h6>
                                                        </td>
                                                        <td>
                                                            <input type="text" class="form-control @error('numero_vehicule') is-invalid @enderror" id="numero_vehicule" placeholder="AB-0000-KO" pattern="[A-Z]{2}-\d+-[A-Z]{2}" value="{{ old('numero_vehicule', strtoupper($carPosition->numero_vehicule)) }}" name="numero_vehicule" style="text-transform:uppercase">
                                                            @error('numero_vehicule')
                                                            <div class="invalid-feedback">{{ $message }}</div>
                                                            @enderror
                                                        </td>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Marque</h6>
                                                        </td>
                                                        <td>
                                                            <input type="text" class="form-control @error('marque') is-invalid @enderror" id="marque" list="marque-options" value="{{ old('marque', $carPosition->marque) }}" name="marque" placeholder="Choisissez ou saisissez une marque">
                                                            <datalist id="marque-options"></datalist>
                                                            @error('marque')
                                                            <div class="invalid-feedback">{{ $message }}</div>
                                                            @enderror
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Type</h6>
                                                        </td>
                                                        <td>
                                                            <select id="type" class="form-control @error('type') is-invalid @enderror" name="type">
                                                                <option value="" {{ $carPosition->type_car == '' ? 'selected' : '' }}>Sélectionnez le type</option>
                                                                <option value="Berline" {{ $carPosition->type_car == 'Berline' ? 'selected' : '' }}>Berline</option>
                                                                <option value="VUS" {{ $carPosition->type_car == 'VUS' ? 'selected' : '' }}>VUS</option>
                                                                <option value="SUV" {{ $carPosition->type_car == 'SUV' ? 'selected' : '' }}>SUV</option>
                                                                <option value="Hayon" {{ $carPosition->type_car == 'Hayon' ? 'selected' : '' }}>Hayon</option>
                                                                <option value="Camion" {{ $carPosition->type_car == 'Camion' ? 'selected' : '' }}>Camion</option>
                                                                <option value="Electrique" {{ $carPosition->type_car == 'Electrique' ? 'selected' : '' }}>Electrique</option>
                                                            </select>
                                                            @error('type')
                                                            <div class="invalid-feedback">{{ $message }}</div>
                                                            @enderror
                                                        </td>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Modèle</h6>
                                                        </td>
                                                        <td>
                                                            <input type="text" class="form-control @error('model') is-invalid @enderror" id="model" value="{{ old('model', $carPosition->model) }}" name="model">
                                                            @error('model')
                                                            <div class="invalid-feedback">{{ $message }}</div>
                                                            @enderror
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Catégorie de Véhicule</h6>
                                                        </td>
                                                        <td>
                                                            <select id="categorie" class="form-control @error('categorie') is-invalid @enderror" name="categorie">
                                                                <option value="">Choisissez une catégorie</option>
                                                                <option value="VPP" {{ in_array($carPosition->categorie, ['VPP', 'BPP'], true) ? 'selected' : '' }}>VPP</option>
                                                                <option value="VUS" {{ $carPosition->categorie == 'VUS' ? 'selected' : '' }}>VUS</option>
                                                                <option value="VUL" {{ $carPosition->categorie == 'VUL' ? 'selected' : '' }}>VUL</option>
                                                                <option value="VTM" {{ $carPosition->categorie == 'VTM' ? 'selected' : '' }}>VTM</option>
                                                                <option value="CYCL" {{ $carPosition->categorie == 'CYCL' ? 'selected' : '' }}>CYCL</option>
                                                            </select>
                                                            @error('categorie')
                                                            <div class="invalid-feedback">{{ $message }}</div>
                                                            @enderror
                                                        </td>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Couleur</h6>
                                                        </td>
                                                        <td>
                                                            @php
                                                                $vehicleColors = [
                                                                    'Blanc'=>'#f5f5f5','Noir'=>'#202124','Gris'=>'#8b9298','Argent'=>'#c5cbd0',
                                                                    'Rouge'=>'#d93636','Bleu'=>'#2767c5','Vert'=>'#278652','Jaune'=>'#f2c230',
                                                                    'Orange'=>'#e87924','Marron'=>'#795548','Violet'=>'#7e57c2'
                                                                ];
                                                            @endphp
                                                            <div class="sendra-color-grid">
                                                                @foreach($vehicleColors as $colorName => $colorHex)
                                                                    <div>
                                                                        <input class="sendra-color-input" type="radio" name="couleur" id="color-{{ Str::slug($colorName) }}" value="{{ $colorName }}" {{ old('couleur', $carPosition->couleur) === $colorName ? 'checked' : '' }}>
                                                                        <label class="sendra-color-card" for="color-{{ Str::slug($colorName) }}">
                                                                            <span class="sendra-color-dot" style="background:{{ $colorHex }}"></span>
                                                                            <small>{{ $colorName }}</small>
                                                                        </label>
                                                                    </div>
                                                                @endforeach
                                                            </div>
                                                            @error('couleur')
                                                            <div class="invalid-feedback">{{ $message }}</div>
                                                            @enderror
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Etat Général</h6>
                                                        </td>
                                                        <td>
                                                            <div class="d-flex align-items-center align-content-center">
                                                                <div class="form-check me-3">
                                                                    <input class="form-check-input @error('entretien') is-invalid @enderror" type="radio" name="entretien" id="entretien1" value="BON" {{ old('entretien', $carPosition->entretien) == 'BON' ? 'checked' : '' }}>
                                                                    <label class="form-label form-check-label" for="entretien1">✅ BON</label>
                                                                </div>
                                                                <div class="form-check me-3">
                                                                    <input class="form-check-input @error('entretien') is-invalid @enderror" type="radio" name="entretien" id="entretien2" value="MOYEN" {{ old('entretien', $carPosition->entretien) == 'MOYEN' ? 'checked' : '' }}>
                                                                    <label class="form-label form-check-label" for="entretien2">🟠 MOYEN</label>
                                                                </div>
                                                                <div class="form-check">
                                                                    <input class="form-check-input @error('entretien') is-invalid @enderror" type="radio" name="entretien" id="entretien3" value="DEGRADE" {{ old('entretien', $carPosition->entretien) == 'DEGRADE' ? 'checked' : '' }}>
                                                                    <label class="form-label form-check-label" for="entretien3">🛠️ DÉGRADÉ</label>
                                                                </div>
                                                            </div>
                                                            @error('entretien')
                                                            <div class="invalid-feedback">{{ $message }}</div>
                                                            @enderror
                                                        </td>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Pays étranger</h6>
                                                        </td>
                                                        <td>
                                                            <div class="d-flex align-items-center align-content-center">
                                                                <div class="form-check me-3">
                                                                    <input class="form-check-input @error('pays_etranger') is-invalid @enderror" type="radio" name="pays_etranger" id="pays_etranger1" value="OUI" {{ old('pays_etranger', $carPosition->pays_etranger) == 'OUI' ? 'checked' : '' }}>
                                                                    <label class="form-label form-check-label" for="pays_etranger1">🌍 OUI</label>
                                                                </div>
                                                                <div class="form-check">
                                                                    <input class="form-check-input @error('pays_etranger') is-invalid @enderror" type="radio" name="pays_etranger" id="pays_etranger2" value="NON" {{ old('pays_etranger', $carPosition->pays_etranger) == 'NON' ? 'checked' : '' }}>
                                                                    <label class="form-label form-check-label" for="pays_etranger2">🇸🇳 NON</label>
                                                                </div>
                                                            </div>
                                                            @error('pays_etranger')
                                                            <div class="invalid-feedback">{{ $message }}</div>
                                                            @enderror
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Défaut de Contrôle technique</h6>
                                                        </td>
                                                        <td>
                                                            <div class="form-check">
                                                                <input class="form-check-input is-valid @error('defaut_controle_technique') is-invalid @enderror" type="checkbox" name="defaut_controle_technique" id="defaut_controle_technique" {{ $carPosition->defaut_controle_technique ? 'checked' : '' }}>
                                                            </div>
                                                            @error('defaut_controle_technique')
                                                            <div class="invalid-feedback">{{ $message }}</div>
                                                            @enderror
                                                        </td>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Pneumatiques manquantes</h6>
                                                        </td>
                                                        <td>
                                                            <div class="form-check">
                                                                <input class="form-check-input is-valid @error('pneumatiques_manquantes') is-invalid @enderror" type="checkbox" name="pneumatiques_manquantes" id="pneumatiques_manquantes" {{ $carPosition->pneumatiques_manquantes ? 'checked' : '' }}>
                                                            </div>
                                                            @error('pneumatiques_manquantes')
                                                            <div class="invalid-feedback">{{ $message }}</div>
                                                            @enderror
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Véhicule immergé audessus du tableau de bord</h6>
                                                        </td>
                                                        <td>
                                                            <div class="form-check">
                                                                <input class="form-check-input is-valid @error('vehicule_immerge') is-invalid @enderror" type="checkbox" name="vehicule_immerge" id="vehicule_immerge" {{ $carPosition->vehicule_immerge ? 'checked' : '' }}>
                                                            </div>
                                                            @error('vehicule_immerge')
                                                            <div class="invalid-feedback">{{ $message }}</div>
                                                            @enderror
                                                        </td>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Défauts techniques irréversibles et non remplaçables</h6>
                                                        </td>
                                                        <td>
                                                            <div class="form-check">
                                                                <input class="form-check-input is-valid @error('defauts_techniques_irreversibles') is-invalid @enderror" type="checkbox" name="defauts_techniques_irreversibles" id="defauts_techniques_irreversibles" {{ $carPosition->defauts_techniques_irreversibles ? 'checked' : '' }}>
                                                            </div>
                                                            @error('defauts_techniques_irreversibles')
                                                            <div class="invalid-feedback">{{ $message }}</div>
                                                            @enderror
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Véhicule définitivement non identifiable</h6>
                                                        </td>
                                                        <td>
                                                            <div class="form-check">
                                                                <input class="form-check-input is-valid @error('vehicule_non_identifiable') is-invalid @enderror" type="checkbox" name="vehicule_non_identifiable" id="vehicule_non_identifiable" {{ $carPosition->vehicule_non_identifiable ? 'checked' : '' }}>
                                                            </div>
                                                            @error('vehicule_non_identifiable')
                                                            <div class="invalid-feedback">{{ $message }}</div>
                                                            @enderror
                                                        </td>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Véhicule complètement brûlé</h6>
                                                        </td>
                                                        <td>
                                                            <div class="form-check">
                                                                <input class="form-check-input is-valid @error('vehicule_brule') is-invalid @enderror" type="checkbox" name="vehicule_brule" id="vehicule_brule" {{ $carPosition->vehicule_brule ? 'checked' : '' }}>
                                                            </div>
                                                            @error('vehicule_brule')
                                                            <div class="invalid-feedback">{{ $message }}</div>
                                                            @enderror
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Coque ou Chassis ni réparable ni remplaçable</h6>
                                                        </td>
                                                        <td>
                                                            <div class="form-check">
                                                                <input class="form-check-input is-valid @error('chassis_non_reparable') is-invalid @enderror" type="checkbox" name="chassis_non_reparable" id="chassis_non_reparable" {{ $carPosition->chassis_non_reparable ? 'checked' : '' }}>
                                                            </div>
                                                            @error('chassis_non_reparable')
                                                            <div class="invalid-feedback">{{ $message }}</div>
                                                            @enderror
                                                        </td>
                                                        <td></td>
                                                        <td></td>
                                                    </tr>
                                                    <tr>
                                                        <td colspan="4">
                                                            <div class="row justify-content-center align-items-center g-2">
                                                                <div class="col-md-6">
                                                                    @if (Auth::user()->role->nomRole != 'Autorite commune' || Auth::user()->role->nomRole != 'Autorite prefecture')
                                                                    <button type="submit mb-3" class="main-btn success-btn-light btn-hover">
                                                                        <i class="lni lni-checkmark"></i> Enregistrer
                                                                    </button>
                                                                    @endif
                                                                </div>
                                                                <div class="col-md-6 text-end">
                                                                    @if($carPosition->etat == "EN COURS")
                                                                    <a href="{{route('pdf_constation', [$carPosition->id])}}" class="main-btn success-btn-light btn-hover " target="_blank">
                                                                        <i class="lni lni-empty-file"></i> Imprimer le PV
                                                                    </a>
                                                                    @endif
                                                                </div>
                                                            </div>
                                                        </td>
                                                    </tr>
                                                </tbody>
                                            </table>
                                        </div>
                                    </form>
                                    <script>
                                        (function () {
                                            const brands = @json($vehicleBrands);
                                            const marqueInput = document.getElementById('marque');
                                            const marqueList = document.getElementById('marque-options');
                                            const numeroInput = document.getElementById('numero_vehicule');

                                            function fillBrandOptions(kind) {
                                                if (!marqueList) return;
                                                marqueList.innerHTML = '';
                                                (brands[kind] || []).forEach((brand) => {
                                                    const option = document.createElement('option');
                                                    option.value = brand;
                                                    marqueList.appendChild(option);
                                                });
                                            }

                                            document.querySelectorAll('.vehicle-kind-choice').forEach((choice) => {
                                                choice.addEventListener('change', (event) => fillBrandOptions(event.target.value));
                                            });
                                            fillBrandOptions('voiture');

                                            // Plaque : AA-<chiffres>-AA — majuscules et tirets automatiques.
                                            // Le nombre de chiffres n'est pas fixe (0, 00, 000, 0000...) : le
                                            // segment chiffres se termine dès qu'une lettre suit, pas après un
                                            // nombre de caractères donné. Validation stricte à la soumission
                                            // (attribut pattern + contrôle serveur).
                                            if (numeroInput) {
                                                numeroInput.addEventListener('input', () => {
                                                    const raw = numeroInput.value.toUpperCase().replace(/[^A-Z0-9]/g, '');
                                                    const letters1 = [];
                                                    const digits = [];
                                                    const letters2 = [];
                                                    for (const char of raw) {
                                                        const isLetter = /[A-Z]/.test(char);
                                                        const isDigit = /[0-9]/.test(char);
                                                        if (isLetter) {
                                                            if (digits.length === 0 && letters1.length < 2) {
                                                                letters1.push(char);
                                                            } else if (digits.length > 0 && letters2.length < 2) {
                                                                letters2.push(char);
                                                            }
                                                        } else if (isDigit) {
                                                            if (letters1.length === 2 && letters2.length === 0) {
                                                                digits.push(char);
                                                            }
                                                        }
                                                    }
                                                    let formatted = letters1.join('');
                                                    if (letters1.length === 2) formatted += '-' + digits.join('');
                                                    if (letters2.length > 0) formatted += '-' + letters2.join('');
                                                    numeroInput.value = formatted;
                                                });
                                            }
                                        })();
                                    </script>

                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- Enlévement form -->
                    @if($carPosition->is_approve)
                    <div class="tab-pane fade" id="removal" role="tabpanel" aria-labelledby="removal-tab">
                        <div class="card-body">
                            <div class="box_header">
                                <div class="main-title">
                                    <h2 class="m-0 mb-1">Enlévement</h2>
                                </div>
                            </div>
                            <form action="{{route('enlevement', [$carPosition->id])}}" method="post">
                                @method('patch')
                                @csrf
                                <div class="table-responsive">
                                    <table class="table top-selling-table">
                                        <tbody>
                                            <tr>
                                                <td>
                                                    <h6 class="text-sm text-medium">Enlevé par propriétaire</h6>
                                                </td>
                                                <td>
                                                    <div class="d-flex align-items-center">
                                                        <div class="d-flex align-items-center align-content-center">
                                                            <div class="form-check">
                                                                <input class="form-check-input is-valid me-3" type="checkbox" value="oui" {{ $carPosition->oui ? 'checked' : '' }}>
                                                                <label class="form-label form-check-label" for="oui">oui</label>
                                                            </div>
                                                            <div class="form-check">
                                                                <input class="form-check-input is-invalid me-3" type="checkbox" value="non" {{ $carPosition->non ? 'checked' : '' }}>
                                                                <label class="form-label form-check-label" for="non">non</label>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    @error('meteo')
                                                    <div class="invalid-feedback">{{ $message }}</div>
                                                    @enderror
                                                </td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                                <hr class="text-success">
                                <div class="row mb-3">
                                    <div class="col-md-12">
                                        <label class="form-label" for="inputEmail4">Motif enlévement</label>
                                        <textarea class="form-control @error('motif_enlevement') is-invalid @enderror" maxlength="225" rows="3" name="motif_enlevement" id="maxlength-textarea" placeholder="Entrez le motif d'enlévement.">{{$carPosition->motif_enlevement}}</textarea>
                                        @error('motif_enlevement')
                                        <div class="invalid-feedback">{{ $message }}</div>
                                        @enderror
                                    </div>
                                </div>
                                <div class="row mb-2">
                                    <div class="col-md-6">
                                        <label class="form-label" for="inputtest4">Date enlévement</label>
                                        <input type="date" class="form-control @error('date_enlevement') is-invalid @enderror" id="inputtest4" value="{{ !empty($carPosition->date_enlevement) ? date('Y-m-d', strtotime($carPosition->date_enlevement)) : date('Y-m-d') }}" name="date_enlevement">
                                        @error('date_enlevement')
                                        <div class="invalid-feedback">{{ $message }}</div>
                                        @enderror
                                    </div>
                                    <div class="col-md-6">
                                        <label class="form-label" for="inputtest4">Lieu enlévement</label>
                                        <input type="test" class="form-control @error('lieu_enlevement') is-invalid @enderror" id="inputtest4" value="{{$carPosition->lieu_enlevement}}" name="lieu_enlevement">
                                        @error('lieu_enlevement')
                                        <div class="invalid-feedback">{{ $message }}</div>
                                        @enderror
                                    </div>
                                </div>
                                <div class="row mb-3">
                                    <div class="col-md-12">
                                        <label class="form-label" for="inputtest4">Nom Responsable de MEF</label>
                                        <input type="test" class="form-control @error('nom_responsable_mef') is-invalid @enderror" id="inputEmail4" value="{{$carPosition->nom_responsable_mef}}" name="nom_responsable_mef">
                                        @error('nom_responsable_mef')
                                        <div class="invalid-feedback">{{ $message }}</div>
                                        @enderror
                                    </div>
                                </div>
                                <div class="row mb-3">
                                    @if (Auth::user()->role->nomRole != 'Autorite commune' || Auth::user()->role->nomRole != 'Autorite prefecture')
                                    <div class="col-md-6">
                                        <button type="submit mb-3" class="main-btn success-btn-light btn-hover">
                                            <i class="lni lni-checkmark"></i> Fin de Procédure
                                        </button>
                                    </div>
                                    @endif
                                    <div class="col-md-6">
                                        @if($carPosition->etat == "ENLEVE")
                                        <a href="{{route('pdf', [$carPosition->id])}}" class="main-btn success-btn-light btn-hover ">
                                            <i class="lni lni-empty-file"></i> Imprimer le PV
                                        </a>
                                        @endif
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                    @endif
                    <!-- Approbation form -->
                    <div class="tab-pane fade" id="approval" role="tabpanel" aria-labelledby="approval-tab">
                        <div class="card-body">
                            <div class="box_header">
                                <div class="main-title">
                                    <h2 class="m-0">Approbation</h2>
                                </div>
                            </div>
                            <form action="{{route('approbation', [$carPosition->id])}}" method="post">
                                @method('patch')
                                @csrf
                                <div class="row mb-2">
                                    <div class="col-md-12">
                                        <div class="col-form-label col-sm-4">Approuver ?</div>
                                        <div class="col-sm-8">
                                            <div class="form-check">
                                                <input class="form-check-input is-valid" type="radio" name="approbation" id="approbation1" value="OUI" {{ $carPosition->is_approve == true ? 'checked' : '' }}>
                                                <label class="form-label form-check-label" for="approbation1">
                                                    OUI
                                                </label>
                                            </div>
                                            <div class="form-check">
                                                <input class="form-check-input is-invalid" type="radio" name="approbation" id="approbation2" value="NON" {{ $carPosition->is_approve == false ? 'checked' : '' }}>
                                                <label class="form-label form-check-label" for="approbation2">
                                                    NON
                                                </label>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div class="row mb-3">
                                    <div class="col-md-12">
                                        <label class="form-label" for="inputEmail4">Motif d'approbation</label>
                                        <textarea class="form-control @error('motife_approbation') is-invalid @enderror" maxlength="225" rows="3" name="motife_approbation" id="maxlength-textarea" placeholder="Entrez le motif d'approbation">{{$carPosition->motife_approbation}}</textarea>
                                    </div>
                                    @error('motife_approbation')
                                    <div class="invalid-feedback">{{ $message }}</div>
                                    @enderror
                                </div>
                                <div class="row justify-content-center align-items-center g-2">
                                    <div class="col-md-6">
                                        @if (Auth::user()->role->nomRole != 'Agent')
                                        <button type="submit mb-3" class="main-btn success-btn-light btn-hover">
                                            <i class="lni lni-checkmark"></i> Enregistrer
                                        </button>
                                        @endif
                                    </div>
                                    <div class="col-md-6">
                                        @if($carPosition->etat != "SIGNALE")
                                        <a href="{{route('pdf', [$carPosition->id])}}" class="main-btn success-btn-light btn-hover ">
                                            <i class="lni lni-empty-file"></i> Imprimer le PV
                                        </a>
                                        @endif
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                    <!-- Dommages form -->
                    <div class="tab-pane fade" id="dommages" role="tabpanel" aria-labelledby="dommages-tab">
                        <div class="card-body">
                            <form id="signature-form" method="POST" action="{{ route('signature.store', [$carPosition->id]) }}">
                                @csrf
                                <img id="default-image" src="{{ asset('img/constation image.png') }}" style="display: none;">
                                @if($carPosition->dommage_image)
                                {{-- Correction : l'Admin ne voyait jamais les dommages déjà
                                     constatés par l'agent — le canvas repartait toujours du
                                     gabarit vierge, quel que soit l'état réel du signalement. --}}
                                <img id="existing-damage-image" src="{{ config('services.backend.storage_url').'/dommages/'.$carPosition->dommage_image }}" style="display: none;" crossorigin="anonymous">
                                @endif
                                <div class="sendra-damage-wrap">
                                    <h5 class="mb-3">Type de véhicule</h5>
                                    <div class="sendra-choice-grid mb-4">
                                        <div>
                                            <input class="sendra-choice-input damage-vehicle-choice" type="radio" name="damage_vehicle_type" id="damage-car" value="car" checked>
                                            <label class="sendra-choice-card" for="damage-car">🚗 Voiture</label>
                                        </div>
                                        <div>
                                            <input class="sendra-choice-input damage-vehicle-choice" type="radio" name="damage_vehicle_type" id="damage-motorcycle" value="motorcycle">
                                            <label class="sendra-choice-card" for="damage-motorcycle">🏍️ Moto</label>
                                        </div>
                                    </div>
                                    <p class="text-sm mb-2">
                                        Dessinez uniquement sur le véhicule pour indiquer les dommages.
                                        @if($carPosition->dommage_image)
                                        <span class="text-muted">Dommages déjà constatés affichés ci-dessous.</span>
                                        @endif
                                    </p>
                                    <canvas id="signature-canvas" width="760" height="360"></canvas>
                                    @if($carPosition->dommage_image)
                                    <div class="mt-2 d-flex gap-2 flex-wrap">
                                        <button type="button" id="blank-template" class="main-btn btn-hover"><i class="lni lni-reload"></i> Nouveau gabarit vierge</button>
                                        <button type="button" id="restore-agent-version" class="main-btn btn-hover"><i class="lni lni-undo"></i> Revenir à la version de l'agent</button>
                                    </div>
                                    @endif
                                </div>
                                <input type="hidden" name="signature" id="signature">
                                <hr>
                                <div class="row justify-content-center align-items-center g-2 sendra-actions" id="signature-controls">
                                    <div class="col-md-6">
                                        <button type="button" id="clear-signature" class="main-btn danger-btn-light btn-hover"> <i class="lni lni-reload"></i> Effacer</button>
                                    </div>
                                    <div class="col-md-6 text-end">
                                        <button type="submit" id="save-signature" class="main-btn success-btn-light btn-hover "> <i class="lni lni-checkmark"></i> Enregistrer
                                        </button>
                                    </div>
                                </div>
                            </form>
                            <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.3.1/jspdf.umd.min.js"></script>
                            <script src="{{ asset('assets/js/signature.js') }}?v={{ filemtime(public_path('assets/js/signature.js')) }}"></script>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>
@endsection
