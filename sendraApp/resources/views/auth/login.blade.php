@extends('layouts.base')
@section('contenu')
<section class="signin-section">
    <div class="container mt-5">
        <div class="title-wrapper pt-30">
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
    <div class="row g-0 auth-row">
        <div class="col-lg-6">
            <div class="auth-cover-wrapper bg-success-100">
                <div class="auth-cover">
                    <div class="title text-center">
                        <h1 class="text-success mb-10">Bienvenue</h1>
                        <p class="text-medium">
                            Connectez-vous à votre compte existant pour continuer.
                        </p>
                    </div>

                </div>
            </div>
        </div>
        <!-- end col -->
        <div class="col-lg-6">
            <div class="signin-wrapper">
                <div class="form-wrapper ">
                    <div class="shape-image mb-25 d-flex justify-content-center flex-wrap">
                        <img src="{{asset('img/EPAVIE.png')}}" alt="" width="50%" height="50%">
                    </div>
                    <h2 class="mb-25 text-center">Connexion</h2>
                    <form method="POST" action="{{ route('login') }}">
                        @csrf
                        <div class="row">
                            <div class="col-12">
                                <div class="input-style-1">
                                    <label>Téléphone</label>
                                    {{-- Correction : type="email" déclenchait la validation
                                         native du navigateur (exige un "@"), alors que la
                                         connexion se fait avec un numéro de téléphone, pas
                                         une adresse e-mail (le nom de champ "email" reste
                                         côté serveur pour Fortify, mais n'est ici qu'un
                                         identifiant texte). --}}
                                    <input type="text" inputmode="tel" name="email" :value="old('email')" class="form-control" placeholder="Numéro de téléphone">
                                    @error('email')
                                    <div class="text-danger">{{ $message }}</div>
                                    @enderror
                                </div>
                            </div>
                            <!-- end col -->
                            <div class="col-12">
                                <div class="input-style-1">
                                    <label>Mot de passe</label>
                                    <input type="password" name="password" class="form-control" placeholder="Password">
                                    @error('password')
                                    <div class="text-danger">{{ $message }}</div>
                                    @enderror
                                </div>
                            </div>
                            <!-- end col -->

                            <!-- end col -->
                            <div class="col-12">
                                <div class="button-group d-flex justify-content-center flex-wrap">
                                    <button class="main-btn success-btn btn-hover w-100 text-center">
                                        Connexion
                                    </button>
                                </div>
                            </div>
                        </div>
                        <!-- end row -->
                    </form>

                </div>
            </div>
        </div>
        <!-- end col -->
    </div>
    <!-- end row -->
    </div>
</section>
@endsection