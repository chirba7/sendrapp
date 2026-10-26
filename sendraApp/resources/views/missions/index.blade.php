@extends('layouts.master')
@section('session')
<section class="section">
    <div class="container-fluid">
        <div class="title-wrapper pt-30">
            <div class="row align-items-center">
                <div class="col-md-6"><h2 class="text-success">Historique des missions</h2><p class="text-muted mb-0">Missions ouvertes et terminées, avec leur état.</p></div>
                <div class="col-md-6 text-md-end mt-3 mt-md-0">
                    <a href="{{ route('missions.create') }}" class="main-btn success-btn btn-hover">
                        <i class="lni lni-plus"></i> Créer une mission
                    </a>
                </div>
            </div>
        </div>

        @if (session('success'))
            <div class="alert alert-success">{{ session('success') }}</div>
        @endif
        @if (session('error'))
            <div class="alert alert-danger">{{ session('error') }}</div>
        @endif

        @php
            $etats = [
                'brouillon' => ['Brouillon', 'secondary'], 'planifiee' => ['Planifiée', 'primary'],
                'en_cours' => ['En cours', 'warning text-dark'], 'en_reception' => ['En réception', 'info text-dark'],
                'terminee' => ['Terminée', 'success'], 'annulee' => ['Annulée', 'danger'],
            ];
        @endphp
        <div class="d-flex flex-wrap gap-2 mb-3">
            @foreach (['toutes' => 'Toutes', 'ouvertes' => 'Ouvertes', 'terminees' => 'Terminées'] as $cle => $libelle)
                <a href="{{ route('missions.index', ['etat' => $cle]) }}" class="btn {{ $etat === $cle ? 'btn-success' : 'btn-outline-success' }}">
                    {{ $libelle }} <span class="badge {{ $etat === $cle ? 'bg-light text-dark' : 'bg-success' }} ms-1">{{ $compteurs[$cle] }}</span>
                </a>
            @endforeach
        </div>

        <div class="card-style mb-30">
            <div class="table-responsive">
                <table class="table align-middle">
                    <thead><tr>
                        <th>Mission</th><th>État</th><th>Date</th><th>Commune</th><th>Équipe</th><th>Véhicules</th><th></th>
                    </tr></thead>
                    <tbody>
                    @forelse ($missions as $mission)
                        <tr>
                            <td>
                                <strong>{{ $mission->code ?: $mission->title }}</strong><br><small>{{ $mission->title }}</small><br>
                                <span class="badge {{ $mission->type === 'programmee' ? 'bg-success' : 'bg-warning text-dark' }}">
                                    {{ $mission->type === 'programmee' ? 'Programmée' : 'Ponctuelle' }}
                                </span>
                            </td>
                            @php
                                $e = $etats[$mission->status] ?? [$mission->status, 'secondary'];
                                $nbRecus = $mission->removals->filter(fn ($r) => $r->reception)->count();
                            @endphp
                            <td>
                                <span class="badge bg-{{ $e[1] }}">{{ $e[0] }}</span><br>
                                <small class="text-muted">
                                    @if ($mission->status === 'terminee')
                                        Terminée le {{ $mission->completed_at?->format('d/m/Y') ?: '—' }}
                                    @elseif ($mission->status === 'annulee')
                                        Annulée
                                    @else
                                        Non terminée
                                        @if ($mission->removal_validated_at) · enlèvement validé @endif
                                    @endif
                                </small>
                            </td>
                            <td>{{ $mission->scheduled_at?->format('d/m/Y H:i') ?: '—' }}</td>
                            <td>{{ $mission->commune?->nomCommune ?: '—' }}</td>
                            <td>
                                {{ $mission->agents->count() ?: 'Tous' }} sur le terrain
                                <small class="d-block text-muted">{{ $mission->agents->filter(fn ($agent) => $agent->pivot->checked_in_at)->count() }} pointé(s)</small>
                                <small class="d-block text-muted">Réception : {{ trim(($mission->receptionAgent?->first_name ?? '').' '.($mission->receptionAgent?->last_name ?? '')) ?: '—' }}</small>
                            </td>
                            <td>
                                {{ $mission->vehicles->count() }} ciblé(s)
                                <small class="d-block text-muted">{{ $mission->removals->count() }} enlevé(s) · {{ $nbRecus }} en fourrière</small>
                            </td>
                            <td class="text-end">
                                <a class="btn btn-sm btn-outline-success" href="{{route('missions.show',$mission)}}">Détails</a>
                                <a class="btn btn-sm btn-outline-secondary" href="{{route('missions.edit',$mission)}}">Modifier</a>
                                <form class="d-inline" action="{{ route('missions.destroy', $mission) }}" method="POST" onsubmit="return confirm('Supprimer cette mission ?')">
                                    @csrf @method('DELETE')
                                    <button class="btn btn-sm btn-outline-danger" type="submit">Supprimer</button>
                                </form>
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="7" class="text-center py-5">Aucune mission dans ce filtre.</td></tr>
                    @endforelse
                    </tbody>
                </table>
            </div>
            <div class="d-flex justify-content-end mt-4">{{ $missions->appends(['etat' => $etat])->links() }}</div>
        </div>
    </div>
</section>
@endsection
