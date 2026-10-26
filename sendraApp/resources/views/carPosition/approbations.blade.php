@extends('layouts.master')
@section('session')
@php
    $storage = rtrim(config('services.backend.storage_url'), '/').'/';
    $nom = fn ($u) => trim(($u?->first_name ?? '').' '.($u?->last_name ?? ''));
@endphp
<style>
    .appro { font-family:"Inter", system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; color:#15201a; }
    .appro h2 { font-size:26px; font-weight:800; letter-spacing:-.3px; }
    .appro .sous-titre { color:#5f6b65; font-size:15px; }
    .appro-filtres a { border-radius:12px; font-weight:600; }
    .appro-recherche { display:flex; flex-wrap:wrap; gap:8px; max-width:560px; }
    .appro-recherche input { flex:1; min-width:220px; border-radius:12px; height:46px; font-size:15px; }
    .appro-recherche button { border-radius:12px; font-weight:600; }
    .appro-carte { border:1px solid #e1e8e4; border-radius:18px; background:#fff; padding:18px; margin-bottom:14px; }
    .appro-carte:hover { border-color:#b7dec4; box-shadow:0 10px 26px rgba(19,61,43,.08); }
    .appro-num { font-size:13px; font-weight:700; color:#5f6b65; text-transform:uppercase; letter-spacing:.4px; }
    .appro-titre { font-size:19px; font-weight:800; margin:2px 0 6px; }
    .appro-vehicule { display:inline-flex; gap:8px; flex-wrap:wrap; margin-bottom:8px; }
    .appro-vehicule span { background:#f2f6f4; border-radius:10px; padding:4px 10px; font-weight:600; font-size:14px; }
    .appro-vehicule .plaque { background:#15201a; color:#fff; letter-spacing:1px; font-family:"Inter", monospace; }
    .appro-meta { color:#5f6b65; font-size:14px; line-height:1.6; }
    .appro-meta strong { color:#15201a; font-weight:600; }
    .appro-photos img { width:64px; height:64px; object-fit:cover; border-radius:10px; }
    .appro-photos .legende { font-size:12px; font-weight:700; color:#5f6b65; text-transform:uppercase; }
    .appro-decision textarea { border-radius:12px; font-size:14px; }
    .appro-decision .btn { border-radius:12px; font-weight:700; min-height:44px; }
    .appro-badge { display:inline-block; border-radius:10px; padding:4px 10px; font-weight:700; font-size:14px; }
    .appro-badge.ok { background:#e8f5ed; color:#0b6b30; }
    .appro-badge.refus { background:#fdecea; color:#b3261e; }
</style>
<section class="section appro">
  <div class="container-fluid">
    <div class="title-wrapper pt-30">
      <h2 class="text-success mb-1">Décisions sur les signalements</h2>
      <p class="sous-titre mb-0">{{ $enAttente }} dossier(s) à traiter. Ouvrez le PV avant de décider.</p>
    </div>
    @if(session('success'))<div class="alert alert-success">{{ session('success') }}</div>@endif
    @if($errors->any())<div class="alert alert-danger">{{ $errors->first() }}</div>@endif

    <div class="card-style mb-30">
      <div class="d-flex flex-wrap justify-content-between gap-3 mb-4">
        <div class="appro-filtres d-flex flex-wrap gap-2">
          <a class="btn {{ $filtre === 'attente' ? 'btn-success' : 'btn-outline-success' }}" href="{{ route('approbations.index', array_filter(['filtre' => 'attente', 'q' => $recherche])) }}">À traiter ({{ $enAttente }})</a>
          <a class="btn {{ $filtre === 'approuves' ? 'btn-success' : 'btn-outline-success' }}" href="{{ route('approbations.index', array_filter(['filtre' => 'approuves', 'q' => $recherche])) }}">Approuvés</a>
          <a class="btn {{ $filtre === 'refuses' ? 'btn-success' : 'btn-outline-success' }}" href="{{ route('approbations.index', array_filter(['filtre' => 'refuses', 'q' => $recherche])) }}">Refusés</a>
        </div>
        <form method="get" action="{{ route('approbations.index') }}" class="appro-recherche">
          <input type="hidden" name="filtre" value="{{ $filtre }}">
          <input type="search" name="q" value="{{ $recherche }}" class="form-control" placeholder="Plaque (ex. AA-573-LP ou aa573lp), n°, marque, commune" aria-label="Rechercher">
          <button class="btn btn-success" type="submit"><i class="lni lni-search-alt"></i> Rechercher</button>
          @if($recherche !== '')
            <a class="btn btn-outline-secondary" href="{{ route('approbations.index', ['filtre' => $filtre]) }}">Effacer</a>
          @endif
        </form>
      </div>

      @forelse($signalements as $signalement)
        @php
          $lienFiche = route('details', ['carPosition' => $signalement, 'depuis' => 'approbations', 'filtre' => $filtre, 'q' => $recherche ?: null]);
          $marqueModele = trim(($signalement->marque ?? '').' '.($signalement->model ?? ''));
        @endphp
        <article class="appro-carte">
          <div class="row g-3">
            <div class="col-lg-6">
              <div class="appro-num">Signalement n° {{ $signalement->id }} · {{ $signalement->updated_at->format('d/m/Y à H:i') }}</div>
              <div class="appro-titre"><a href="{{ $lienFiche }}" class="text-reset">{{ $signalement->vehicle_kind ?: $signalement->title }}</a></div>
              <div class="appro-vehicule">
                @if($marqueModele)<span>{{ $marqueModele }}</span>@endif
                <span class="{{ $signalement->numero_vehicule ? 'plaque' : '' }}">{{ $signalement->numero_vehicule ?: 'Plaque non renseignée' }}</span>
              </div>
              <div class="appro-meta">
                <div><strong>Commune :</strong> {{ $signalement->commune ?: '—' }}</div>
                <div><strong>Citoyen :</strong> {{ $nom($signalement->user) ?: 'Non renseigné' }} · <strong>Agent :</strong> {{ $nom($signalement->agent) ?: 'Non affecté' }}</div>
              </div>
              <div class="appro-photos d-flex flex-wrap gap-3 my-3">
                <div><div class="legende mb-1">Citoyen</div>
                  @foreach($signalement->photo->where('position', '!=', 'agent_constat') as $photo)
                    <a href="{{ $storage.$photo->filepath }}" target="_blank" rel="noopener"><img src="{{ $storage.$photo->filepath }}" alt="Photo du citoyen"></a>
                  @endforeach
                </div>
                <div><div class="legende mb-1">Agent</div>
                  @forelse($signalement->photo->where('position', 'agent_constat') as $photo)
                    <a href="{{ $storage.$photo->filepath }}" target="_blank" rel="noopener"><img src="{{ $storage.$photo->filepath }}" alt="Photo de l’agent"></a>
                  @empty
                    <span class="text-muted small">Aucune</span>
                  @endforelse
                </div>
              </div>
              <a href="{{ $lienFiche }}" class="btn btn-outline-secondary btn-sm"><i class="lni lni-eye"></i> Détails</a>
              <a href="{{ route('pdf_constation', $signalement) }}" target="_blank" rel="noopener" class="btn btn-outline-success btn-sm"><i class="lni lni-empty-file"></i> Consulter le PV</a>
            </div>
            <div class="col-lg-6 appro-decision">
              @if($filtre === 'attente')
                <form action="{{ route('approbation', $signalement) }}" method="post">
                  @csrf @method('patch')
                  <label class="form-label fw-semibold">Motif</label>
                  <textarea name="motife_approbation" class="form-control mb-2" rows="3" maxlength="225" placeholder="Obligatoire en cas de refus"></textarea>
                  <div class="d-flex flex-wrap gap-2">
                    <button type="submit" name="approbation" value="OUI" class="btn btn-success flex-fill"><i class="lni lni-checkmark-circle"></i> Approuver</button>
                    <button type="submit" name="approbation" value="NON" class="btn btn-outline-danger flex-fill"><i class="lni lni-close"></i> Refuser</button>
                  </div>
                </form>
              @else
                <span class="appro-badge {{ $filtre === 'approuves' ? 'ok' : 'refus' }}">{{ $filtre === 'approuves' ? 'Approuvé' : 'Refusé' }}</span>
                @if($signalement->motife_approbation)<p class="mt-2 mb-0">{{ $signalement->motife_approbation }}</p>@endif
              @endif
            </div>
          </div>
        </article>
      @empty
        <p class="text-muted">Aucun dossier dans cette vue{{ $recherche !== '' ? ' pour « '.$recherche.' »' : '' }}.</p>
      @endforelse
      {{ $signalements->links() }}
    </div>
  </div>
</section>
@endsection
