@extends('layouts.base')
{{-- Habillage par rôle : la classe posée sur <body> fixe la couleur
     d'accent (voir sendra-refresh.css, section V2). --}}
@php
    $roleId = Auth::user()->role_id;
    $roleUi = match ($roleId) {
        1 => ['key' => 'admin', 'label' => 'Administration', 'icon' => 'lni-cog'],
        3 => ['key' => 'commune', 'label' => 'Autorité communale', 'icon' => 'lni-apartment'],
        4 => ['key' => 'prefecture', 'label' => 'Autorité préfectorale', 'icon' => 'lni-library'],
        7 => ['key' => 'operateur', 'label' => 'Opérateur', 'icon' => 'lni-delivery'],
        default => ['key' => 'agent', 'label' => 'Agent', 'icon' => 'lni-user'],
    };
@endphp
@section('body_class', 'role-'.$roleUi['key'])
@section('contenu')
{{-- Le menu latéral est reconstruit à chaque page : sans cela il repart en
     haut à chaque clic. On restitue sa position de défilement, pour que seul
     le contenu paraisse changer. --}}
@push('scripts')
<script>
(function () {
    var nav = document.querySelector('.sidebar-nav-wrapper .sidebar-nav');
    if (!nav) return;
    var cle = 'sendra:menu-scroll';
    try {
        var y = sessionStorage.getItem(cle);
        if (y) nav.scrollTop = parseInt(y, 10) || 0;
    } catch (e) {}
    nav.addEventListener('scroll', function () {
        try { sessionStorage.setItem(cle, nav.scrollTop); } catch (e) {}
    }, { passive: true });
    var actif = nav.querySelector('.nav-item.active');
    if (actif && (actif.offsetTop < nav.scrollTop || actif.offsetTop > nav.scrollTop + nav.clientHeight - 40)) {
        nav.scrollTop = Math.max(0, actif.offsetTop - 120);
    }
})();
</script>
@endpush

<!-- ======== sidebar-nav start =========== -->
<aside class="sidebar-nav-wrapper">
    <div class="navbar-logo">
        <a href="/">
            <img src="{{asset('img/sendra-original.png')}}" alt="logo" width="90%" height="80%" />
        </a>
    </div>
    <nav class="sidebar-nav ">
        <div class="role-card">
            <span class="role-icon"><i class="lni {{ $roleUi['icon'] }}"></i></span>
            <div>
                <small>Espace de travail</small>
                <strong>{{ $roleUi['label'] }}</strong>
            </div>
        </div>
        {{-- Menu construit à partir des rôles réellement autorisés sur chaque
             route (voir routes/web.php) : aucune entrée affichée ne peut
             aboutir à un 403. Regroupé par domaine, une icône distincte par
             entrée. --}}
        @php
            $r = (int) Auth::user()->role_id;
            $actif = fn (string ...$chemins) => collect($chemins)->contains(fn ($c) => request()->is($c));
            $sections = [
                'Pilotage' => [
                    ['Tableau de bord', route('dashboard'), 'lni-dashboard', [1, 2, 3, 4, 7], $actif('dashboard', '/')],
                    ['Cartographie', route('maps'), 'lni-map', [1, 2, 3, 4], $actif('dashboard/cartographie')],
                ],
                'Signalements' => [
                    ['Signalés', route('signales'), 'lni-alarm', [1, 2, 3, 4, 7], $actif('dashboard/signalement/signales')],
                    ['En cours', route('encours'), 'lni-reload', [1, 2, 3, 4, 7], $actif('dashboard/signalement/encours')],
                    ['Non résolus', route('non_resolus'), 'lni-warning', [1, 2, 3, 4, 7], $actif('dashboard/signalement/non-resolus')],
                    ['Résolus', route('enleves'), 'lni-checkmark-circle', [1, 2, 3, 4, 7], $actif('dashboard/signalement/enleves')],
                    ['Rejetés', route('rejetes'), 'lni-ban', [1, 2, 3, 4, 7], $actif('dashboard/signalement/rejetes')],
                    ['Approbations', route('approbations.index'), 'lni-shield', [1, 3, 4], $actif('dashboard/approbations')],
                ],
                'Opérations' => [
                    ['Missions', route('missions.index'), 'lni-clipboard', [1, 7], $actif('dashboard/missions*')],
                    ['Fourrières', route('pounds.index'), 'lni-home', [1], $actif('dashboard/fourrieres*')],
                    ['Pointage', route('attendance.index'), 'lni-timer', [1], $actif('dashboard/pointage*')],
                    ['Communes', route('communes.index'), 'lni-map-marker', [1], $actif('dashboard/communes*')],
                ],
            ];
            // Chaque rôle reçoit sa pastille de couleur, reprise de l'accent
            // défini dans sendra-refresh.css : la liste de sept entrées était
            // impossible à parcourir d'un coup d'œil.
            $comptes = [
                ['Ajouter un compte', route('ajouter'), 'dashboard/comptes/ajouter', 'plus', '#64748b'],
                ['Admin', route('admin'), 'dashboard/comptes/admin', 'role', '#048b44'],
                ['Agents', route('agents'), 'dashboard/comptes/agents', 'role', '#1a73e8'],
                ['Autorité commune', route('autorites'), 'dashboard/comptes/autorites', 'role', '#0f8a7e'],
                ['Autorité préfecture', route('utilisateurs'), 'dashboard/comptes/utilisateurs', 'role', '#7b3fc4'],
                ['Opérateurs', route('operateurs'), 'dashboard/comptes/operateurs', 'role', '#e37400'],
                ['Citoyens', route('citoyens'), 'dashboard/comptes/citoyens', 'role', '#94a3b8'],
            ];
            $comptesActif = collect($comptes)->contains(fn ($c) => request()->is($c[2]));
        @endphp
        @foreach ($sections as $titre => $entrees)
            @php($visibles = array_values(array_filter($entrees, fn ($e) => in_array($r, $e[3], true))))
            @if (count($visibles))
            <p class="nav-section">{{ $titre }}</p>
            <ul class="nav-group">
                @foreach ($visibles as [$libelle, $url, $icone, $roles, $estActif])
                <li class="nav-item {{ $estActif ? 'active' : '' }}">
                    <a href="{{ $url }}">
                        <span class="icon"><i class="lni {{ $icone }}"></i></span>
                        <span class="text">{{ $libelle }}</span>
                    </a>
                </li>
                @endforeach
            </ul>
            @endif
        @endforeach
        @if ($r === 1)
        <p class="nav-section">Administration</p>
        <ul class="nav-group">
            <li class="nav-item nav-item-has-children {{ $comptesActif ? 'active' : '' }}">
                <a href="#0" class="{{ $comptesActif ? '' : 'collapsed' }}" data-bs-toggle="collapse" data-bs-target="#ddmenu_comptes" aria-controls="ddmenu_comptes" aria-expanded="{{ $comptesActif ? 'true' : 'false' }}">
                    <span class="icon"><i class="lni lni-users"></i></span>
                    <span class="text">Comptes</span>
                </a>
                <ul id="ddmenu_comptes" class="collapse dropdown-nav {{ $comptesActif ? 'show' : '' }}">
                    @foreach ($comptes as [$libelle, $url, $chemin, $forme, $couleur])
                    <li>
                        <a href="{{ $url }}" class="{{ request()->is($chemin) ? 'active' : '' }}">
                            @if ($forme === 'plus')
                            <i class="lni lni-circle-plus role-dot-icon" style="color: {{ $couleur }}"></i>
                            @else
                            <span class="role-dot" style="background: {{ $couleur }}"></span>
                            @endif
                            {{ $libelle }}
                        </a>
                    </li>
                    @endforeach
                </ul>
            </li>
        </ul>
        @endif
    </nav>

</aside>
<div class="overlay"></div>
<!-- ======== sidebar-nav end =========== -->

<!-- ======== main-wrapper start =========== -->
<main class="main-wrapper">
    <!-- ========== header start ========== -->
    <header class="header">
        <div class="container-fluid">
            <div class="row">
                <div class="col-lg-5 col-md-5 col-6">
                    <div class="header-left d-flex align-items-center">
                        <div class="menu-toggle-btn mr-15">
                            <button id="menu-toggle" class="main-btn success-btn btn-hover">
                                <i class="lni lni-chevron-left me-2"></i> Menu
                            </button>
                        </div>
                        <div class="header-search d-none d-md-flex">
                            <form action="#">
                                <input type="text" placeholder="Rechercher…" />
                                <button><i class="lni lni-search-alt"></i></button>
                            </form>
                        </div>
                    </div>
                </div>
                <div class="col-lg-7 col-md-7 col-6">
                    <div class="header-right">
                        <div class="profile-box ml-15">
                            <button class="dropdown-toggle bg-transparent border-0" type="button" id="profile" data-bs-toggle="dropdown" aria-expanded="false">
                                <div class="profile-info">
                                    <div class="info">
                                        <div class="image">
                                            <img src="{{asset('assets/images/avatar.png')}}" alt="" />
                                        </div>
                                        <div>
                                            <h6 class="fw-500">{{ Auth::user()->first_name }} {{Auth::user()->last_name }}</h6>
                                            <p>{{Auth::user()->role->nomRole}}</p>
                                        </div>
                                    </div>
                                </div>
                            </button>
                            <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="profile">
                                <li>
                                    <div class="author-info flex items-center !p-1">
                                        <div class="content">
                                            <h4 class="text-sm">{{ Auth::user()->first_name }} {{Auth::user()->last_name }}</h4>
                                            <a class="text-black/40 dark:text-white/40 hover:text-black dark:hover:text-white text-xs" href="#">{{ Auth::user()->email }}</a>
                                        </div>
                                    </div>
                                </li>
                                <li class="divider"></li>
                                <li>
                                    <a href="{{ route('profile.show') }}">
                                        <i class="lni lni-user"></i> Voir Profil
                                    </a>
                                </li>
                                <li class="divider"></li>
                                <li>
                                    <form method="POST" action="{{ route('logout') }}" x-data>
                                        @csrf
                                        <button type="submit" class="main-btn danger-btn btn-hover w-100 text-center"><i class="lni lni-exit"></i> Se Déconecter </button>
                                    </form>
                                </li>
                            </ul>
                        </div>
                        <!-- profile end -->
                    </div>
                </div>
            </div>
        </div>
    </header>
    <!-- ========== header end ========== -->

    <!-- ========== section start ========== -->
    @yield('session')
    <!-- ========== section end ========== -->

    <!-- ========== footer start =========== -->
    <footer class="footer">
        <div class="container-fluid">
            <div class="row">
                <div class="col-md-6 order-last order-md-first">
                    <div class="copyright text-center text-md-start">
                        <p class="text-sm">
                            2024 © Designed by
                            <a href="https://sendra.sn" rel="nofollow" target="_blank">
                                SENDRA
                            </a>
                        </p>
                    </div>
                </div>
                <!-- end col-->
                <div class="col-md-6">
                    <div class="terms d-flex justify-content-center justify-content-md-end">
                        <a href="#0" class="text-sm">SENDRA</a>
                    </div>
                </div>
            </div>
            <!-- end row -->
        </div>
        <!-- end container -->
    </footer>
    <!-- ========== footer end =========== -->
</main>
<!-- ======== main-wrapper end =========== -->
@endsection
