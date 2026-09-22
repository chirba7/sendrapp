@extends('layouts.master')
@section('session')
<section class="section">
    <div class="container-fluid">
        <div class="title-wrapper pt-30">
            <div class="row align-items-center">
                <div class="col-md-6"><h2 class="text-success">Missions</h2></div>
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

        <div class="card-style mb-30">
            <div class="table-responsive">
                <table class="table align-middle">
                    <thead><tr>
                        <th>Mission</th><th>Date</th><th>Lieu</th><th>Agents</th><th>Pointages</th><th>Véhicules</th><th></th>
                    </tr></thead>
                    <tbody>
                    @forelse ($missions as $mission)
                        <tr>
                            <td>
                                <strong>{{ $mission->title }}</strong><br>
                                <span class="badge {{ $mission->type === 'programmee' ? 'bg-success' : 'bg-warning text-dark' }}">
                                    {{ $mission->type === 'programmee' ? 'Programmée' : 'Brute' }}
                                </span>
                            </td>
                            <td>{{ $mission->scheduled_at->format('d/m/Y H:i') }}</td>
                            <td>{{ $mission->address }}</td>
                            <td>{{ $mission->agents->count() }}</td>
                            <td>{{ $mission->agents->filter(fn ($agent) => $agent->pivot->checked_in_at)->count() }}</td>
                            <td>{{ $mission->vehicles->count() }}</td>
                            <td class="text-end">
                                <form action="{{ route('missions.destroy', $mission) }}" method="POST" onsubmit="return confirm('Supprimer cette mission ?')">
                                    @csrf @method('DELETE')
                                    <button class="btn btn-sm btn-outline-danger" type="submit">Supprimer</button>
                                </form>
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="7" class="text-center py-5">Aucune mission créée.</td></tr>
                    @endforelse
                    </tbody>
                </table>
            </div>
            <div class="d-flex justify-content-end mt-4">{{ $missions->links() }}</div>
        </div>
    </div>
</section>
@endsection
