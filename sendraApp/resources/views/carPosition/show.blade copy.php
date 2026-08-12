@extends('layouts.master')
@section('session')
<section class="tab-components">
    <div class="container-fluid">
        <div class="title-wrapper pt-30">
            <div class="row align-items-center">
                <div class="col-md-6">
                    <a class="main-btn success-btn btn-hover mb-4" href="{{route('locatlisation', [$carPosition->id])}}">
                        <i class="lni lni-map-marker"></i>
                        Localisation</a>
                </div>
            </div>
            @if (session('success'))
            <div class="row alert-box success-alert">
                <div class="col-12 alert">
                    <p class="text-medium">
                        {{ session('success') }}
                    </p>
                </div>
            </div>
            @endif
            @if(count($errors) >0)
            <div class="row alert-box danger-alert">
                <div class="col-12 alert">
                    <p class="text-medium">
                        Une erreur s'est produite !!
                    </p>
                </div>
            </div>
            @endif
            <!-- end row -->
        </div>
        <div class="form-elements-wrapper">
            <div class="row">
                <div class="col-lg-12">
                    <!-- input style start -->
                    <div class="card-style mb-30">
                        <div class="white_card_body">
                            <div class="box_header ">
                                <div class="main-title">
                                    <h2 class="m-0 mb-1">Informations de base</h2>
                                </div>
                            </div>
                            <div class="card-body">
                                <div class="profile_card_5 mb-1">
                                    <img class="circle-rounded" src="{{asset('https://backend.sendra.sn/storage/'. $photo->filepath)}}" alt="" width="100%" height="100%">
                                </div>
                                <form action="{{route('constataion', [$carPosition->id])}}" method="post">
                                    @method('patch')
                                    @csrf
                                    <div class="row mb-3">
                                        <div class="col-md-6">
                                            <label class="form-label" for="inputEmail4">Titre</label>
                                            <input type="email" class="form-control" id="inputEmail4" value="{{$carPosition->title}}" readonly>
                                        </div>
                                        <div class=" col-md-6">
                                            <label class="form-label" for="inputPassword4">Date de Signalement</label>
                                            <input type="text" class="form-control" id="inputPassword4" value="{{$carPosition->created_at->format('d F Y \à H\hi')}}" readonly>
                                        </div>
                                    </div>
                                    <div class="row mb-3">
                                        <div class="col-md-6">
                                            <label class="form-label" for="inputEmail4">Marque</label>
                                            <select id="inputState" class="form-control @error('marque') is-invalid @enderror" name="marque">
                                                <option value="" {{ $carPosition->marque == '' ? 'selected' : '' }}>Sélectionnez une marque</option>
                                                <option value="Toyota" {{ $carPosition->marque == 'Toyota' ? 'selected' : '' }}>Toyota</option>
                                                <option value="Ford" {{ $carPosition->marque == 'Ford' ? 'selected' : '' }}>Ford</option>
                                                <option value="Honda" {{ $carPosition->marque == 'Honda' ? 'selected' : '' }}>Honda</option>
                                                <option value="Chevrolet" {{ $carPosition->marque == 'Chevrolet' ? 'selected' : '' }}>Chevrolet</option>
                                                <option value="Nissan" {{ $carPosition->marque == 'Nissan' ? 'selected' : '' }}>Nissan</option>
                                                <option value="BMW" {{ $carPosition->marque == 'BMW' ? 'selected' : '' }}>BMW</option>
                                                <option value="Mercedes-Benz" {{ $carPosition->marque == 'Mercedes-Benz' ? 'selected' : '' }}>Mercedes-Benz</option>
                                                <option value="Audi" {{ $carPosition->marque == 'Audi' ? 'selected' : '' }}>Audi</option>
                                                <option value="Volkswagen" {{ $carPosition->marque == 'Volkswagen' ? 'selected' : '' }}>Volkswagen</option>
                                                <option value="Hyundai" {{ $carPosition->marque == 'Hyundai' ? 'selected' : '' }}>Hyundai</option>
                                                <option value="Kia" {{ $carPosition->marque == 'Kia' ? 'selected' : '' }}>Kia</option>
                                                <option value="Mazda" {{ $carPosition->marque == 'Mazda' ? 'selected' : '' }}>Mazda</option>
                                                <option value="Peugeot" {{ $carPosition->marque == 'Peugeot' ? 'selected' : '' }}>Peugeot</option>
                                                <option value="Renault" {{ $carPosition->marque == 'Renault' ? 'selected' : '' }}>Renault</option>
                                            </select>
                                            @error('marque')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                            @enderror
                                        </div>
                                        <div class="col-md-6">
                                            <label class="form-label" for="inputPassword4">Modéle</label>
                                            <input type="text" class="form-control @error('model') is-invalid @enderror" id="inputPassword4" value="{{ old('model', $carPosition->model) }}" name="model">
                                            @error('model')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                            @enderror
                                        </div>
                                    </div>
                                    <div class="row mb-3">
                                        <div class="col-md-6">
                                            <label class="form-label" for="inputEmail4">Type</label>
                                            <select id="inputState" class="form-control @error('type') is-invalid @enderror" name="type">
                                                <option value="" {{ $carPosition->type_car == '' ? 'selected' : '' }}>Sélectionnez le type</option>
                                                <option value="Berline" {{ $carPosition->type_car == 'Berline' ? 'selected' : '' }}>Berline</option>
                                                <option value="VUS" {{ $carPosition->type_car == 'VUS' ? 'selected' : '' }}>VUS</option>
                                                <option value="hayon" {{ $carPosition->type_car == 'hayon' ? 'selected' : '' }}>hayon</option>
                                                <option value="Camion" {{ $carPosition->type_car == 'Camion' ? 'selected' : '' }}>Camion</option>
                                                <option value="Electrique" {{ $carPosition->type_car == 'Electrique' ? 'selected' : '' }}>Electrique</option>
                                            </select>
                                            @error('type')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                            @enderror
                                        </div>
                                        <div class="col-md-6">
                                            <label class="form-label" for="inputPassword4">Secteur</label>
                                            <input type="text" class="form-control @error('secteur') is-invalid @enderror" id="inputPassword4" name="secteur" value="{{ old('secteur', $carPosition->commune) }}" readonly>
                                            @error('secteur')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                            @enderror
                                        </div>

                                    </div>
                                    <div class="row mb-3">
                                        <div class="col-md-6">
                                            <label class="form-label" for="inputPassword4">Catégorie de Véhicule</label>
                                            <select id="inputState" class="form-control @error('categorie') is-invalid @enderror" name="categorie">
                                                <option value="">Choisissez une catégorie</option>
                                                <option value="BPP" {{ $carPosition->categorie == 'BPP' ? 'selected' : '' }}>BPP</option>
                                                <option value="VUS" {{ $carPosition->categorie == 'VUS' ? 'selected' : '' }}>VUS</option>
                                                <option value="VUL" {{ $carPosition->categorie == 'VUL' ? 'selected' : '' }}>VUL</option>
                                                <option value="VTM" {{ $carPosition->categorie == 'VTM' ? 'selected' : '' }}>VTM</option>
                                                <option value="CYCL" {{ $carPosition->categorie == 'CYCL' ? 'selected' : '' }}>CYCL</option>
                                            </select>
                                            @error('categorie')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                            @enderror
                                        </div>
                                        <div class=" col-md-6">
                                            <label class="form-label" for="inputEmail4">Couleur</label>
                                            <input type="text" class="form-control @error('couleur') is-invalid @enderror" id="inputPassword4" name="couleur" value="{{$carPosition->couleur}}">
                                            @error('couleur')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                            @enderror
                                        </div>
                                    </div>
                                    <div class="mb-3">
                                        <div class="row">
                                            <div class="col-md-6">
                                                <div class="col-form-label col-sm-4 pt-0">Entretien</div>
                                                <div class="col-sm-8">
                                                    <div class="form-check">
                                                        <input class="form-check-input @error('entretien') is-invalid @enderror" type="radio" name="entretien" id="entretien1" value="BON" {{ old('entretien', $carPosition->entretien) == 'BON' ? 'checked' : '' }}>
                                                        <label class="form-label form-check-label" for="entretien1">BON</label>
                                                    </div>
                                                    <div class="form-check">
                                                        <input class="form-check-input @error('entretien') is-invalid @enderror" type="radio" name="entretien" id="entretien2" value="MOYEN" {{ old('entretien', $carPosition->entretien) == 'MOYEN' ? 'checked' : '' }}>
                                                        <label class="form-label form-check-label" for="entretien2">MOYEN</label>
                                                    </div>
                                                    <div class="form-check">
                                                        <input class="form-check-input @error('entretien') is-invalid @enderror" type="radio" name="entretien" id="entretien3" value="DEGRADE" {{ old('entretien', $carPosition->entretien) == 'DEGRADE' ? 'checked' : '' }}>
                                                        <label class="form-label form-check-label" for="entretien3">DEGRADE</label>
                                                    </div>
                                                </div>
                                                @error('entretien')
                                                <div class="invalid-feedback">{{ $message }}</div>
                                                @enderror
                                            </div>
                                        </div>

                                    </div>
                                    @if (Auth::user()->role->nomRole != 'Autorite commune' || Auth::user()->role->nomRole != 'Autorite prefecture')
                                    <button type="submit mb-3" class="main-btn success-btn-light btn-hover">
                                        <i class="lni lni-checkmark"></i>
                                        Enregistrer
                                    </button>
                                    @endif
                                </form>
                            </div>

                        </div>
                    </div>
                </div>
                <!-- end col -->
                <div class="col-lg-6">
                    <!-- ======= textarea style start ======= -->
                    <div class="card-style mb-30">
                        <div class="box_header ">
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
                            @if (Auth::user()->role->nomRole != 'Agent')
                            <button type="submit mb-3" class="main-btn success-btn-light btn-hover">
                                <i class="lni lni-checkmark"></i>
                                Enregistrer
                            </button>
                            @endif
                        </form>
                    </div>
                </div>
                @if($carPosition->is_approve)
                <div class="col-md-6">
                    <div class="card-style mb-30">
                        <div class="box_header ">
                            <div class="main-title">
                                <h2 class="m-0 mb-1">Enlévement</h2>
                            </div>
                        </div>
                        <form action="{{route('enlevement', [$carPosition->id])}}" method="post">
                            @method('patch')
                            @csrf
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
                                        <i class="lni lni-checkmark"></i>
                                        Enregistrer
                                    </button>
                                </div>
                                @endif
                                <div class="col-md-6">
                                    @if($carPosition->etat == "ENLEVE")
                                    <a href="{{route('pdf', [$carPosition->id])}}" class="main-btn success-btn-light btn-hover ">
                                        <i class="lni lni-empty-file"></i>
                                        Imprimer le PV</a>
                                    @endif
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
                @endif
                <!-- end col -->
            </div>
            <!-- end row -->
        </div>
        <!-- ========== form-elements-wrapper end ========== -->
    </div>
    <!-- end container -->
</section>

@endsection