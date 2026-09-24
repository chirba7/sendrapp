@extends('layouts.master')
@section('session')
<section class="section"><div class="container-fluid"><div class="title-wrapper pt-30 d-flex justify-content-between"><div><h2 class="text-success">{{$pound->name}}</h2><p>{{$pound->department}}</p></div><a class="main-btn success-btn" href="{{route('pounds.edit',$pound)}}">Modifier</a></div><div class="card-style"><p><strong>Coordonnées :</strong> {{$pound->latitude}}, {{$pound->longitude}}</p><p><strong>Marge de pointage :</strong> 500 m</p><p><strong>Missions :</strong> {{$pound->missions_count}}</p></div></div></section>
@endsection
