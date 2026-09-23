@extends('layouts.master')
@section('session')
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
<section class="section"><div class="container-fluid">
    <div class="title-wrapper pt-30"><div class="row"><div class="col-md-8"><h2 class="text-success">{{ $commune->nomCommune }}</h2></div><div class="col-md-4 text-end"><a href="{{ route('communes.edit',$commune) }}" class="main-btn success-btn">Modifier</a></div></div></div>
    @if(session('success'))<div class="alert alert-success">{{session('success')}}</div>@endif
    <div class="card-style mb-30"><div class="row mb-3"><div class="col-md-4"><strong>Département</strong><p>{{ $commune->departement ?: '—' }}</p></div><div class="col-md-4"><strong>Marge</strong><p>{{ $commune->geofence_margin_meters }} m</p></div><div class="col-md-4"><strong>Missions</strong><p>{{ $commune->missions_count }}</p></div></div><div id="commune-map" style="height:480px;border-radius:12px"></div></div>
</div></section>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script><script src="https://cdn.jsdelivr.net/npm/@turf/turf@6/turf.min.js"></script><script>
document.addEventListener('DOMContentLoaded',()=>{const map=L.map('commune-map').setView([{{(float)$commune->latitude}},{{(float)$commune->longitude}}],12);L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19,attribution:'© OpenStreetMap'}).addTo(map);L.marker([{{(float)$commune->latitude}},{{(float)$commune->longitude}}]).addTo(map);const geo=@json($commune->geofence);if(geo){const buffer=turf.buffer(geo,{{(int)$commune->geofence_margin_meters}}/1000,{units:'kilometers'});L.geoJSON(buffer,{style:{color:'#07883F',weight:2,dashArray:'6 6',fillOpacity:.08}}).addTo(map);const layer=L.geoJSON(geo).addTo(map);map.fitBounds(L.geoJSON(buffer).getBounds());}});
</script>
@endsection
