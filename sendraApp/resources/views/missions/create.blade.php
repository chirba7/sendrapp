@extends('layouts.master')
@section('session')
<section class="section"><div class="container-fluid">
<div class="title-wrapper pt-30"><div class="row"><div class="col-md-8"><h2 class="text-success">{{ $mission->exists ? 'Modifier la mission '.$mission->code : 'Créer une mission' }}</h2></div><div class="col-md-4 text-end"><a href="{{ route('missions.index') }}" class="main-btn light-btn">Retour</a></div></div></div>
@if($errors->any())<div class="alert alert-danger"><ul class="mb-0">@foreach($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>@endif
<form action="{{ $mission->exists ? route('missions.update',$mission) : route('missions.store') }}" method="POST" class="card-style mb-30">
@csrf @if($mission->exists) @method('PUT') @endif
<div class="row g-3">
    <div class="col-md-4"><label class="form-label">Type *</label><select class="form-select" name="type" id="mission-type"><option value="programmee" @selected(old('type',$mission->type ?: 'programmee')==='programmee')>Programmée</option><option value="brute" @selected(old('type',$mission->type)==='brute')>Directe</option></select></div>
    <div class="col-md-4"><label class="form-label">Commune</label><select class="form-select" name="commune_id"><option value="">Non renseignée</option>@foreach($communes as $commune)<option value="{{$commune->id}}" @selected(old('commune_id',$mission->commune_id)==$commune->id)>{{$commune->nomCommune}} — {{$commune->departement}}</option>@endforeach</select></div>
    <div class="col-md-4"><label class="form-label">Date et heure</label><input type="datetime-local" class="form-control" name="scheduled_at" value="{{ old('scheduled_at', optional($mission->scheduled_at)->format('Y-m-d\TH:i')) }}"></div>
    <div class="col-md-6"><label class="form-label">Intitulé facultatif</label><input class="form-control" name="title" value="{{old('title',$mission->title)}}"></div>
    <div class="col-md-6"><label class="form-label">Nom du prestataire</label><input class="form-control" name="provider_name" value="{{old('provider_name',$mission->provider_name)}}"></div>

    <div class="col-12"><hr><div class="d-flex justify-content-between"><h5>Camions / remorques</h5><button type="button" class="btn btn-outline-success btn-sm" id="add-truck">Ajouter un camion</button></div><div id="trucks"></div></div>
    <div class="col-12"><hr><div class="d-flex justify-content-between"><h5>Fourrières prêtes à accueillir les épaves</h5><button type="button" class="btn btn-outline-success btn-sm" id="add-pound">Ajouter une fourrière</button></div><div id="pounds"></div></div>

    <div class="col-md-6"><label class="form-label">Agents affectés <span id="agents-required">*</span></label><select class="form-select" name="agents[]" multiple size="9">@php($selectedAgents=old('agents',$mission->exists?$mission->agents->pluck('id')->all():[]))@foreach($agents as $agent)<option value="{{$agent->id}}" @selected(in_array($agent->id,$selectedAgents))>{{trim($agent->first_name.' '.$agent->last_name)}} — {{$agent->telephone}}</option>@endforeach</select><small class="text-muted">Facultatif en mission directe : sans sélection, tous les agents la verront.</small></div>
    <div class="col-md-6" id="vehicles-field"><label class="form-label">Véhicules à emporter *</label><select class="form-select" name="vehicles[]" multiple size="9">@php($selectedVehicles=old('vehicles',$mission->exists?$mission->vehicles->pluck('id')->all():[]))@foreach($vehicles as $vehicle)<option value="{{$vehicle->id}}" @selected(in_array($vehicle->id,$selectedVehicles))>#{{$vehicle->id}} — {{$vehicle->marque ?: 'Marque inconnue'}} {{$vehicle->model}} — {{$vehicle->numero_vehicule ?: 'sans plaque'}}</option>@endforeach</select></div>
    <div class="col-12 text-end mt-4"><button class="main-btn success-btn" type="submit">{{ $mission->exists ? 'Enregistrer les modifications' : 'Créer la mission' }}</button></div>
</div></form></div></section>
<template id="truck-template"><div class="row g-2 mt-1 repeat-row"><div class="col-md-3"><input class="form-control" data-name="trailer_brand" placeholder="Marque remorque"></div><div class="col-md-3"><input class="form-control" data-name="registration" placeholder="Immatriculation"></div><div class="col-md-3"><input class="form-control" data-name="driver_name" placeholder="Nom du chauffeur"></div><div class="col-md-2"><input type="number" min="1" class="form-control" data-name="seats" placeholder="Places"></div><div class="col-md-1"><button type="button" class="btn btn-outline-danger remove-row">×</button></div></div></template>
<template id="pound-template"><div class="input-group mt-2 repeat-row"><input class="form-control" data-name="pound" placeholder="Nom de la fourrière"><button type="button" class="btn btn-outline-danger remove-row">Retirer</button></div></template>
<script>
document.addEventListener('DOMContentLoaded',()=>{
 let truckIndex=0,poundIndex=0;
 const addTruck=(v={})=>{const n=document.getElementById('truck-template').content.cloneNode(true);n.querySelectorAll('[data-name]').forEach(i=>{i.name=`trucks[${truckIndex}][${i.dataset.name}]`;i.value=v[i.dataset.name]||''});document.getElementById('trucks').appendChild(n);truckIndex++};
 const addPound=(v='')=>{const n=document.getElementById('pound-template').content.cloneNode(true);const i=n.querySelector('[data-name]');i.name=`pounds[${poundIndex++}]`;i.value=v;document.getElementById('pounds').appendChild(n)};
 document.getElementById('add-truck').onclick=()=>addTruck();document.getElementById('add-pound').onclick=()=>addPound();document.addEventListener('click',e=>{if(e.target.classList.contains('remove-row'))e.target.closest('.repeat-row').remove()});
 const initialTrucks=@json(old('trucks',$mission->exists?$mission->trucks->toArray():[]));const initialPounds=@json(old('pounds',$mission->pounds??[]));initialTrucks.length?initialTrucks.forEach(addTruck):addTruck();initialPounds.length?initialPounds.forEach(addPound):addPound();
 const type=document.getElementById('mission-type'),refresh=()=>{const p=type.value==='programmee';document.getElementById('vehicles-field').style.display=p?'':'none';document.getElementById('agents-required').style.display=p?'':'none'};type.onchange=refresh;refresh();
});
</script>
@endsection
