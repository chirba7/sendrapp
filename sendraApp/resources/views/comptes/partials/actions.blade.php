{{-- Actions d'une ligne de la liste des comptes.
     $archives : la liste affichée est celle des comptes supprimés. --}}
<div class="action d-flex justify-content-end align-items-center" style="gap: 14px;">
    @if ($archives)
        <form action="{{ route('restaurer.compte', [$user->id]) }}" method="POST"
              onsubmit="return confirm('Restaurer ce compte ? Il pourra de nouveau se connecter au back-office.');">
            @csrf
            @method('PATCH')
            <button type="submit" class="border-0 bg-transparent p-0 text-success" title="Restaurer ce compte">
                <i class="lni lni-reload"></i>
            </button>
        </form>
    @else
        <a href="{{ route('modifier', [$user->id]) }}" class="edit text-success" title="Modifier ce compte">
            <i class="lni lni-pencil"></i>
        </a>
        {{-- Un Admin ne peut pas supprimer son propre compte (refusé aussi
             côté contrôleur) : le bouton est simplement masqué. --}}
        @if ($user->id !== auth()->id())
            <form action="{{ route('supprimer.compte', [$user->id]) }}" method="POST"
                  onsubmit="return confirm('Supprimer ce compte ?\n\nIl ne pourra plus se connecter et ne recevra plus les e-mails de SENDRA. Ses signalements sont conservés, et le compte reste restaurable depuis « Comptes supprimés ».');">
                @csrf
                @method('DELETE')
                <button type="submit" class="border-0 bg-transparent p-0 text-danger" title="Supprimer ce compte">
                    <i class="lni lni-trash-can"></i>
                </button>
            </form>
        @endif
    @endif
</div>
