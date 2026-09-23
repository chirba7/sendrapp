@extends('layouts.master')
@section('session')
<section class="section"><div class="container-fluid">
<div class="title-wrapper pt-30"><div class="row"><div class="col-md-8"><h2 class="text-success">Mission {{ $mission->code }}</h2><p>{{ $mission->title }}</p></div><div class="col-md-4 text-end"><a href="{{route('missions.edit',$mission)}}" class="main-btn success-btn">Modifier</a></div></div></div>
@if(session('success'))<div class="alert alert-success">{{session('success')}}</div>@endif
<div class="card-style mb-30"><div class="row g-3">
<div class="col-md-3"><strong>Type</strong><p>{{$mission->type==='programmee'?'Programmée':'Directe'}}</p></div><div class="col-md-3"><strong>Commune</strong><p>{{$mission->commune?->nomCommune ?: '—'}}</p></div><div class="col-md-3"><strong>Date</strong><p>{{$mission->scheduled_at?->format('d/m/Y H:i') ?: '—'}}</p></div><div class="col-md-3"><strong>Prestataire</strong><p>{{$mission->provider_name ?: '—'}}</p></div>
<div class="col-md-4"><h5>Agents</h5>@forelse($mission->agents as $agent)<p class="mb-1">{{trim($agent->first_name.' '.$agent->last_name)}} @if($agent->pivot->checked_in_at)<span class="badge bg-success">Pointé le {{date('d/m/Y H:i',strtotime($agent->pivot->checked_in_at))}}</span>@endif</p>@empty<p>Tous les agents peuvent prendre cette mission.</p>@endforelse</div>
<div class="col-md-4"><h5>Camions</h5>@forelse($mission->trucks as $truck)<p>{{$truck->trailer_brand}} — {{$truck->registration}}<br><small>{{$truck->driver_name}} · {{$truck->seats ? $truck->seats.' places' : ''}}</small></p>@empty<p>—</p>@endforelse</div>
<div class="col-md-4"><h5>Fourrières</h5>@forelse($mission->pounds??[] as $pound)<p class="mb-1">{{$pound}}</p>@empty<p>—</p>@endforelse</div>
<div class="col-12"><h5>Véhicules à emporter</h5>@forelse($mission->vehicles as $vehicle)<span class="badge bg-light text-dark me-2">#{{$vehicle->id}} {{$vehicle->marque}} {{$vehicle->model}} {{$vehicle->numero_vehicule}}</span>@empty<p>—</p>@endforelse</div>
</div></div></div></section>
@endsection
