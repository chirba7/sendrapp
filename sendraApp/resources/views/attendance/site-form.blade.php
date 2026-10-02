@extends('layouts.master')
@section('session')
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
<section class="section"><div class="container-fluid">
    <div class="title-wrapper pt-30"><h2 class="text-success">{{$site->exists ? 'Modifier le site' : 'Créer un site de pointage'}}</h2></div>
    @include('attendance.nav')
    <form class="card-style" method="POST" action="{{$site->exists ? route('attendance.sites.update', $site) : route('attendance.sites.store')}}">
        @csrf @if($site->exists) @method('PUT') @endif
        <div class="row g-3">
            <div class="col-md-6"><label for="name" class="form-label">Nom du site</label><input id="name" name="name" class="form-control" value="{{old('name', $site->name)}}" maxlength="255" required></div>
            <div class="col-md-6"><label for="address" class="form-label">Adresse</label><input id="address" name="address" class="form-control" value="{{old('address', $site->address)}}" maxlength="255"></div>
            <div class="col-12"><p>Cliquez sur la carte pour placer le point de référence, ou saisissez ses coordonnées. Le cercle représente le rayon autorisé lors du pointage.</p><div id="attendance-map" style="height:360px;border-radius:12px" aria-label="Position du site"></div><p id="map-message" class="text-muted" role="status"></p></div>
            <div class="col-md-3"><label for="latitude" class="form-label">Latitude</label><input type="number" step="0.0000001" min="-90" max="90" id="latitude" name="latitude" class="form-control" value="{{old('latitude', $site->latitude)}}" required></div>
            <div class="col-md-3"><label for="longitude" class="form-label">Longitude</label><input type="number" step="0.0000001" min="-180" max="180" id="longitude" name="longitude" class="form-control" value="{{old('longitude', $site->longitude)}}" required></div>
            <div class="col-md-3"><label for="radius_meters" class="form-label">Rayon autorisé (m)</label><input type="number" min="10" max="5000" id="radius_meters" name="radius_meters" class="form-control" value="{{old('radius_meters', $site->radius_meters)}}" required></div>
            <div class="col-md-3"><label for="max_accuracy_meters" class="form-label">Imprécision GPS maximale (m)</label><input type="number" min="1" max="500" id="max_accuracy_meters" name="max_accuracy_meters" class="form-control" value="{{old('max_accuracy_meters', $site->max_accuracy_meters)}}" required></div>
            <div class="col-md-6"><label for="timezone" class="form-label">Fuseau horaire</label><input id="timezone" name="timezone" class="form-control" value="{{old('timezone', $site->timezone)}}" placeholder="Africa/Dakar" required></div>
            <div class="col-md-6"><label for="active" class="form-label">État du site</label><select id="active" name="active" class="form-select"><option value="1" @selected(old('active', $site->active) == 1)>Actif</option><option value="0" @selected(old('active', $site->active) == 0)>Désactivé</option></select></div>
            <div class="col-12"><p class="text-muted">La désactivation bloque les nouvelles arrivées. Les journées déjà ouvertes restent clôturables avec leur configuration d’origine.</p></div>
            <div class="col-12 text-end"><a class="btn btn-outline-secondary" href="{{route('attendance.sites')}}">Annuler</a> <button class="btn btn-success">Enregistrer le site</button></div>
        </div>
    </form>
</div></section>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script src="{{asset('js/attendance-site.js')}}" defer></script>
@endsection
