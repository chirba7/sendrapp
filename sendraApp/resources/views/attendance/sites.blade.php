@extends('layouts.master')
@section('session')
<section class="section"><div class="container-fluid">
    <div class="title-wrapper pt-30 d-flex flex-wrap justify-content-between gap-3"><h2 class="text-success">Sites de pointage</h2><a class="main-btn success-btn" href="{{route('attendance.sites.create')}}">Créer un site</a></div>
    @include('attendance.nav')
    <div class="card-style table-responsive"><table class="table"><thead><tr><th>Site</th><th>Rayon autorisé</th><th>Précision GPS maximale</th><th>Affectations</th><th>État</th><th>Action</th></tr></thead><tbody>
    @forelse($sites as $site)
    <tr><td><strong>{{$site->name}}</strong><br><small>{{$site->address}}</small></td><td>{{$site->radius_meters}} m</td><td>{{$site->max_accuracy_meters}} m</td><td>{{$site->assignments_count}}</td><td>{{$site->active ? 'Actif' : 'Désactivé'}}</td><td><a class="btn btn-outline-success btn-sm" href="{{route('attendance.sites.edit', $site)}}">Modifier</a></td></tr>
    @empty<tr><td colspan="6">Aucun site. Créez un site puis affectez les employés et leurs horaires.</td></tr>@endforelse
    </tbody></table>{{$sites->links()}}</div>
</div></section>
@endsection
