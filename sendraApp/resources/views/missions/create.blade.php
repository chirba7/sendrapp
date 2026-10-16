@extends('layouts.master')
@section('session')
@php
    // Mêmes repères visuels que la fiche de mission (missions/show).
    $selectedAgents = collect(old('agents', $mission->exists ? $mission->agents->pluck('id')->all() : []))->map(fn ($v) => (int) $v)->all();
    $selectedVehicles = collect(old('vehicles', $mission->exists ? $mission->vehicles->pluck('id')->all() : []))->map(fn ($v) => (int) $v)->all();
    $selectedPounds = old('pounds', $mission->pounds ?? []);
@endphp
<style>
.mission-hero{background:linear-gradient(135deg,#073b2a,#0b8f55);color:#fff;border-radius:22px;padding:24px;box-shadow:0 16px 38px rgba(7,59,42,.18)}
.mission-hero .meta{color:rgba(255,255,255,.78)}
.form-card{border:1px solid #e7eee9;border-radius:18px;background:#fff;padding:22px;height:100%}
.form-card h5{display:flex;align-items:center;gap:10px;margin-bottom:4px}
.form-card .ico{width:40px;height:40px;border-radius:12px;display:grid;place-items:center;font-size:19px}
.pick-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(230px,1fr));gap:10px;max-height:330px;overflow:auto;padding:2px}
.pick{margin:0;cursor:pointer}
.pick input{position:absolute;opacity:0;pointer-events:none}
.pick-body{display:flex;align-items:center;gap:11px;border:2px solid #e1eae5;border-radius:14px;padding:11px 13px;background:#fff;transition:.15s;height:100%}
.pick:hover .pick-body{border-color:#a8d9bf}
.pick input:checked+.pick-body{border-color:#07834e;background:#e8f7ef;box-shadow:0 6px 16px rgba(8,120,68,.12)}
.pick input:focus-visible+.pick-body{outline:2px solid #0b8f55;outline-offset:2px}
.pick .avatar{min-width:38px;width:38px;height:38px;border-radius:12px;background:#e8f7ef;color:#07834e;display:grid;place-items:center;font-size:18px}
.pick input:checked+.pick-body .avatar{background:#07834e;color:#fff}
.pick .nom{font-weight:700;font-size:14px;line-height:1.2}
.pick .detail{color:#77827c;font-size:12px}
.pick-vide{color:#77827c;background:#f6f9f7;border-radius:14px;padding:18px;text-align:center}
.compteur{font-size:12px;font-weight:700;color:#07834e;background:#e8f7ef;border-radius:20px;padding:4px 10px}
@media(max-width:767px){.mission-hero{padding:18px}.pick-grid{grid-template-columns:1fr;max-height:none}}
</style>
<section class="section"><div class="container-fluid pb-5">

<div class="pt-30 mb-4 d-flex flex-wrap align-items-center justify-content-between gap-3">
    <a href="{{ route('missions.index') }}" class="btn btn-outline-secondary">← Retour aux missions</a>
</div>

<div class="mission-hero mb-4">
    <div class="d-flex gap-2 mb-2">
        <span class="badge bg-light text-dark">{{ $mission->exists ? 'MODIFICATION' : 'NOUVELLE MISSION' }}</span>
        @if($mission->exists)<span class="badge bg-light text-dark">{{ $mission->type === 'programmee' ? 'PROGRAMMÉE' : 'PONCTUELLE' }}</span>@endif
    </div>
    <h2 class="text-white mb-1">{{ $mission->exists ? $mission->code : 'Créer une mission' }}</h2>
    <div class="meta">{{ $mission->exists ? ($mission->title ?: 'Sans intitulé') : 'Renseignez l’organisation, l’équipe et les véhicules concernés.' }}</div>
</div>

@if($errors->any())
<div class="alert alert-danger"><ul class="mb-0">@foreach($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>
@endif

<form action="{{ $mission->exists ? route('missions.update',$mission) : route('missions.store') }}" method="POST">
@csrf @if($mission->exists) @method('PUT') @endif

{{-- Organisation --}}
<div class="form-card mb-4">
    <h5><span class="ico" style="background:#e8f2ff;color:#1769aa">🗂️</span> Organisation</h5>
    <p class="text-muted small mb-3">Type, commune et date de l’intervention.</p>
    <div class="row g-3">
        <div class="col-md-4">
            <label class="form-label">Type *</label>
            <select class="form-select" name="type" id="mission-type">
                <option value="programmee" @selected(old('type',$mission->type ?: 'programmee')==='programmee')>Programmée</option>
                <option value="brute" @selected(old('type',$mission->type)==='brute')>Ponctuelle</option>
            </select>
        </div>
        <div class="col-md-4">
            <label class="form-label">Commune</label>
            <select class="form-select" name="commune_id">
                <option value="">Non renseignée</option>
                @foreach($communes as $commune)
                <option value="{{$commune->id}}" @selected(old('commune_id',$mission->commune_id)==$commune->id)>{{$commune->nomCommune}} — {{$commune->departement}}</option>
                @endforeach
            </select>
        </div>
        <div class="col-md-4">
            <label class="form-label">Date et heure</label>
            <input type="datetime-local" class="form-control" name="scheduled_at" value="{{ old('scheduled_at', optional($mission->scheduled_at)->format('Y-m-d\TH:i')) }}">
        </div>
        <div class="col-md-6">
            <label class="form-label">Intitulé facultatif</label>
            <input class="form-control" name="title" value="{{old('title',$mission->title)}}">
        </div>
        <div class="col-md-6">
            <label class="form-label">Nom du prestataire</label>
            <input class="form-control" name="provider_name" value="{{old('provider_name',$mission->provider_name)}}">
        </div>
    </div>
</div>

<div class="row g-4 mb-4">
    {{-- Équipe terrain --}}
    <div class="col-lg-6">
        <div class="form-card">
            <h5><span class="ico" style="background:#e8f2ff;color:#1769aa">👥</span> Équipe terrain <span class="compteur ms-auto" id="compteur-agents">0</span></h5>
            <p class="text-muted small mb-2" id="agents-help">Les agents qui interviennent sur place.</p>
            <div class="mb-2"><button type="button" class="btn btn-sm btn-outline-success" data-tout="agents">Tout cocher</button> <button type="button" class="btn btn-sm btn-outline-secondary" data-rien="agents">Tout décocher</button></div>
            <div class="pick-grid" id="grid-agents">
                @forelse($agents as $agent)
                <label class="pick">
                    <input type="checkbox" name="agents[]" value="{{$agent->id}}" data-groupe="agents" @checked(in_array($agent->id,$selectedAgents))>
                    <span class="pick-body">
                        <span class="avatar">👤</span>
                        <span><span class="nom">{{trim($agent->first_name.' '.$agent->last_name)}}</span><br><span class="detail">{{$agent->telephone}}</span></span>
                    </span>
                </label>
                @empty
                <div class="pick-vide">Aucun compte Agent. Créez-en depuis Comptes → Ajouter.</div>
                @endforelse
            </div>
        </div>
    </div>

    {{-- Réception --}}
    <div class="col-lg-6">
        <div class="form-card">
            <h5><span class="ico" style="background:#f0eaff;color:#6847b8">🏢</span> Réception en fourrière</h5>
            <p class="text-muted small mb-3">Qui réceptionne les épaves, et où.</p>
            <div class="mb-3">
                <label class="form-label">Agent chargé de réceptionner *</label>
                <select class="form-select" name="reception_agent_id" required>
                    <option value="">Sélectionner</option>
                    @foreach($agents as $agent)
                    <option value="{{$agent->id}}" @selected(old('reception_agent_id',$mission->reception_agent_id)==$agent->id)>{{trim($agent->first_name.' '.$agent->last_name)}} — {{$agent->telephone}}</option>
                    @endforeach
                </select>
                <small class="text-muted">Il peut aussi faire partie de l’équipe terrain ci-contre : les deux rôles sont indépendants.</small>
            </div>
            <div class="mb-3">
                <label class="form-label">Poste de fourrière *</label>
                <select class="form-select" name="reception_pound_id" id="reception-pound" required>
                    <option value="">Sélectionner</option>
                    @foreach($poundOptions as $pound)
                    <option value="{{$pound->id}}" data-pound-name="{{$pound->name}}" @selected(old('reception_pound_id',$mission->reception_pound_id)==$pound->id)>{{$pound->name}}</option>
                    @endforeach
                </select>
            </div>
            <label class="form-label">Fourrières prêtes à accueillir les épaves</label>
            <div class="pick-grid" id="grid-pounds" style="max-height:200px">
                @forelse($poundOptions as $pound)
                <label class="pick">
                    <input type="checkbox" name="pounds[]" value="{{$pound->name}}" data-groupe="pounds" data-pound-name="{{$pound->name}}" @checked(in_array($pound->name,$selectedPounds))>
                    <span class="pick-body">
                        <span class="avatar" style="background:#f0eaff;color:#6847b8">🏁</span>
                        <span><span class="nom">{{$pound->name}}</span><br><span class="detail">{{$pound->department}}</span></span>
                    </span>
                </label>
                @empty
                <div class="pick-vide">Aucune fourrière enregistrée.</div>
                @endforelse
            </div>
            <small class="text-muted">Le poste de réception choisi est coché automatiquement.</small>
        </div>
    </div>
</div>

{{-- Véhicules --}}
<div class="form-card mb-4" id="vehicles-field">
    <h5><span class="ico" style="background:#e7f8f0;color:#087844">🚗</span> Véhicules approuvés à emporter <span class="compteur ms-auto" id="compteur-vehicles">0</span></h5>
    <p class="text-muted small mb-2" id="vehicles-help">Obligatoire pour une mission programmée.</p>
    <div class="mb-2"><button type="button" class="btn btn-sm btn-outline-success" data-tout="vehicles">Tout cocher</button> <button type="button" class="btn btn-sm btn-outline-secondary" data-rien="vehicles">Tout décocher</button></div>
    <div class="pick-grid" id="grid-vehicles">
        @forelse($vehicles as $vehicle)
        <label class="pick">
            <input type="checkbox" name="vehicles[]" value="{{$vehicle->id}}" data-groupe="vehicles" @checked(in_array($vehicle->id,$selectedVehicles))>
            <span class="pick-body">
                <span class="avatar">🚘</span>
                <span><span class="nom">{{$vehicle->marque ?: 'Marque inconnue'}} {{$vehicle->model}}</span><br><span class="detail">#{{$vehicle->id}} · {{$vehicle->numero_vehicule ?: 'sans plaque'}}</span></span>
            </span>
        </label>
        @empty
        <div class="pick-vide">Aucun véhicule approuvé disponible.</div>
        @endforelse
    </div>
</div>

{{-- Camions --}}
<div class="form-card mb-4">
    <h5><span class="ico" style="background:#fff2db;color:#a26700">🚚</span> Camions et remorques</h5>
    <p class="text-muted small mb-3">Le matériel mobilisé et son chauffeur.</p>
    <div id="trucks"></div>
    <button type="button" class="btn btn-outline-success btn-sm mt-2" id="add-truck">+ Ajouter un camion</button>
</div>

<div class="text-end">
    <a href="{{ route('missions.index') }}" class="btn btn-outline-secondary me-2">Annuler</a>
    <button class="main-btn success-btn" type="submit">{{ $mission->exists ? 'Enregistrer les modifications' : 'Créer la mission' }}</button>
</div>
</form>
</div></section>

<template id="truck-template">
<div class="row g-2 mt-1 repeat-row align-items-center">
    <input type="hidden" data-name="id">
    <div class="col-md-3"><input class="form-control" data-name="trailer_brand" placeholder="Marque remorque"></div>
    <div class="col-md-3"><input class="form-control" data-name="registration" placeholder="Immatriculation"></div>
    <div class="col-md-3"><input class="form-control" data-name="driver_name" placeholder="Nom du chauffeur"></div>
    <div class="col-md-2"><input type="number" min="1" class="form-control" data-name="seats" placeholder="Places"></div>
    <div class="col-md-1"><button type="button" class="btn btn-outline-danger remove-row">×</button></div>
</div>
</template>
<script>
document.addEventListener('DOMContentLoaded', () => {
    // --- camions : lignes répétables -------------------------------------
    let truckIndex = 0;
    const addTruck = (v = {}) => {
        const n = document.getElementById('truck-template').content.cloneNode(true);
        n.querySelectorAll('[data-name]').forEach(i => { i.name = `trucks[${truckIndex}][${i.dataset.name}]`; i.value = v[i.dataset.name] || '' });
        document.getElementById('trucks').appendChild(n); truckIndex++;
    };
    document.getElementById('add-truck').onclick = () => addTruck();
    document.addEventListener('click', e => { if (e.target.classList.contains('remove-row')) e.target.closest('.repeat-row').remove() });
    const initialTrucks = @json(old('trucks', $mission->exists ? $mission->trucks->toArray() : []));
    initialTrucks.length ? initialTrucks.forEach(addTruck) : addTruck();

    // --- cases à cocher : compteurs et tout cocher/décocher ---------------
    const compteurs = { agents: 'compteur-agents', vehicles: 'compteur-vehicles' };
    const cases = groupe => [...document.querySelectorAll(`input[data-groupe="${groupe}"]`)];
    const majCompteur = groupe => {
        const cible = document.getElementById(compteurs[groupe]);
        if (cible) cible.textContent = cases(groupe).filter(c => c.checked).length + ' / ' + cases(groupe).length;
    };
    Object.keys(compteurs).forEach(g => { cases(g).forEach(c => c.addEventListener('change', () => majCompteur(g))); majCompteur(g) });
    document.querySelectorAll('[data-tout]').forEach(b => b.onclick = () => { cases(b.dataset.tout).forEach(c => c.checked = true); majCompteur(b.dataset.tout) });
    document.querySelectorAll('[data-rien]').forEach(b => b.onclick = () => { cases(b.dataset.rien).forEach(c => c.checked = false); majCompteur(b.dataset.rien) });

    // --- le poste de réception est toujours une fourrière prête ----------
    const receptionPound = document.getElementById('reception-pound');
    const coherencePound = () => {
        const nom = receptionPound.selectedOptions[0]?.dataset.poundName;
        if (!nom) return;
        const c = document.querySelector(`input[data-groupe="pounds"][data-pound-name="${CSS.escape(nom)}"]`);
        if (c) c.checked = true;
    };
    receptionPound.addEventListener('change', coherencePound); coherencePound();

    // --- obligations selon le type de mission ----------------------------
    const type = document.getElementById('mission-type');
    const refresh = () => {
        const programmee = type.value === 'programmee';
        document.getElementById('agents-help').textContent = programmee
            ? 'Au moins un agent est obligatoire pour une mission programmée.'
            : 'Facultatif : sans sélection, tous les agents verront la mission.';
        document.getElementById('vehicles-help').textContent = programmee
            ? 'Au moins un véhicule approuvé est obligatoire.'
            : 'Facultatif : cochez les véhicules déjà connus pour que les agents les voient avant l’intervention.';
    };
    type.onchange = refresh; refresh();
});
</script>
@endsection
