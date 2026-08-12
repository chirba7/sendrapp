@extends('layouts.master')
@section('session')
<section class="section ">
    <div class="container-fluid ">
        <!-- ========== title-wrapper start ========== -->
        <div class="title-wrapper pt-30">
            <div class="row align-items-center">
                <div class="col-md-6">
                    <div class="title">
                        <h2 class="text-success">Comptes Admin</h2>
                    </div>
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

        <!-- End Row -->
        <div class="row">
            <div class="col-lg-12">
                <div class="card-style mb-30">
                    <div class="title d-flex flex-wrap align-items-center justify-content-between">
                        <div class="left">
                            <h6 class="text-medium mb-30">Liste des comptes Admin</h6>
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
                                            Modifier
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
                                        <div class="action d-flex justify-content-end">
                                            <a href="{{route('modifier', [$user->id])}}" class="edit text-success ">
                                                <i class="lni lni-pencil"></i>
                                            </a>
                                        </div>
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