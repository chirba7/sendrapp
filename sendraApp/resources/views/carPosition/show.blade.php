@extends('layouts.master')
@section('session')
@php
    $storageBase = rtrim(config('services.backend.storage_url'), '/');
    $vehicleKind = $carPosition->vehicle_kind ?: (($carPosition->type_car === 'Moto' || $carPosition->categorie === 'CYCL') ? 'Moto' : 'Voiture');
    // Cinq états, les mêmes que dans les applications : Signalé, En cours,
    // Résolu, Non résolu, Rejeté.
    // Une fois la constatation saisie : marque, modèle et plaque à côté du titre.
    $vehiculeConstate = collect([trim(($carPosition->marque ?? '').' '.($carPosition->model ?? '')), $carPosition->numero_vehicule])->filter()->join(' · ');
    $statusLabel = \App\Support\AvancementSignalement::LIBELLES[\App\Support\AvancementSignalement::etatAffiche($carPosition)] ?? 'Signalé';
@endphp
<style>
    .report-hero { background:linear-gradient(135deg,#073b2a,#0b8f55); color:#fff; border-radius:22px; padding:24px; box-shadow:0 16px 38px rgba(7,59,42,.18); }
    .report-hero .meta { color:rgba(255,255,255,.8); }
    .report-stat { height:100%; border:1px solid #e7eee9; border-radius:18px; padding:18px; background:#fff; }
    .report-detail { border:1px solid #e1eae5; border-radius:18px; background:#fff; padding:20px; height:100%; }
    .report-detail dt { color:#66736c; font-size:13px; margin-top:12px; }
    .report-detail dd { font-weight:600; margin-bottom:0; overflow-wrap:anywhere; }
    .report-agent-photo { width:100%; height:190px; object-fit:cover; border-radius:12px; }
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
    .decision-choix { display:grid; grid-template-columns:repeat(2,minmax(140px,1fr)); gap:12px; max-width:520px; }
    .decision-choix input { position:absolute; opacity:0; pointer-events:none; }
    .decision-choix span { display:flex; align-items:center; justify-content:center; gap:8px; min-height:64px; border:2px solid #dce5df; border-radius:16px; font-weight:700; font-size:16px; cursor:pointer; transition:.15s; }
    .decision-choix input:checked + span.ok { border-color:#188038; background:#e8f5ed; color:#0b6b30; }
    .decision-choix input:checked + span.refus { border-color:#d93025; background:#fdecea; color:#b3261e; }
    .decision-choix input:focus-visible + span { outline:2px solid #0b8f55; outline-offset:2px; }
    .decision-resultat { border-radius:14px; padding:14px 16px; }
    .decision-resultat.ok { background:#e8f5ed; color:#0b6b30; }
    .decision-resultat.refus { background:#fdecea; color:#b3261e; }
    @media(max-width:767px) { .sendra-choice-grid{grid-template-columns:1fr 1fr}.sendra-choice-card{min-height:68px}.sendra-actions{gap:10px}.sendra-actions>div{text-align:left!important} }
</style>
<section class="tab-components">
    <div class="container-fluid">
        <div class="title-wrapper pt-30">
            <div class="row align-items-center">
                <div class="col-12 d-flex flex-wrap gap-2 mb-4">
                    @if(request('depuis') === 'approbations')
                        <a class="btn btn-outline-secondary" href="{{ route('approbations.index', array_filter(['filtre' => request('filtre'), 'q' => request('q')])) }}">
                            <i class="lni lni-arrow-left"></i> Retour aux approbations
                        </a>
                    @endif
                    <a class="main-btn success-btn btn-hover" href="{{route('locatlisation', [$carPosition->id])}}">
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

        <div class="report-hero mb-4">
            <div class="row align-items-center g-3">
                <div class="col-lg-8">
                    <span class="badge bg-light text-dark mb-2">{{ $statusLabel }}</span>
                    <h2 class="text-white mb-1">Signalement n° {{ $carPosition->id }}
                        @if($vehiculeConstate)<span class="fs-5 fw-semibold ms-1" style="color:rgba(255,255,255,.88)">· {{ $vehiculeConstate }}</span>@endif
                    </h2>
                    <div class="meta">{{ $carPosition->title ?: 'Véhicule signalé' }} · {{ $carPosition->created_at?->format('d/m/Y à H:i') }}</div>
                </div>
                <div class="col-lg-4 text-lg-end">
                    <div class="fs-5 fw-semibold">{{ $vehicleKind }} · {{ $carPosition->marque ?: 'Marque non renseignée' }}</div>
                    <div class="meta">{{ $carPosition->numero_vehicule ?: 'Plaque non renseignée' }}</div>
                </div>
            </div>
        </div>
        @if(in_array($carPosition->etat, ['SIGNALE', 'EN COURS']) && $carPosition->non_removed_at)
            <div class="alert alert-warning"><strong>Véhicule non enlevé</strong> · {{ $carPosition->non_removal_reason }}<br><small>Constaté le {{ $carPosition->non_removed_at?->format('d/m/Y à H:i') }}</small></div>
        @endif
        <div class="row g-3 mb-4">
            <div class="col-md-4"><div class="report-stat"><div class="text-muted small">Citoyen</div><div class="fw-bold">{{ trim(($carPosition->user?->first_name ?? '').' '.($carPosition->user?->last_name ?? '')) ?: 'Non renseigné' }}</div><small>{{ $carPosition->user?->telephone ?: 'Téléphone non renseigné' }}</small></div></div>
            <div class="col-md-4"><div class="report-stat"><div class="text-muted small">Agent</div><div class="fw-bold">{{ trim(($carPosition->agent?->first_name ?? '').' '.($carPosition->agent?->last_name ?? '')) ?: 'Non pris en charge' }}</div><small>{{ $carPosition->dommage_image ? 'Constatation transmise' : ($carPosition->pris_en_charge_at ? 'Pris en charge le '.\Carbon\Carbon::parse($carPosition->pris_en_charge_at)->format('d/m/Y à H:i') : 'Constatation en attente') }}{{ $carPosition->pv_signe_at ? ' · PV signé' : '' }}</small></div></div>
            <div class="col-md-4"><div class="report-stat"><div class="text-muted small">Décision</div><div class="fw-bold">{{ $carPosition->etat === 'REJETE' ? 'Refusée' : ($carPosition->is_approve ? 'Approuvée' : 'En attente') }}</div><small>{{ $carPosition->motife_approbation ?: 'Aucun motif renseigné' }}</small></div></div>
        </div>
        <div class="row g-3 mb-4">
            <div class="col-12"><div class="report-detail">
                <h4 class="mb-3">Avancement du signalement</h4>
                @include('carPosition.partials.avancement')
            </div></div>
        </div>
        <div class="row g-3 mb-4">
            <div class="col-lg-6"><div class="report-detail">
                <h4>Informations du signalement</h4>
                <dl class="mb-0">
                    <dt>Description du citoyen</dt><dd>{{ $carPosition->description ?: '—' }}</dd>
                    <dt>Ville / commune / quartier</dt><dd>{{ collect([$carPosition->commune, $carPosition->adresse_precise])->filter()->unique()->join(' · ') ?: 'Adresse non renseignée' }}</dd>
                    <dt>Position GPS</dt><dd>@if($carPosition->latitude && $carPosition->longitude)<a href="https://www.google.com/maps/search/?api=1&query={{ $carPosition->latitude }},{{ $carPosition->longitude }}" target="_blank" rel="noopener">Voir sur la carte</a>@else Non disponible @endif</dd>
                    <dt>Véhicule</dt><dd>{{ $vehicleKind }} · {{ $carPosition->type_car ?: 'Type non renseigné' }} · {{ $carPosition->categorie ?: 'Catégorie non renseignée' }}</dd>
                    <dt>Plaque / marque / modèle</dt><dd>{{ $carPosition->numero_vehicule ?: '—' }} · {{ $carPosition->marque ?: '—' }} · {{ $carPosition->model ?: '—' }}</dd>
                    <dt>Couleur</dt><dd>{{ $carPosition->couleur ?: '—' }}</dd>
                    <dt>État général</dt><dd>{{ $carPosition->entretien ?: '—' }}</dd>
                    <dt>Autre situation constatée</dt><dd>{{ $carPosition->autre_situation ?: '—' }}</dd>
                    <dt>Détails du véhicule</dt><dd>{{ collect([
                        $carPosition->defaut_controle_technique ? 'Contrôle technique' : null,
                        $carPosition->pneumatiques_manquantes ? 'Pneumatiques manquants' : null,
                        $carPosition->vehicule_immerge ? 'Véhicule immergé' : null,
                        $carPosition->defauts_techniques_irreversibles ? 'Défauts techniques irréversibles' : null,
                        $carPosition->vehicule_non_identifiable ? 'Véhicule non identifiable' : null,
                        $carPosition->vehicule_brule ? 'Véhicule brûlé' : null,
                    ])->filter()->join(' · ') ?: 'Aucun détail renseigné' }}</dd>
                    <dt>Pays étranger</dt><dd>{{ $carPosition->pays_etranger ?: '—' }}</dd>
                </dl>
            </div></div>
            <div class="col-lg-6"><div class="report-detail">
                <h4>Constatation de l’agent</h4>
                <dl class="mb-0">
                    <dt>Motif d’infraction</dt><dd>{{ $carPosition->motif_infraction ?: '—' }}</dd>
                    <dt>Explication</dt><dd>{{ $carPosition->explication_infraction ?: '—' }}</dd>
                    <dt>Lieu</dt><dd>{{ $carPosition->lieu ?: '—' }}</dd>
                    <dt>Conditions</dt><dd>{{ $carPosition->pluie ? 'Pluie' : ($carPosition->nuit ? 'Nuit' : 'Jour / non précisé') }}</dd>
                    <dt>Pièces manquantes</dt><dd>{{ $carPosition->pieces_manquantes ?: '—' }}</dd>
                    <dt>Dommages</dt><dd>@if($carPosition->dommage_image)<a href="{{ $storageBase.'/dommages/'.$carPosition->dommage_image }}" target="_blank" rel="noopener"><img class="report-agent-photo" style="max-width:400px;object-fit:contain;background:#f5f8f6" src="{{ $storageBase.'/dommages/'.$carPosition->dommage_image }}" alt="Schéma des dommages annoté"></a>@else Non renseignés @endif</dd>
                </dl>
            </div></div>
        </div>
        <div class="report-detail mb-4">
            <h4 class="mb-3">Photo du citoyen</h4>
            <div class="row g-3">
                @forelse($photos as $citizenPhoto)
                    <div class="col-6 col-md-3"><a href="{{ $storageBase.'/'.$citizenPhoto->filepath }}" target="_blank" rel="noopener"><img class="report-agent-photo" src="{{ $storageBase.'/'.$citizenPhoto->filepath }}" alt="Photo du citoyen {{ $loop->iteration }}"></a></div>
                @empty
                    <p class="text-muted mb-0">Aucune photo ajoutée par le citoyen.</p>
                @endforelse
            </div>
        </div>
        <div class="report-detail mb-4">
            <h4 class="mb-3">Photos de l’agent</h4>
            <div class="row g-3">
                @forelse($agentPhotos as $agentPhoto)
                    <div class="col-6 col-md-3"><a href="{{ $storageBase.'/'.$agentPhoto->filepath }}" target="_blank" rel="noopener"><img class="report-agent-photo" src="{{ $storageBase.'/'.$agentPhoto->filepath }}" alt="Photo de constatation {{ $loop->iteration }}"></a></div>
                @empty
                    <p class="text-muted mb-0">Aucune photo de constatation ajoutée.</p>
                @endforelse
            </div>
        </div>

        {{-- Décision de l'autorité (remplace les anciens onglets de saisie). --}}
        @php
            $peutDecider = in_array((int) Auth::user()->role_id, [1, 3, 4], true);
            $transmis = !empty($carPosition->dommage_image);
            $decide = $carPosition->is_approve || $carPosition->etat === 'REJETE';
        @endphp
        <div class="report-detail mb-4" id="decision">
            <div class="d-flex flex-wrap align-items-center justify-content-between gap-2 mb-3">
                <h4 class="mb-0">Approbation</h4>
                @if($transmis)
                    <a href="{{ route('pdf_constation', $carPosition) }}" target="_blank" rel="noopener" class="btn btn-outline-success btn-sm">
                        <i class="lni lni-empty-file"></i> Consulter le PV
                    </a>
                @endif
            </div>
            @if(!$transmis)
                <p class="text-muted mb-0">La constatation n’a pas encore été transmise par l’agent : la décision n’est pas encore possible.</p>
            @elseif($decide)
                <div class="decision-resultat {{ $carPosition->is_approve ? 'ok' : 'refus' }}">
                    <strong>{{ $carPosition->is_approve ? 'Signalement approuvé' : 'Signalement rejeté' }}</strong>
                    <div>{{ $carPosition->motife_approbation ? 'Motif : '.$carPosition->motife_approbation : 'Aucun motif renseigné' }}</div>
                </div>
            @elseif(!$peutDecider)
                <p class="text-muted mb-0">En attente de la décision de l’autorité.</p>
            @else
                <form action="{{ route('approbation', $carPosition) }}" method="post">
                    @csrf @method('patch')
                    <div class="decision-choix mb-3">
                        <label>
                            <input type="radio" name="approbation" value="OUI" @checked(old('approbation') === 'OUI') required>
                            <span class="ok"><i class="lni lni-checkmark-circle"></i> Approuver</span>
                        </label>
                        <label>
                            <input type="radio" name="approbation" value="NON" @checked(old('approbation') === 'NON')>
                            <span class="refus"><i class="lni lni-close"></i> Rejeter</span>
                        </label>
                    </div>
                    <label class="form-label fw-semibold" for="motif-decision">Motif</label>
                    <textarea class="form-control @error('motife_approbation') is-invalid @enderror" id="motif-decision" name="motife_approbation" rows="3" maxlength="225" placeholder="Obligatoire en cas de rejet, facultatif pour une approbation">{{ old('motife_approbation') }}</textarea>
                    @error('motife_approbation')<div class="invalid-feedback">{{ $message }}</div>@enderror
                    <div class="text-end mt-3">
                        <button type="submit" class="main-btn success-btn btn-hover"><i class="lni lni-checkmark"></i> Enregistrer la décision</button>
                    </div>
                </form>
            @endif
        </div>
    </div>
</section>
@endsection
