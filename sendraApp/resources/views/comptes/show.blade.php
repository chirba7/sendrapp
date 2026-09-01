@extends('layouts.master')
@section('session')
<section class="tab-components">
    <div class="container-fluid">

        <div class="title-wrapper pt-30">
            <div class="row align-items-center">
                <div class="col-md-6">
                    <div class="title">
                        <h2 class="text-success">Modifier le Compte </h2>
                    </div>
                </div>
            </div>
            <!-- end row -->
        </div>

        <div class="title-wrapper pt-30">
            @if (session('success'))
            <div class="row alert-box success-alert">
                <div class="col-12 alert">
                    <p class="text-medium">
                        {{ session('success') }}
                    </p>
                </div>
            </div>
            @endif
            @if(count($errors) >0)
            <div class="row alert-box danger-alert">
                <div class="col-12 alert">
                    <p class="text-medium">
                        Une erreur s'est produite !!
                    </p>
                </div>
            </div>
            @endif
            <!-- end row -->
        </div>
        <div class="form-elements-wrapper">
            <div class="row">
                <div class="col-lg-12">
                    <!-- input style start -->
                    <div class="card-style mb-30">
                        <div class="white_card_body">
                            <div class="card-body">
                                <form action="{{route('modifier.compte', [$user->id])}}" method="post">
                                    @method('patch')
                                    @csrf
                                    <div class="row mb-3">
                                        <div class="col-md-6">
                                            <label class="form-label" for="inputEmail4">Prémon</label>
                                            <input type="text" class="form-control @error('premon') is-invalid @enderror" id="inputEmail4" name="prenom" value="{{ old('premon', $user->first_name) }}">
                                            @error('premon')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                            @enderror
                                        </div>
                                        <div class=" col-md-6">
                                            <label class="form-label" for="inputPassword4">Nom</label>
                                            <input type="text" class="form-control @error('nom') is-invalid @enderror" id="inputPassword4" name="nom" value="{{ old('nom', $user->last_name) }}">
                                            @error('nom')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                            @enderror
                                        </div>
                                    </div>
                                    <div class="row mb-3">
                                        <div class="col-md-6">
                                            <label class="form-label" for="inputEmail4">Role</label>
                                            <select id="inputState" class="form-control @error('role') is-invalid @enderror" name="role">
                                                <option value="1" {{ $user->role_id == 1 ? 'selected' : '' }}>Admin</option>
                                                <option value="2" {{ $user->role_id == 2 ? 'selected' : '' }}>Agent</option>
                                                <option value="3" {{ $user->role_id == 3 ? 'selected' : '' }}>Autorité</option>
                                            </select>
                                            @error('role')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                            @enderror
                                        </div>
                                        <div class=" col-md-6">
                                            <label class="form-label" for="inputPassword4">Téléphone</label>
                                            <input type="text" class="form-control @error('telephone') is-invalid @enderror" id="inputPassword4" name="telephone" value="{{ old('telephone', $user->telephone) }}">
                                            @error('telephone')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                            @enderror
                                        </div>
                                    </div>
                                    <div class="row mb-3">
                                        <div class="col-md-6">
                                            <label class="form-label" for="inputEmail4">Email</label>
                                            <input type="email" class="form-control @error('email') is-invalid @enderror" id="inputEmail4" name="email" value="{{ old('email', $user->email) }}">
                                            @error('email')
                                            <div class="invalid-feedback">{{ $message }}</div>
                                            @enderror
                                        </div>
                                    </div>
                                    <button type="submit mb-3" class="main-btn success-btn-light btn-hover">
                                        <i class="lni lni-checkmark"></i>
                                        Modifier</button>
                                </form>

                                {{-- Le champ "Mot De Passe" ci-dessus n'était relié à rien
                                     (ni validé, ni lu par modifier()) : retiré. Un Admin ne
                                     saisit plus de mot de passe en clair — il déclenche
                                     l'envoi d'un mot de passe temporaire par e-mail. --}}
                                <form action="{{ route('reset-password', [$user->id]) }}" method="post"
                                      onsubmit="return confirm('Réinitialiser le mot de passe de {{ $user->first_name }} {{ $user->last_name }} ? L\'ancien mot de passe cessera de fonctionner immédiatement, un nouveau sera envoyé à {{ $user->email ?? 'son adresse e-mail' }}.');"
                                      class="mt-3">
                                    @csrf
                                    <button type="submit" class="main-btn danger-btn-light btn-hover">
                                        <i class="lni lni-key"></i>
                                        Réinitialiser le mot de passe
                                    </button>
                                </form>
                            </div>

                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>
@endsection