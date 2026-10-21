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
                        <span class="auth-logo"><img src="{{asset('img/EPAVIE.png')}}" alt="epaVie" height="70"></span>
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
                                    <label>E-mail</label>
                                    {{-- La connexion au back-office se fait par e-mail
                                         (config/fortify.php : 'username' => 'email'). Le
                                         libellé « Téléphone » posé par une correction
                                         antérieure faisait saisir un numéro, d'où des
                                         « identifiants incorrects » incompréhensibles. --}}
                                    <input type="email" name="email" value="{{ old('email') }}" class="form-control" placeholder="votre@email.sn" autocomplete="username" autofocus>
                                    @error('email')
                                    <div class="text-danger">{{ $message }}</div>
                                    @enderror
                                </div>
                            </div>
                            <!-- end col -->
                            <div class="col-12">
                                <div class="input-style-1">
                                    <label>Mot de passe</label>
                                    <input type="password" name="password" class="form-control" placeholder="Votre mot de passe" autocomplete="current-password">
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