@extends('layouts.master')
@section('session')
<section class="section">
  <div class="container-fluid">
    <div class="title-wrapper pt-30"><h2 class="text-success">Décisions sur les signalements</h2></div>
    @if(session('success'))<div class="alert alert-success">{{ session('success') }}</div>@endif
    @if($errors->any())<div class="alert alert-danger">{{ $errors->first() }}</div>@endif
    <div class="card-style mb-30">
      <p class="mb-3">{{ $enAttente }} dossier(s) à traiter. Ouvrez le PV avant de décider.</p>
      <div class="d-flex flex-wrap gap-2 mb-4">
        <a class="btn {{ $filtre === 'attente' ? 'btn-success' : 'btn-outline-success' }}" href="{{ route('approbations.index', ['filtre' => 'attente']) }}">À traiter ({{ $enAttente }})</a>
        <a class="btn {{ $filtre === 'approuves' ? 'btn-success' : 'btn-outline-success' }}" href="{{ route('approbations.index', ['filtre' => 'approuves']) }}">Approuvés</a>
        <a class="btn {{ $filtre === 'refuses' ? 'btn-success' : 'btn-outline-success' }}" href="{{ route('approbations.index', ['filtre' => 'refuses']) }}">Refusés</a>
      </div>
      <form method="get" action="{{ route('approbations.index') }}" class="d-flex flex-wrap gap-2 mb-4">
        <input type="hidden" name="filtre" value="{{ $filtre }}">
        <input type="search" name="q" value="{{ $recherche }}" class="form-control" style="max-width:360px" placeholder="N°, commune ou plaque">
        <button class="btn btn-outline-success" type="submit">Rechercher</button>
      </form>
      @forelse($signalements as $signalement)
        <article class="border rounded p-3 mb-3">
          <div class="row align-items-start g-3">
            <div class="col-lg-5">
              <h5>N° {{ $signalement->id }} · {{ $signalement->title }}</h5>
              <p class="mb-1">{{ $signalement->commune }} · {{ $signalement->updated_at->format('d/m/Y H:i') }}</p>
              <p class="mb-1">Citoyen : {{ trim(($signalement->user?->first_name ?? '').' '.($signalement->user?->last_name ?? '')) ?: 'Non renseigné' }} · Agent : {{ trim(($signalement->agent?->first_name ?? '').' '.($signalement->agent?->last_name ?? '')) ?: 'Non affecté' }}</p>
              <p class="mb-2">Plaque : {{ $signalement->numero_vehicule ?: 'Non renseignée' }}</p>
              <div class="d-flex flex-wrap gap-3 mb-2">
                <div><strong>Citoyen</strong><br>
                  @foreach($signalement->photo->where('position', '!=', 'agent_constat') as $photo)
                    <a href="{{ rtrim(config('services.backend.storage_url'), '/') . '/' . $photo->filepath }}" target="_blank" rel="noopener">
                      <img src="{{ rtrim(config('services.backend.storage_url'), '/') . '/' . $photo->filepath }}" alt="Photo du citoyen" style="width:64px;height:64px;object-fit:cover;border-radius:8px">
                    </a>
                  @endforeach
                </div>
                <div><strong>Agent</strong><br>
                  @foreach($signalement->photo->where('position', 'agent_constat') as $photo)
                    <a href="{{ rtrim(config('services.backend.storage_url'), '/') . '/' . $photo->filepath }}" target="_blank" rel="noopener">
                      <img src="{{ rtrim(config('services.backend.storage_url'), '/') . '/' . $photo->filepath }}" alt="Photo de l’agent" style="width:64px;height:64px;object-fit:cover;border-radius:8px">
                    </a>
                  @endforeach
                </div>
              </div>
              <a href="{{ route('details', $signalement) }}" class="btn btn-outline-secondary btn-sm">Détails</a>
              <a href="{{ route('pdf_constation', $signalement) }}" target="_blank" rel="noopener" class="btn btn-outline-success btn-sm">Consulter le PV</a>
            </div>
            @if($filtre === 'attente')
            <div class="col-lg-7">
              <form action="{{ route('approbation', $signalement) }}" method="post" class="d-flex flex-wrap gap-2 align-items-start">
                @csrf @method('patch')
                <textarea name="motife_approbation" class="form-control" style="min-width:240px;flex:1" rows="2" maxlength="225" placeholder="Motif obligatoire en cas de refus"></textarea>
                <button type="submit" name="approbation" value="OUI" class="btn btn-success">Approuver</button>
                <button type="submit" name="approbation" value="NON" class="btn btn-outline-danger">Refuser</button>
              </form>
            </div>
            @else
            <div class="col-lg-7"><strong>{{ $filtre === 'approuves' ? 'Approuvé' : 'Refusé' }}</strong>
              @if($signalement->motife_approbation)<p>{{ $signalement->motife_approbation }}</p>@endif
            </div>
            @endif
          </div>
        </article>
      @empty
        <p>Aucun dossier dans cette vue.</p>
      @endforelse
      {{ $signalements->links() }}
    </div>
  </div>
</section>
@endsection
