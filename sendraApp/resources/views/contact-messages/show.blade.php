@extends('layouts.master')
@section('session')
<section class="section">
    <div class="container-fluid">
        <div class="title-wrapper pt-30 d-flex justify-content-between align-items-center flex-wrap gap-2">
            <div>
                <h2 class="text-success">{{ $msg->objet ?: 'Message sans objet' }}</h2>
                <p class="text-muted mb-0">Reçu le {{ $msg->created_at->format('d/m/Y à H:i') }} via le site web</p>
            </div>
            <a class="main-btn light-btn" href="{{ route('contact-messages.index') }}">← Retour aux messages</a>
        </div>

        @if (session('success'))<div class="alert alert-success">{{ session('success') }}</div>@endif

        <div class="row g-3">
            <div class="col-lg-8">
                <div class="card-style h-100">
                    <p class="mb-1"><strong>{{ $msg->nom }}</strong></p>
                    <p class="mb-1"><a href="mailto:{{ $msg->email }}">{{ $msg->email }}</a></p>
                    @if ($msg->telephone)<p class="mb-1"><a href="tel:{{ preg_replace('/[^0-9+]/', '', $msg->telephone) }}">{{ $msg->telephone }}</a></p>@endif
                    <hr>
                    <div style="white-space: pre-line">{{ $msg->message }}</div>
                    <hr>
                    <a class="btn btn-success btn-sm"
                       href="mailto:{{ $msg->email }}?subject={{ rawurlencode('Re : ' . ($msg->objet ?: 'Votre message à SENDRA')) }}">Répondre par e-mail</a>
                </div>
            </div>
            <div class="col-lg-4">
                <div class="card-style">
                    <h6 class="mb-3">Traitement</h6>
                    <form method="POST" action="{{ route('contact-messages.update', $msg) }}">
                        @csrf
                        @method('PATCH')
                        <label class="form-label" for="statut">Statut</label>
                        <select id="statut" name="statut" class="form-select mb-3">
                            @foreach (\App\Models\ContactMessage::STATUTS as $cle => $libelle)
                                <option value="{{ $cle }}" @selected(old('statut', $msg->statut) === $cle)>{{ $libelle }}</option>
                            @endforeach
                        </select>
                        <label class="form-label" for="note_interne">Note interne</label>
                        <textarea id="note_interne" name="note_interne" rows="5" class="form-control mb-3" placeholder="Suite donnée, personne contactée…">{{ old('note_interne', $msg->note_interne) }}</textarea>
                        @error('statut')<div class="text-danger small mb-2">{{ $message }}</div>@enderror
                        @error('note_interne')<div class="text-danger small mb-2">{{ $message }}</div>@enderror
                        <button class="main-btn success-btn w-100">Enregistrer</button>
                    </form>
                    @if ($msg->traite_le)
                        <p class="text-muted small mt-3 mb-0">Traité le {{ $msg->traite_le->format('d/m/Y à H:i') }}@if ($msg->traitePar) par {{ trim($msg->traitePar->first_name . ' ' . $msg->traitePar->last_name) }}@endif</p>
                    @endif
                </div>
            </div>
        </div>
    </div>
</section>
@endsection
