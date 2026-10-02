<nav class="d-flex flex-wrap gap-2 my-3" aria-label="Gestion du pointage">
    <a class="btn {{request()->routeIs('attendance.index') ? 'btn-success' : 'btn-outline-success'}}" href="{{route('attendance.index')}}">Présences</a>
    <a class="btn {{request()->routeIs('attendance.sites*') ? 'btn-success' : 'btn-outline-success'}}" href="{{route('attendance.sites')}}">Sites de pointage</a>
    <a class="btn {{request()->routeIs('attendance.assignments*') ? 'btn-success' : 'btn-outline-success'}}" href="{{route('attendance.assignments')}}">Horaires et affectations</a>
</nav>
@if(session('success'))<div class="alert alert-success" role="status">{{session('success')}}</div>@endif
@if($errors->any())<div class="alert alert-danger" role="alert"><ul class="mb-0">@foreach($errors->all() as $error)<li>{{$error}}</li>@endforeach</ul></div>@endif
