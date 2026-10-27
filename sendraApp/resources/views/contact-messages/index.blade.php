@extends('layouts.master')
@section('session')
@php
    $couleurs = ['nouveau' => 'bg-danger', 'en_cours' => 'bg-warning text-dark', 'traite' => 'bg-success'];
    $total = $compteurs->sum();
@endphp
<section class="section">
    <div class="container-fluid">
        <div class="title-wrapper pt-30 d-flex justify-content-between align-items-center flex-wrap gap-2">
            <div>
                <h2 class="text-success">Messages du site web</h2>
                <p class="text-muted mb-0">Reçus via le formulaire de la page Contact du site. Visibles par l'Admin uniquement.</p>
            </div>
        </div>

        @if (session('success'))<div class="alert alert-success">{{ session('success') }}</div>@endif

        <div class="card-style mb-3">
            <form method="GET" class="d-flex flex-wrap gap-2 align-items-center">
                <a href="{{ route('contact-messages.index', array_filter(['q' => $recherche])) }}"
                   class="btn btn-sm {{ !$statut ? 'btn-success' : 'btn-outline-success' }}">Tous ({{ $total }})</a>
                @foreach (\App\Models\ContactMessage::STATUTS as $cle => $libelle)
                    <a href="{{ route('contact-messages.index', array_filter(['statut' => $cle, 'q' => $recherche])) }}"
                       class="btn btn-sm {{ $statut === $cle ? 'btn-success' : 'btn-outline-success' }}">{{ $libelle }} ({{ $compteurs[$cle] ?? 0 }})</a>
                @endforeach
                @if ($statut)<input type="hidden" name="statut" value="{{ $statut }}">@endif
                <input type="search" name="q" value="{{ $recherche }}" class="form-control form-control-sm ms-auto" style="max-width: 260px" placeholder="Nom, e-mail, objet, texte…">
                <button class="btn btn-sm btn-outline-secondary">Rechercher</button>
            </form>
        </div>

        <div class="card-style">
            <div class="table-responsive">
                <table class="table align-middle">
                    <thead>
                        <tr><th>Reçu le</th><th>Expéditeur</th><th>Objet</th><th>Statut</th><th></th></tr>
                    </thead>
                    <tbody>
                    @forelse ($messages as $m)
                        <tr @class(['fw-semibold' => !$m->lu_le])>
                            <td class="text-nowrap">{{ $m->created_at->format('d/m/Y H:i') }}</td>
                            <td>
                                {{ $m->nom }}<br>
                                <small class="text-muted">{{ $m->email }}@if ($m->telephone) · {{ $m->telephone }}@endif</small>
                            </td>
                            <td>
                                {{ $m->objet ?: '—' }}<br>
                                <small class="text-muted">{{ \Illuminate\Support\Str::limit($m->message, 90) }}</small>
                            </td>
                            <td><span class="badge {{ $couleurs[$m->statut] ?? 'bg-secondary' }}">{{ $m->statut_libelle }}</span></td>
                            <td class="text-end"><a class="btn btn-outline-success btn-sm" href="{{ route('contact-messages.show', $m) }}">Ouvrir</a></td>
                        </tr>
                    @empty
                        <tr><td colspan="5">Aucun message.</td></tr>
                    @endforelse
                    </tbody>
                </table>
            </div>
            {{ $messages->links() }}
        </div>
    </div>
</section>
@endsection
