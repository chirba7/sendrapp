@extends('layouts.base')
@section('contenu')
<section class="signin-section">
    <div class="container mt-5">
        <div class="row g-0 auth-row">
            <div class="col-lg-6">
                <div class="auth-cover-wrapper bg-success-100">
                    <div class="auth-cover">
                        <div class="title text-center">
                            <h1 class="text-success mb-10">Bienvenue, {{Auth::user()->first_name}}</h1>
                            <p class="text-medium">
                                Nous sommes ravis de vous avoir parmi nous. Pour tirer le meilleur parti de la plateform, Choisissez un nouveau mot de passe pour des raisons de sécurité :
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
                            <img src="{{asset('img/logoSendra.png')}}" alt="">
                        </div>
                        <h2 class="mb-25 text-center">Modifier votre mot de passe</h2>
                        <form method="POST" action="{{ route('motDePasse') }}">
                            @csrf
                            @method('PATCH')
                            <div class="row">
                                <div class="col-12">
                                    <div class="input-style-1">
                                        <label>Mot de passe</label>
                                        <input type="password" name="password" class="form-control" placeholder="Entre votre mot de passe">
                                        @error('password')
                                        <span class="text-danger">{{ $message }}</span>
                                        @enderror
                                    </div>
                                </div>
                                <div class="col-12">
                                    <div class="input-style-1">
                                        <label>Confirmation Mot de passe</label>
                                        <input type="password" name="password_confirmation" class="form-control" placeholder="Confirmer votre mot de passe">
                                        @error('password_confirmation')
                                        <span class="text-danger">{{ $message }}</span>
                                        @enderror
                                    </div>
                                </div>
                                <!-- end col -->

                                <!-- end col -->
                                <div class="col-12">
                                    <div class="button-group d-flex justify-content-center flex-wrap">
                                        <button class="main-btn success-btn btn-hover w-100 text-center">
                                            VALIDER
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