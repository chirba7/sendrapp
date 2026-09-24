@extends('layouts.master')
@section('session')
<section class="section"><div class="container-fluid"><div class="title-wrapper pt-30 d-flex justify-content-between"><h2 class="text-success">Fourrières</h2><a class="main-btn success-btn" href="{{route('pounds.create')}}">Créer une fourrière</a></div>
@if(session('success'))<div class="alert alert-success">{{session('success')}}</div>@endif
<div class="card-style"><div class="table-responsive"><table class="table"><thead><tr><th>Nom</th><th>Département</th><th>Missions</th><th></th></tr></thead><tbody>@forelse($pounds as $pound)<tr><td>{{$pound->name}}</td><td>{{$pound->department?:'—'}}</td><td>{{$pound->missions_count}}</td><td class="text-end"><a class="btn btn-outline-success btn-sm" href="{{route('pounds.show',$pound)}}">Voir</a></td></tr>@empty<tr><td colspan="4">Aucune fourrière.</td></tr>@endforelse</tbody></table></div>{{$pounds->links()}}</div></div></section>
@endsection
