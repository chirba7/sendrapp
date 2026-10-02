@extends('layouts.master')
@section('session')
@php($days = [1=>'Lundi', 2=>'Mardi', 3=>'Mercredi', 4=>'Jeudi', 5=>'Vendredi', 6=>'Samedi', 7=>'Dimanche'])
<section class="section"><div class="container-fluid">
    <div class="title-wrapper pt-30"><h2 class="text-success">Horaires et affectations</h2></div>
    @include('attendance.nav')
    <div class="card-style mb-4 table-responsive"><h3 class="mb-3">Inscriptions depuis l’application Pointage</h3>
        <p>Seuls les comptes validés et actifs apparaissent dans la liste des employés à affecter.</p>
        <table class="table"><thead><tr><th>Employé</th><th>Téléphone</th><th>Inscrit le</th><th>État</th><th>Appareil</th><th>Action</th></tr></thead><tbody>
        @forelse($enrollments as $enrollment)
            @php($hasDevice = \Illuminate\Support\Facades\DB::table('attendance_devices')->where('user_id', $enrollment->user_id)->exists())
            <tr><td>{{$enrollment->user->first_name}} {{$enrollment->user->last_name}}</td><td>{{$enrollment->user->telephone}}</td><td>{{$enrollment->created_at->timezone('Africa/Dakar')->format('d/m/Y H:i')}}</td><td>{{['pending'=>'En attente', 'approved'=>'Validé', 'disabled'=>'Désactivé'][$enrollment->status] ?? $enrollment->status}}</td><td>{{$hasDevice ? 'Lié' : 'À lier'}}</td><td class="d-flex gap-2">
                @if($enrollment->status !== 'approved' && !$enrollment->user->deleted)<form method="POST" action="{{route('attendance.enrollments.approve', $enrollment)}}">@csrf @method('PATCH')<label class="small d-block"><input type="checkbox" name="identity_checked" value="1" required> Identité vérifiée en personne</label><button class="btn btn-success btn-sm">Valider</button></form>@endif
                @if(($hasDevice || $enrollment->status === 'approved') && !$enrollment->user->deleted)<form method="POST" action="{{route('attendance.enrollments.reset-device', $enrollment)}}" onsubmit="return confirm('Suspendre le pointage et autoriser un nouveau téléphone ?')">@csrf @method('PATCH')<button class="btn btn-outline-warning btn-sm">Changer de téléphone</button></form>@endif
                @if($enrollment->status !== 'disabled')<form method="POST" action="{{route('attendance.enrollments.disable', $enrollment)}}">@csrf @method('PATCH')<button class="btn btn-outline-danger btn-sm">Désactiver</button></form>@endif
                @if($enrollment->user->role?->nomRole === 'Employe pointage')
                    <form method="POST" action="{{route('attendance.enrollments.destroy', $enrollment)}}" onsubmit="return confirm('Supprimer ce compte Pointage ? Il ne pourra plus se connecter. Son historique de pointage sera conservé.')">@csrf @method('DELETE')<button class="btn btn-danger btn-sm">Supprimer le compte</button></form>
                @endif
            </td></tr>
        @empty<tr><td colspan="6">Aucune inscription depuis l’application Pointage.</td></tr>@endforelse
        </tbody></table>{{$enrollments->links()}}
    </div>
    <form class="card-style mb-4" method="POST" action="{{route('attendance.assignments.store')}}">
        @csrf
        <h3 class="mb-3">Affecter un employé ou remplacer son planning</h3>
        <p class="mb-3">Un site et un planning hebdomadaire par employé. Une fin antérieure au début correspond à un service de nuit, terminé le lendemain. Les jours cochés sont les jours de début du service.</p>
        <div class="row g-3">
            <div class="col-md-6"><label for="user_id" class="form-label">Employé inscrit et validé depuis Pointage</label><select id="user_id" name="user_id" class="form-select" required><option value="">Choisir un employé</option>@foreach($employees as $employee)<option value="{{$employee->id}}" @selected(old('user_id') == $employee->id)>{{$employee->first_name}} {{$employee->last_name}} — {{$employee->telephone}}</option>@endforeach</select></div>
            <div class="col-md-6"><label for="attendance_site_id" class="form-label">Site actif</label><select id="attendance_site_id" name="attendance_site_id" class="form-select" required><option value="">Choisir un site</option>@foreach($sites as $site)<option value="{{$site->id}}" @selected(old('attendance_site_id') == $site->id)>{{$site->name}}</option>@endforeach</select></div>
            <div class="col-md-4"><label for="starts_at" class="form-label">Début du travail</label><input type="time" id="starts_at" name="starts_at" class="form-control" value="{{old('starts_at', '08:00')}}" required></div>
            <div class="col-md-4"><label for="ends_at" class="form-label">Fin du travail</label><input type="time" id="ends_at" name="ends_at" class="form-control" value="{{old('ends_at', '17:00')}}" required></div>
            <div class="col-md-4"><label for="late_tolerance_minutes" class="form-label">Tolérance de retard (minutes)</label><input type="number" min="0" max="120" id="late_tolerance_minutes" name="late_tolerance_minutes" class="form-control" value="{{old('late_tolerance_minutes', 5)}}" required></div>
            <fieldset class="col-12"><legend class="fs-6">Jours travaillés</legend>@foreach($days as $number => $label)<label class="me-3"><input type="checkbox" name="weekdays[]" value="{{$number}}" @checked(in_array($number, old('weekdays', [1,2,3,4,5])))> {{$label}}</label>@endforeach</fieldset>
            <div class="col-12 text-end"><button class="btn btn-success" @disabled($employees->isEmpty() || $sites->isEmpty())>Enregistrer le planning</button></div>
        </div>
        @if($sites->isEmpty())<p class="text-muted">Créez d’abord un site de pointage actif.</p>@endif
    </form>
    <div class="card-style table-responsive"><table class="table"><thead><tr><th>Employé</th><th>Site</th><th>Jours</th><th>Horaires</th><th>Tolérance</th><th>État</th><th>Action</th></tr></thead><tbody>
    @forelse($assignments as $assignment)
        <tr><td>{{$assignment->user->first_name}} {{$assignment->user->last_name}}</td><td>{{$assignment->site->name}}</td><td>{{collect($assignment->weekdays)->map(fn ($day) => $days[$day])->join(', ')}}</td><td>{{substr($assignment->starts_at, 0, 5)}} – {{substr($assignment->ends_at, 0, 5)}}<br><small>{{$assignment->site->timezone}}</small></td><td>{{$assignment->late_tolerance_minutes}} min</td><td>{{$assignment->active ? 'Active' : 'Désactivée'}}</td><td>@if($assignment->active)<form method="POST" action="{{route('attendance.assignments.disable', $assignment)}}">@csrf @method('PATCH')<button class="btn btn-outline-danger btn-sm">Désactiver</button></form>@endif</td></tr>
    @empty<tr><td colspan="7">Aucun employé affecté.</td></tr>@endforelse
    </tbody></table>{{$assignments->links()}}</div>
</div></section>
@endsection
