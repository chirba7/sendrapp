@extends('layouts.master')
@section('session')
<section class="section"><div class="container-fluid">
    <div class="title-wrapper pt-30"><div class="row align-items-center">
        <div class="col-md-6"><h2 class="text-success">Communes</h2></div>
        <div class="col-md-6 text-md-end"><a href="{{ route('communes.create') }}" class="main-btn success-btn btn-hover">Ajouter une commune</a></div>
    </div></div>
    @if(session('success'))<div class="alert alert-success">{{ session('success') }}</div>@endif
    @if(session('error'))<div class="alert alert-danger">{{ session('error') }}</div>@endif
    <div class="card-style mb-30"><div class="table-responsive"><table class="table align-middle">
        <thead><tr><th>Commune</th><th>Département</th><th>Marge</th><th>Missions</th><th></th></tr></thead>
        <tbody>@forelse($communes as $commune)<tr>
            <td><strong>{{ $commune->nomCommune }}</strong></td><td>{{ $commune->departement ?: '—' }}</td>
            <td>{{ $commune->geofence_margin_meters }} m</td><td>{{ $commune->missions_count }}</td>
            <td class="text-end"><a class="btn btn-sm btn-outline-success" href="{{ route('communes.show', $commune) }}">Détails</a> <a class="btn btn-sm btn-outline-secondary" href="{{ route('communes.edit', $commune) }}">Modifier</a></td>
        </tr>@empty<tr><td colspan="5" class="text-center py-5">Aucune commune.</td></tr>@endforelse</tbody>
    </table></div>{{ $communes->links() }}</div>
</div></section>
@endsection
