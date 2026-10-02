@extends('layouts.master')
@section('session')
@php($statuses = ['early'=>'En avance', 'on_time'=>'À l’heure', 'late'=>'En retard'])
<section class="section"><div class="container-fluid">
    <div class="title-wrapper pt-30"><h2 class="text-success">Pointage des employés</h2></div>
    @include('attendance.nav')
    <form class="card-style mb-4" method="GET" action="{{route('attendance.index')}}"><div class="row g-3 align-items-end">
        <div class="col-md-3"><label for="date" class="form-label">Date de début du service</label><input type="date" id="date" name="date" class="form-control" value="{{$date}}" required></div>
        <div class="col-md-3"><label for="site_id" class="form-label">Site</label><select id="site_id" name="site_id" class="form-select"><option value="">Tous les sites</option>@foreach($sites as $site)<option value="{{$site->id}}" @selected(request('site_id') == $site->id)>{{$site->name}}</option>@endforeach</select></div>
        <div class="col-md-3"><label for="status" class="form-label">Statut</label><select id="status" name="status" class="form-select"><option value="">Tous les statuts</option>@foreach($statuses + ['incomplete'=>'Sans départ'] as $key => $label)<option value="{{$key}}" @selected(request('status') === $key)>{{$label}}</option>@endforeach</select></div>
        <div class="col-md-3"><button class="btn btn-success">Afficher</button></div>
    </div></form>
    <div class="card-style table-responsive"><table class="table"><thead><tr><th>Employé / site</th><th>Service prévu</th><th>Arrivée</th><th>Statut</th><th>Départ</th><th>Départ anticipé</th></tr></thead><tbody>
    @forelse($sessions as $session)
    <tr>
        <td>{{$session->user->first_name}} {{$session->user->last_name}}<br><small>{{$session->schedule_snapshot['name']}}</small></td>
        <td>{{$session->scheduled_start->setTimezone($session->timezone)->format('d/m H:i')}} – {{$session->scheduled_end->setTimezone($session->timezone)->format('d/m H:i')}}<br><small>{{$session->timezone}}</small></td>
        <td>{{$session->arrived_at->setTimezone($session->timezone)->format('d/m H:i:s')}}<br><small>Distance : {{$session->arrival_position['distance_meters']}} m</small></td>
        <td><span class="badge {{$session->arrival_status === 'late' ? 'bg-warning text-dark' : 'bg-success'}}">{{$statuses[$session->arrival_status]}}</span>@if($session->late_minutes > 0)<br><small>Écart réel : {{$session->late_minutes}} min</small>@endif</td>
        <td>@if($session->departed_at){{$session->departed_at->setTimezone($session->timezone)->format('d/m H:i:s')}}@else<span class="text-muted">Sans départ</span>@endif</td>
        <td>{{$session->early_departure_minutes ? $session->early_departure_minutes.' min' : '—'}}</td>
    </tr>
    @empty<tr><td colspan="6">Aucun pointage pour ces critères. L’absence d’un pointage ne constitue pas à elle seule une absence validée.</td></tr>@endforelse
    </tbody></table>{{$sessions->links()}}</div>
</div></section>
@endsection
