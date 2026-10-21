@extends('layouts.master')
@section('session')
<section class="section ">
    <div class="container-fluid ">
        <!-- ========== title-wrapper start ========== -->
        <div class="title-wrapper pt-30">
            <div class="row align-items-center">
                <div class="col-md-6">
                    <div class="title tesu">
                        <h2 class="text-success">@if(Auth::user()->role_id == 1)Administration @elseif(Auth::user()->role_id == 3) Autorité communale @elseif(Auth::user()->role_id == 4) Autorité préfectorale @elseif(Auth::user()->role_id == 7) Espace Opérateur @else Espace Agent @endif</h2>
                        <p class="text-muted mb-0">{{ Auth::user()->role->nomRole }} · Bonjour {{ Auth::user()->first_name }}</p>
                    </div>
                </div>
            </div>
            <!-- end row -->
        </div>
        @if(in_array(Auth::user()->role_id, [1, 3, 4]))
        <div class="card-style mb-30" style="border-left:5px solid {{ Auth::user()->role_id == 4 ? '#7b4bb7' : '#198754' }}">
            <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
                <div><h5>Décisions à prendre</h5><p class="mb-0">{{ $approbationsEnAttente }} signalement(s) transmis pour approbation.</p></div>
                <a href="{{ route('approbations.index') }}" class="main-btn success-btn btn-hover">Ouvrir la file d’approbation</a>
            </div>
        </div>
        @elseif(Auth::user()->role_id == 2)
        <div class="card-style mb-30" style="border-left:5px solid #0d6efd">
            <h5>Suivi des signalements</h5><p class="mb-0">Consultez les dossiers et leurs constatations depuis le menu Signalements.</p>
        </div>
        @endif
        <!-- ========== title-wrapper end ========== -->
        <div class="row">
            <div class="col-xl-3 col-lg-4 col-sm-6">
                <div class="icon-card mb-30">
                    <div class="icon ">
                        <i class="lni lni-car"></i>
                    </div>
                    <div class="content">
                        <h6 class="mb-10">Signalements</h6>
                        <h3 class="text-bold mb-10">{{$signalements}}</h3>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-lg-4 col-sm-6">
                <div class="icon-card mb-30">
                    <div class="icon red">
                        <i class="lni lni-car"></i>
                    </div>
                    <div class="content">
                        <h6 class="mb-10">Pas résolus</h6>
                        <h3 class="text-bold mb-10">{{$signales}}</h3>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-lg-4 col-sm-6">
                <div class="icon-card mb-30">
                    <div class="icon orange">
                        <i class="lni lni-car"></i>
                    </div>
                    <div class="content">
                        <h6 class="mb-10">En cours</h6>
                        <h3 class="text-bold mb-10">{{$encours}}</h3>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-lg-4 col-sm-6">
                <div class="icon-card mb-30">
                    <div class="icon success ">
                        <i class="lni lni-car"></i>
                    </div>
                    <div class="content">
                        <h6 class="mb-10">Enlévements</h6>
                        <h3 class="text-bold mb-10">{{$enleves}}</h3>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-lg-4 col-sm-6">
                <a href="{{ route('non_resolus') }}" class="text-decoration-none text-dark"><div class="icon-card mb-30">
                    <div class="icon orange"><i class="lni lni-warning"></i></div>
                    <div class="content"><h6 class="mb-10">Non résolus</h6><h3 class="text-bold mb-10">{{ $nonResolus }}</h3></div>
                </div></a>
            </div>
        </div>


        <div class="row">
            <div class="col-lg-12">
                <div class="card-style mb-30">
                    <div class="title d-flex flex-wrap align-items-center justify-content-between">
                        <div class="left">
                            <h6 class="text-medium mb-30">Liste des signalements</h6>
                        </div>
                    </div>
                    <!-- End Title -->
                    <div class="table-responsive">
                        <table class="table top-selling-table">
                            <thead>
                                <tr>
                                    <th class="min-width">
                                        <h6 class="text-sm text-medium">
                                            Image
                                        </h6>
                                    </th>
                                    <th class="min-width">
                                        <h6 class="text-sm text-medium">
                                            Titre
                                        </h6>
                                    </th>
                                    <th class="min-width">
                                        <h6 class="text-sm text-medium">
                                            Secteur
                                        </h6>
                                    </th>
                                    <th class="min-width">
                                        <h6 class="text-sm text-medium">
                                            Date Signalement
                                        </h6>
                                    </th>
                                    <th>
                                        <h6 class="text-sm text-medium text-start">
                                            Etat
                                        </h6>
                                    </th>
                                    <th>
                                        <h6 class="text-sm text-medium text-end">
                                            Constatation
                                        </h6>
                                    </th>
                            <tbody>
                                @foreach ($signalement as $key => $signalement)
                                <tr>
                                    <td>
                                        <div class="employee-image">
                                            {{-- Correction (même bug qu'API-H-1) : photo peut être une collection vide --}}
                                            <img src="{{ $signalement->photo->isNotEmpty() ? config('services.backend.storage_url') . '/' . $signalement->photo[0]->filepath : '' }}" alt="" />
                                        </div>
                                    </td>
                                    <td>
                                        <p class="text-sm">{{$signalement->title}}</p>
                                    </td>
                                    <td>
                                        <p class="text-sm">{{$signalement->commune}}</p>
                                    </td>
                                    <td>
                                        <p class="text-sm">{{$signalement->created_at->format('d F Y \à H\hi')}}</p>
                                    </td>
                                    @if (in_array($signalement->etat, ['SIGNALE', 'EN COURS']) && $signalement->non_removed_at)
                                    <td><span class="status-btn warning-btn">NON RÉSOLU</span></td>
                                    @elseif ($signalement->etat == "SIGNALE")
                                    <td>
                                        <span class="status-btn close-btn">{{$signalement->etat}}</span>
                                    </td>
                                    @elseif ($signalement->etat == "EN COURS")
                                    <td>
                                        <span class="status-btn warning-btn">{{$signalement->etat}}</span>
                                    </td>
                                    @elseif ($signalement->etat == "ENLEVE")
                                    <td>
                                        <span class="status-btn success-btn">{{$signalement->etat}}</span>
                                    </td>
                                    @else
                                    <td><span class="status-btn">{{ $signalement->etat }}</span></td>
                                    @endif
                                    <td>
                                        <div class="action justify-content-center">
                                            <a href="{{route('details', [$signalement->id])}}" class="edit text-success ">
                                                <i class="lni lni-eye"></i>
                                            </a>
                                        </div>
                                    </td>
                                </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <!-- end container -->
</section>
@endsection
