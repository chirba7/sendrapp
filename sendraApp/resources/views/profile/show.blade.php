@extends('layouts.master')
@section('session')

<section class="section ">
    <div class="container-fluid ">
        <div class="title-wrapper pt-30">
            <div class="row align-items-center">
                <div class="col-md-12">
                    <div class="title">
                        <h2 class="text-success">Profil</h2>
                    </div>
                </div>
                <div class="col-md-12">
                    @if (session('success')) <div class="alert-box success-alert pl-100">
                        <div class="alert">
                            <p class="text-medium">
                                {{ session('success') }}
                            </p>
                        </div>
                    </div>
                    @endif
                </div>
            </div>
        </div>

        <!-- End Row -->
        <div class="row">
            <div class="col-lg-6">
                <div class="card-style mb-30">
                    <div class="white_card_header">
                        <div class="box_header m-0">
                            <div class="main-title">
                                <h2 class="m-0">Informations sur le profil</h2>
                            </div>
                        </div>
                    </div>

                    <p>Mettez à jour les informations de profil et l'adresse e-mail de votre compte.</p>
                    <div class="white_card_body mt-4">
                        <form action="{{route('update.profil')}}" method="post">
                            @method('patch')
                            @csrf
                            <div class="mb-3">
                                <label class="form-label" for="exampleInputPassword1">Nom</label>
                                <input type="text" name="first_name" class="form-control" id="exampleInputPassword1" value="{{ old('first_name', Auth::user()->first_name) }}" readonly>
                                @error('first_name')
                                <div class="text-danger">{{ $message }}</div>
                                @enderror
                            </div>

                            <div class="mb-3">
                                <label class="form-label" for="exampleInputPassword1">Prénom</label>
                                <input type="text" name="last_name" class="form-control" id="exampleInputPassword1" value="{{ old('last_name', Auth::user()->last_name) }}" readonly>
                                @error('last_name')
                                <div class="text-danger">{{ $message }}</div>
                                @enderror
                            </div>

                            <div class="mb-3">
                                <label class="form-label" for="exampleInputEmail1">Adresse Email</label>
                                <input type="email" name="email" class="form-control" id="exampleInputEmail1" aria-describedby="emailHelp" value="{{ old('email', Auth::user()->email) }}" readonly>
                                @error('email')
                                <div class="text-danger">{{ $message }}</div>
                                @enderror
                            </div>
                            <!-- 
                            <button type="submit" class="main-btn success-btn btn-hover">
                                <i class="lni lni-checkmark"></i>
                                Valider</button> -->
                        </form>
                    </div>
                </div>
            </div>
            <div class="col-lg-6">
                <div class="card-style mb-30">

                    <div class="white_card_header">
                        <div class="box_header m-0">
                            <div class="main-title">
                                <h2 class="m-0">Mettre à jour le mot de passe</h2>
                            </div>
                        </div>
                    </div>
                    <p>Assurez-vous que votre compte utilise un mot de passe long et aléatoire pour rester en sécurité.</p>
                    <div class="white_card_body mt-4">
                        <form action="{{route('update.pass')}}" method="post">
                            @csrf
                            @method('patch')
                            <div class="mb-3">
                                <label for="current_password" class="form-label">Mot de passe actuel</label>
                                <input type="password" name="current_password" class="form-control" id="current_password" placeholder="Mot de passe actuel">
                                @error('current_password')
                                <div class="text-danger">{{ $message }}</div>
                                @enderror
                            </div>
                            <div class="mb-3">
                                <label for="new_password" class="form-label">Nouveau mot de passe</label>
                                <input type="password" name="password" class="form-control" id="new_password" placeholder="Nouveau mot de passe">
                                @error('password')
                                <div class="text-danger">{{ $message }}</div>
                                @enderror
                            </div>
                            <div class="mb-3">
                                <label for="password_confirmation" class="form-label">Confirmez le mot de passe</label>
                                <input type="password" name="password_confirmation" class="form-control" id="password_confirmation" placeholder="Confirmez le mot de passe">
                                @error('password_confirmation')
                                <div class="text-danger">{{ $message }}</div>
                                @enderror
                            </div>
                            <div class=" row">
                                <div class="col-sm-10">
                                    <button type="submit" class="main-btn success-btn btn-hover">
                                        <i class="lni lni-checkmark"></i>
                                        Valider</button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>
@endsection