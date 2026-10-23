{{--
    Parcours complet d'un signalement, comme dans les applications :
    Signalé → Constaté par l'agent → Approbation de l'autorité (rouge + motif
    si rejeté) → Enlèvement (rouge + motif si non enlevé) → Résolu / Non résolu.
    Vert = fait, orange = étape actuelle, rouge = échec, gris = à venir.
    Données : App\Support\AvancementSignalement::pour().
--}}
@php
    $couleurs = ['fait' => '#188038', 'actuel' => '#E37400', 'echec' => '#D93025'];
    $etapes = \App\Support\AvancementSignalement::pour($carPosition, \App\Support\HistoriqueSignalement::pour($carPosition));
    $atteinte = fn ($e) => in_array($e['statut'], ['fait', 'actuel', 'echec'], true);
@endphp
<style>
    .avc { list-style:none; margin:0; padding:0; }
    .avc-etape { position:relative; display:flex; gap:14px; padding-bottom:22px; }
    .avc-etape:last-child { padding-bottom:0; }
    .avc-rail { position:absolute; left:15px; top:34px; bottom:2px; width:4px; border-radius:2px; background:#e1e8e4; overflow:hidden; }
    .avc-rail span { display:block; width:100%; height:0; border-radius:2px; animation:avc-glisse .8s ease-out forwards; }
    .avc-etape:last-child .avc-rail { display:none; }
    .avc-pastille { flex:0 0 34px; width:34px; height:34px; border-radius:50%; display:flex; align-items:center; justify-content:center; color:#fff; font-weight:800; border:2px solid #e1e8e4; background:#fff; z-index:1; }
    .avc-actuel .avc-pastille { box-shadow:0 0 0 5px rgba(227,116,0,.18); }
    .avc-titre { font-weight:800; color:#15201a; }
    .avc-echec .avc-titre, .avc-echec .avc-detail { color:#D93025; }
    .avc-a_venir .avc-titre, .avc-saute .avc-titre { color:#5f6b65; font-weight:600; }
    .avc-saute .avc-titre { text-decoration:line-through; }
    .avc-detail { color:#5f6b65; font-size:14px; }
    .avc-date { color:#5f6b65; font-size:13px; }
    .avc-badge { font-size:11px; font-weight:700; border-radius:8px; padding:2px 7px; margin-left:6px; background:#E374001f; color:#E37400; }
    @keyframes avc-glisse { to { height:100%; } }
</style>
<ol class="avc">
    @foreach ($etapes as $i => $etape)
        @php
            $couleur = $couleurs[$etape['statut']] ?? '#e1e8e4';
            $suivante = $etapes[$i + 1] ?? null;
        @endphp
        <li class="avc-etape avc-{{ $etape['statut'] }}">
            <div class="avc-rail">@if ($suivante && $atteinte($suivante))<span style="background:{{ $couleurs[$suivante['statut']] }}"></span>@endif</div>
            <div class="avc-pastille" style="{{ $atteinte($etape) ? "background:$couleur;border-color:$couleur" : '' }}">
                @if ($etape['statut'] === 'saute') –
                @elseif ($etape['statut'] === 'actuel') ●
                @elseif ($etape['statut'] === 'echec') ✕
                @elseif ($etape['statut'] === 'fait') ✓
                @endif
            </div>
            <div>
                <div class="avc-titre">
                    {{ $etape['libelle'] }}
                    @if ($etape['statut'] === 'actuel')<span class="avc-badge">Étape actuelle</span>@endif
                </div>
                @if (!empty($etape['detail']))
                    <div class="avc-detail">{{ $etape['detail'] }}</div>
                @endif
                @if ($atteinte($etape) && !empty($etape['date']))
                    <div class="avc-date">{{ $etape['date'] }}</div>
                @endif
            </div>
        </li>
    @endforeach
</ol>
