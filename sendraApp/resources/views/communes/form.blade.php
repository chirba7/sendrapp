@extends('layouts.master')
@section('session')
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet.draw/1.0.4/leaflet.draw.css">
<section class="section"><div class="container-fluid">
    <div class="title-wrapper pt-30"><h2 class="text-success">{{ $commune->exists ? 'Modifier la commune' : 'Créer une commune' }}</h2></div>
    @if($errors->any())<div class="alert alert-danger"><ul class="mb-0">@foreach($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>@endif
    <form class="card-style mb-30" method="POST" action="{{ $commune->exists ? route('communes.update', $commune) : route('communes.store') }}">
        @csrf @if($commune->exists) @method('PUT') @endif
        <div class="row g-3">
            <div class="col-md-6"><label class="form-label">Nom *</label><input class="form-control" name="nomCommune" value="{{ old('nomCommune', $commune->nomCommune) }}" required></div>
            <div class="col-md-6"><label class="form-label">Département</label><input class="form-control" name="departement" value="{{ old('departement', $commune->departement) }}"></div>
            <div class="col-md-6"><label class="form-label">Marge de géofence *</label><select class="form-select" id="geofence-margin" name="geofence_margin_meters"><option value="500" @selected(old('geofence_margin_meters', $commune->geofence_margin_meters ?: 500)==500)>500 mètres</option><option value="1000" @selected(old('geofence_margin_meters', $commune->geofence_margin_meters)==1000)>1 000 mètres</option></select></div>
            <div class="col-12"><p class="text-muted mb-2">Cliquez pour placer le centre, puis utilisez l’outil polygone à gauche pour cadrer la commune.</p><div id="commune-map" style="height:480px;border-radius:12px"></div></div>
            <input type="hidden" name="latitude" id="latitude" value="{{ old('latitude', $commune->latitude) }}">
            <input type="hidden" name="longitude" id="longitude" value="{{ old('longitude', $commune->longitude) }}">
            <input type="hidden" name="geofence" id="geofence" value="{{ old('geofence', $commune->geofence ? json_encode($commune->geofence) : '') }}">
            <div class="col-12 text-end"><a href="{{ route('communes.index') }}" class="main-btn light-btn">Annuler</a> <button class="main-btn success-btn" type="submit">Enregistrer</button></div>
        </div>
    </form>
</div></section>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet.draw/1.0.4/leaflet.draw.js"></script>
<script src="https://cdn.jsdelivr.net/npm/@turf/turf@6/turf.min.js"></script>
<script>
document.addEventListener('DOMContentLoaded', () => {
    const lat = parseFloat(document.getElementById('latitude').value) || 14.7167;
    const lng = parseFloat(document.getElementById('longitude').value) || -17.4677;
    const map = L.map('commune-map').setView([lat, lng], 12);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {maxZoom: 19, attribution: '© OpenStreetMap'}).addTo(map);
    let marker = L.marker([lat, lng], {draggable:true}).addTo(map);
    const drawn = new L.FeatureGroup().addTo(map);
    const raw = document.getElementById('geofence').value;
    if (raw) { try { const geo = JSON.parse(raw); L.geoJSON(geo).eachLayer(layer => drawn.addLayer(layer)); if (drawn.getLayers().length) map.fitBounds(drawn.getBounds()); } catch (_) {} }
    map.addControl(new L.Control.Draw({edit:{featureGroup:drawn}, draw:{polyline:false,rectangle:false,circle:false,circlemarker:false,marker:false}}));
    const saveMarker = p => { document.getElementById('latitude').value=p.lat.toFixed(7); document.getElementById('longitude').value=p.lng.toFixed(7); };
    marker.on('dragend', e => saveMarker(e.target.getLatLng()));
    map.on('click', e => { marker.setLatLng(e.latlng); saveMarker(e.latlng); });
    const saveShape = () => { const layer=drawn.getLayers()[0]; document.getElementById('geofence').value=layer ? JSON.stringify(layer.toGeoJSON().geometry) : ''; };
    map.on(L.Draw.Event.CREATED, e => { drawn.clearLayers(); drawn.addLayer(e.layer); saveShape(); });
    map.on(L.Draw.Event.EDITED, saveShape); map.on(L.Draw.Event.DELETED, saveShape);
});
</script>
@endsection
