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
                        {{-- Le logo n'apparaît plus ici : il est déjà présent, en
                             grand, au-dessus du formulaire à droite. --}}
                        <h1 class="auth-title">Bienvenue</h1>
                        <p class="auth-subtitle">
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
                                    {{-- Bouton œil : vérifier ce qu'on a tapé avant de valider. --}}
                                    <div style="position:relative">
                                        <input type="password" id="motDePasse" name="password" class="form-control" placeholder="Votre mot de passe" autocomplete="current-password" style="padding-right:52px">
                                        <button type="button" id="basculerMotDePasse" aria-label="Afficher le mot de passe" title="Afficher le mot de passe"
                                                style="position:absolute;top:50%;right:8px;transform:translateY(-50%);border:0;background:transparent;padding:8px;line-height:0;color:#6b7c72;cursor:pointer">
                                            <svg class="oeil-ouvert" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                                            <svg class="oeil-barre" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="display:none"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><path d="M14.12 14.12a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                                        </button>
                                    </div>
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
<script>
    (function () {
        var champ = document.getElementById('motDePasse');
        var bouton = document.getElementById('basculerMotDePasse');
        if (!champ || !bouton) return;
        bouton.addEventListener('click', function () {
            var visible = champ.type === 'password';
            champ.type = visible ? 'text' : 'password';
            bouton.querySelector('.oeil-ouvert').style.display = visible ? 'none' : '';
            bouton.querySelector('.oeil-barre').style.display = visible ? '' : 'none';
            var libelle = visible ? 'Masquer le mot de passe' : 'Afficher le mot de passe';
            bouton.setAttribute('aria-label', libelle);
            bouton.title = libelle;
            champ.focus();
        });
    })();
</script>
@endsection