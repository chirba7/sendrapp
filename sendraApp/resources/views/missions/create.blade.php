@extends('layouts.master')
@section('session')
<section class="section">
    <div class="container-fluid">
        <div class="title-wrapper pt-30">
            <div class="row align-items-center">
                <div class="col-md-8"><h2 class="text-success">Créer une mission</h2></div>
                <div class="col-md-4 text-md-end"><a href="{{ route('missions.index') }}" class="main-btn light-btn">Retour</a></div>
            </div>
        </div>

        @if ($errors->any())
            <div class="alert alert-danger"><ul class="mb-0">@foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach</ul></div>
        @endif

        <form action="{{ route('missions.store') }}" method="POST" class="card-style mb-30">
            @csrf
            <div class="row g-3">
                <div class="col-md-8">
                    <label class="form-label">Titre *</label>
                    <input class="form-control" name="title" value="{{ old('title') }}" required maxlength="255">
                </div>
                <div class="col-md-4">
                    <label class="form-label">Type *</label>
                    <select class="form-select" name="type" id="mission-type" required>
                        <option value="programmee" @selected(old('type') === 'programmee')>Programmée</option>
                        <option value="brute" @selected(old('type') === 'brute')>Brute</option>
                    </select>
                </div>
                <div class="col-md-4">
                    <label class="form-label">Date et heure *</label>
                    <input type="datetime-local" class="form-control" name="scheduled_at" value="{{ old('scheduled_at') }}" required>
                </div>
                <div class="col-md-8">
                    <label class="form-label">Lieu de rendez-vous *</label>
                    <input class="form-control" name="address" value="{{ old('address') }}" required maxlength="255">
                </div>
                <div class="col-md-4">
                    <label class="form-label">Latitude *</label>
                    <input type="number" step="0.0000001" class="form-control" name="latitude" value="{{ old('latitude') }}" required>
                </div>
                <div class="col-md-4">
                    <label class="form-label">Longitude *</label>
                    <input type="number" step="0.0000001" class="form-control" name="longitude" value="{{ old('longitude') }}" required>
                </div>
                <div class="col-md-4">
                    <label class="form-label">Rayon de pointage *</label>
                    <select class="form-select" name="check_in_radius_meters" required>
                        @foreach ([100, 150, 200] as $radius)
                            <option value="{{ $radius }}" @selected((int) old('check_in_radius_meters', 150) === $radius)>{{ $radius }} mètres</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-4">
                    <label class="form-label">Marque de la remorque</label>
                    <input class="form-control" name="trailer_brand" value="{{ old('trailer_brand') }}">
                </div>
                <div class="col-md-4">
                    <label class="form-label">Immatriculation de la remorque</label>
                    <input class="form-control" name="trailer_plate" value="{{ old('trailer_plate') }}">
                </div>
                <div class="col-12">
                    <label class="form-label">Fourrières prêtes à accueillir les épaves</label>
                    <textarea class="form-control" name="pounds" rows="3" placeholder="Une fourrière par ligne">{{ old('pounds') }}</textarea>
                </div>
                <div class="col-md-6">
                    <label class="form-label">Agents affectés *</label>
                    <select class="form-select" name="agents[]" multiple size="8" required>
                        @foreach ($agents as $agent)
                            <option value="{{ $agent->id }}" @selected(in_array($agent->id, old('agents', [])))>
                                {{ trim($agent->first_name.' '.$agent->last_name) }} — {{ $agent->telephone }}
                            </option>
                        @endforeach
                    </select>
                    <small class="text-muted">Maintenez Ctrl/Cmd pour sélectionner plusieurs agents.</small>
                </div>
                <div class="col-md-6" id="vehicles-field">
                    <label class="form-label">Véhicules à emporter *</label>
                    <select class="form-select" name="vehicles[]" multiple size="8">
                        @foreach ($vehicles as $vehicle)
                            <option value="{{ $vehicle->id }}" @selected(in_array($vehicle->id, old('vehicles', [])))>
                                #{{ $vehicle->id }} — {{ $vehicle->marque ?: 'Marque inconnue' }} {{ $vehicle->model }} — {{ $vehicle->numero_vehicule ?: 'sans plaque' }}
                            </option>
                        @endforeach
                    </select>
                    <small class="text-muted">La liste restera masquée dans l’application jusqu’au pointage.</small>
                </div>
                <div class="col-12 mt-4 text-end">
                    <button type="submit" class="main-btn success-btn btn-hover">Créer et transmettre la mission</button>
                </div>
            </div>
        </form>
    </div>
</section>
<script>
document.addEventListener('DOMContentLoaded', function () {
    const type = document.getElementById('mission-type');
    const vehicles = document.getElementById('vehicles-field');
    const refresh = () => vehicles.style.display = type.value === 'programmee' ? '' : 'none';
    type.addEventListener('change', refresh);
    refresh();
});
</script>
@endsection
