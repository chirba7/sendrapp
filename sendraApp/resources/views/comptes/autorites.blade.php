@extends('layouts.master')
@section('session')
<section class="section ">
    <div class="container-fluid ">
        <!-- ========== title-wrapper start ========== -->
        <div class="title-wrapper pt-30">
            <div class="row align-items-center">
                <div class="col-md-6">
                    <div class="title">
                        <h2 class="text-success">Comptes Autorité</h2>
                    </div>
                </div>

                <div class="col-md-6 d-flex justify-content-md-end mt-3 mt-md-0">
                    @if ($archives)
                        <a href="{{ route('autorites') }}" class="main-btn light-btn btn-hover">
                            <i class="lni lni-arrow-left"></i> Comptes actifs
                        </a>
                    @else
                        <a href="{{ route('autorites', ['archives' => 1]) }}" class="main-btn light-btn btn-hover">
                            <i class="lni lni-trash-can"></i> Comptes supprimés
                        </a>
                    @endif
                </div>
            </div>
            <!-- end row -->
        </div>
        @if (session('success'))
        <div class="row alert-box success-alert">
            <div class="col-12 alert">
                <p class="text-medium">
                    {{ session('success') }}
                </p>
            </div>
        </div>
        @endif

        @if (session('error'))
        <div class="row alert-box danger-alert">
            <div class="col-12 alert">
                <p class="text-medium">
                    {{ session('error') }}
                </p>
            </div>
        </div>
        @endif

        <!-- End Row -->
        <div class="row">
            <div class="col-lg-12">
                <div class="card-style mb-30">
                    <div class="title d-flex flex-wrap align-items-center justify-content-between">
                        <div class="left">
                            <h6 class="text-medium mb-30">{{ $archives ? 'Comptes Autorité supprimés' : 'Liste des comptes Autorité' }}</h6>
                        </div>
                    </div>
                    <!-- End Title -->
                    <div class="table-responsive">
                        <table class="table top-selling-table">
                            <thead>
                                <tr>
                                    <th class="min-width">
                                        <h6 class="text-sm text-medium">
                                            Nom
                                        </h6>
                                    </th>
                                    <th class="min-width">
                                        <h6 class="text-sm text-medium">
                                            Prénom
                                        </h6>
                                    </th>
                                    <th class="min-width">
                                        <h6 class="text-sm text-medium">
                                            email
                                        </h6>
                                    </th>
                                    <th class="min-width">
                                        <h6 class="text-sm text-medium">
                                            Téléphone
                                        </h6>
                                    </th>
                                    <th>
                                        <h6 class="text-sm text-medium text-start">
                                            Role
                                        </h6>
                                    </th>
                                    <th>
                                        <h6 class="text-sm text-medium text-end">
                                            Actions
                                        </h6>
                                    </th>
                            <tbody>
                                @foreach ($users as $key => $user)
                                <tr>
                                    <td>
                                        <p class="text-sm">{{$user->first_name}}</p>
                                    </td>
                                    <td>
                                        <p class="text-sm">{{$user->last_name}}</p>
                                    </td>
                                    <td>
                                        <p class="text-sm">{{$user->email}}</p>
                                    </td>
                                    <td>
                                        <p class="text-sm">{{$user->telephone}}</p>
                                    </td>
                                    <td>
                                        <p class="text-sm">{{$user->role->nomRole}}</p>
                                    </td>
                                    <td>
                                        @include('comptes.partials.actions', ['user' => $user, 'archives' => $archives])
                                    </td>
                                </tr>
                                @endforeach
                            </tbody>
                        </table>
                        <div class="d-flex justify-content-end mt-4">
                            {!! $users->links() !!}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>
@endsection