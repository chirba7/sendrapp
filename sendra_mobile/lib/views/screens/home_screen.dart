import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../utils/app_brand.dart';
import '../../utils/app_prefs.dart';
import '../../utils/signaler_flow.dart';
import '../../utils/strings.dart';
import '../../utils/sendra_theme.dart';
import '../../widgets/others/guide_view.dart';
import '../screens/drawer_screen.dart';

/// Accueil : liste des signalements.
///
/// Corrections de performance par rapport à l'ancienne version :
/// - la liste est réellement paresseuse (SliverList) : seules les cartes
///   visibles sont construites, au lieu de TOUTES les cartes à chaque image
///   (ListView shrinkWrap dans un SingleChildScrollView) ;
/// - plus de setState à chaque pixel de défilement (l'indicateur maison
///   reconstruisait tout l'écran pendant le scroll) ;
/// - les photos sont décodées à la taille de la vignette (cacheWidth) et non
///   en pleine résolution ;
/// - la réponse du serveur n'est plus imprimée en entier dans la console ;
/// - les compteurs par statut sont calculés une fois par chargement.
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();

  List<dynamic> _items = [];
  Map<String, int> _counts = const {};
  bool _initialLoading = true;
  bool _loadingMore = false;
  String? _loadError;
  // Par défaut : les dossiers à traiter (« Signalés »).
  String _filter = 'SIGNALE';
  bool _filterOpen = false;
  String _nextPageUrl = '';
  String _token = '';
  late final bool _isStaff = AppPrefs.isStaff;

  // Citoyen : ses signalements ou ceux des autres (liste « Autres »).
  bool _autres = false;
  List<dynamic> _autresItems = [];
  bool _autresCharges = false;
  bool _autresChargement = false;


  static const _filters = <({String value, String label})>[
    (value: 'TOUS', label: 'Tous'),
    (value: 'SIGNALE', label: 'Signalés'),
    (value: 'EN COURS', label: 'En cours'),
    (value: 'ENLEVE', label: 'Résolus'),
    (value: 'NON RESOLU', label: 'Non résolus'),
    (value: 'REJETE', label: 'Rejetés'),
  ];

  List<dynamic> get _source => _autres ? _autresItems : _items;

  List<dynamic> get _filtered => _filter == 'TOUS'
      ? _source
      : _source.where((s) => s['etat'] == _filter).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _fetchData();
    // Photo prise juste avant que le système ne ferme l'app : on rouvre le
    // formulaire de signalement avec elle.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => SignalerFlow.recupererPhotoPerdue());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final p = _scroll.position;
    if (p.extentAfter < 500) _loadMore();
  }

  void _recount() {
    final counts = <String, int>{'TOUS': _source.length};
    for (final s in _source) {
      final etat = s['etat']?.toString() ?? '';
      counts[etat] = (counts[etat] ?? 0) + 1;
    }
    _counts = counts;
  }

  Future<void> _refresh() => _autres ? _fetchAutres() : _fetchData();

  /// Signalements des autres citoyens (données réduites côté serveur).
  Future<void> _fetchAutres() async {
    setState(() {
      _autresChargement = true;
      _loadError = null;
    });
    try {
      final prefs = await AppPrefs.init();
      _token = prefs.getString('token') ?? '';
      final response = await http.get(
        Uri.parse('${Strings.apiURI}signalementsCommunaute'),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      final liste = decoded is List ? decoded : const [];
      if (!mounted) return;
      setState(() {
        _autresItems = liste
            .where((s) => s is Map && s['est_mien'] != true)
            .toList(growable: false);
        _autresCharges = true;
        _recount();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError =
          'Impossible de charger les signalements des autres. Réessayez.');
    } finally {
      if (mounted) setState(() => _autresChargement = false);
    }
  }

  void _choisirPortee(bool autres) {
    if (autres == _autres) return;
    setState(() {
      _autres = autres;
      _loadError = null;
      _recount();
    });
    if (autres && !_autresCharges) _fetchAutres();
  }

  Future<void> _fetchData() async {
    setState(() {
      _initialLoading = _items.isEmpty;
      _loadError = null;
    });
    try {
      final data = await _fetchSignalements();
      if (!mounted) return;
      setState(() {
        _items = data;
        _recount();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError =
          'Impossible de joindre le serveur. Vérifiez votre connexion puis réessayez.');
    } finally {
      if (mounted) setState(() => _initialLoading = false);
    }
  }

  Future<List<dynamic>> _fetchSignalements() async {
    final prefs = await AppPrefs.init();
    _token = prefs.getString('token') ?? '';

    // Le staff (Admin/Agent/Autorités) voit tous les signalements
    // (listerSignalements, paginé) ; un citoyen ne voit que les siens
    // (voirSignalements, non paginé).
    final endpoint = _isStaff ? 'listerSignalements' : 'voirSignalements';
    final url = Uri.parse(Strings.apiURI + endpoint);
    final response = await http.get(url, headers: _headers);
    if (kDebugMode) {
      debugPrint('GET $url -> ${response.statusCode}');
    }

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      // voirSignalements (citoyen) renvoie un tableau JSON brut ;
      // listerSignalements (staff) renvoie {"data": [...], "links": {...}}.
      if (decoded is List) {
        _nextPageUrl = '';
        return decoded;
      }
      _nextPageUrl = decoded['links']?['next'] ?? '';
      return List<dynamic>.from(decoded['data'] ?? const []);
    }
    if (response.statusCode == 401 && mounted) {
      // Un 401 isolé ne doit pas effacer la session persistée de l'agent.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Connexion momentanément impossible. Réessayez.'),
        backgroundColor: SendraTheme.statusEnCours,
      ));
    }
    throw Exception('Erreur ${response.statusCode}');
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  Future<void> _loadMore() async {
    if (_loadingMore || _nextPageUrl.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final response =
          await http.get(Uri.parse(_nextPageUrl), headers: _headers);
      if (response.statusCode != 200) throw Exception();
      final data = jsonDecode(response.body);
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...List<dynamic>.from(data['data'] ?? const [])];
        _nextPageUrl = data['links']?['next'] ?? '';
        _recount();
      });
    } catch (_) {
      // On réessaiera au prochain défilement.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// Réouvre le guide de prise en main en plein écran.
  void _openGuide() => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (ctx) => GuideView(onDone: () => Navigator.of(ctx).pop()),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SendraTheme.surface,
      drawer: const DrawerScreen(),
      appBar: AppBar(
        toolbarHeight: 68,
        // Logo epAvie en grand dans la barre du haut.
        title: Image.asset(
          AppBrand.appBarLogo,
          height: 46,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
        actions: [
          IconButton(
            tooltip: 'Guide',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: _openGuide,
          ),
          const SizedBox(width: 4),
        ],
      ),
      // Accueil : le bouton Signaler occupe le tiers haut de l'écran, la
      // liste des signalements les deux tiers restants.
      body: LayoutBuilder(
        builder: (context, constraints) {
          final heroHeight = (constraints.maxHeight / 3).clamp(150.0, 280.0);
          return Column(
            children: [
              SizedBox(
                height: heroHeight,
                child: _SignalerHero(
                  onTap: () => SignalerFlow.demarrer(context),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: SendraTheme.green,
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _header()),
                      if (!_isStaff) SliverToBoxAdapter(child: _porteeBar()),
                      SliverToBoxAdapter(child: _filterBar()),
                      ..._content(),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 40,
                          child: _loadingMore
                              ? const Center(
                                  child: SizedBox.square(
                                    dimension: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.4),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Citoyen : bascule entre ses signalements et ceux des autres.
  Widget _porteeBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: SendraTheme.greenSoft,
          selectedForegroundColor: SendraTheme.forest,
          side: const BorderSide(color: SendraTheme.border),
          textStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        segments: const [
          ButtonSegment(
            value: false,
            icon: Icon(Icons.person_rounded, size: 18),
            label: Text('Mes signalements'),
          ),
          ButtonSegment(
            value: true,
            icon: Icon(Icons.groups_rounded, size: 18),
            label: Text('Les autres'),
          ),
        ],
        selected: {_autres},
        onSelectionChanged: (v) => _choisirPortee(v.first),
      ),
    );
  }

  Widget _header() {
    final n = _source.length;
    final chargement = _autres ? _autresChargement && !_autresCharges : _initialLoading;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isStaff
                ? 'Signalements à proximité'
                : _autres
                    ? 'Signalements des autres'
                    : 'Mes signalements',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            chargement
                ? 'Chargement…'
                : '$n dossier${n > 1 ? 's' : ''} disponible${n > 1 ? 's' : ''}',
            style: const TextStyle(color: SendraTheme.muted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Sélecteur de statut : un seul bouton (statut courant + nombre) qui
  /// déroule la liste des statuts quand on le touche.
  Widget _filterBar() {
    final current = _filters.firstWhere((f) => f.value == _filter);
    Color colorOf(String v) =>
        v == 'TOUS' ? SendraTheme.green : SendraTheme.status(v).color;
    final color = colorOf(current.value);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          const Text('Statut',
              style: TextStyle(
                  color: SendraTheme.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(
            child: PopupMenuButton<String>(
              tooltip: 'Filtrer par statut',
              initialValue: _filter,
              position: PopupMenuPosition.under,
              offset: const Offset(0, 6),
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              constraints: const BoxConstraints(minWidth: 240),
              onSelected: (v) => setState(() {
                _filter = v;
                _filterOpen = false;
              }),
              onOpened: () => setState(() => _filterOpen = true),
              onCanceled: () => setState(() => _filterOpen = false),
              itemBuilder: (context) => [
                for (final f in _filters)
                  PopupMenuItem<String>(
                    value: f.value,
                    height: 48,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colorOf(f.value),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            f.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: f.value == _filter
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: SendraTheme.ink,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorOf(f.value).withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_counts[f.value] ?? 0}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colorOf(f.value),
                            ),
                          ),
                        ),
                        if (f.value == _filter) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_rounded,
                              size: 18, color: SendraTheme.green),
                        ],
                      ],
                    ),
                  ),
              ],
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _filterOpen ? color : SendraTheme.border,
                    width: _filterOpen ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        current.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: SendraTheme.ink,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_counts[current.value] ?? 0}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _filterOpen ? .5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: SendraTheme.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _content() {
    if (_autres ? (_autresChargement && !_autresCharges) : _initialLoading) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: 5,
            itemBuilder: (_, __) => const _SkeletonCard(),
          ),
        ),
      ];
    }
    if (_source.isEmpty || _filtered.isEmpty) {
      final error = _source.isEmpty ? _loadError : null;
      return [
        SliverToBoxAdapter(
          child: _EmptyState(
            icon: error != null
                ? Icons.wifi_off_rounded
                : Icons.inbox_outlined,
            message: error ??
                (_source.isEmpty
                    ? (_autres
                        ? 'Aucun autre signalement pour le moment.'
                        : 'Aucun signalement pour le moment.')
                    : 'Aucun signalement dans cette catégorie.'),
            onRetry: error != null ? _refresh : null,
          ),
        ),
      ];
    }
    final list = _filtered;
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.builder(
          itemCount: list.length,
          itemBuilder: (context, i) => _SignalementCard(
            key: ValueKey(list[i]['signalementId'] ?? i),
            data: list[i],
            showAgent: _isStaff,
            onTap: () async {
              await Navigator.pushNamed(
                context,
                '/depositMoneyDetailsScreen',
                arguments: list[i],
              );
              // La prise en charge ou la constatation a pu changer.
              if (mounted && _isStaff) _fetchData();
            },
          ),
        ),
      ),
    ];
  }
}

// ───────────────────────────── Carte d'un signalement ─────────────────────

class _SignalementCard extends StatelessWidget {
  const _SignalementCard({
    super.key,
    required this.data,
    required this.onTap,
    this.showAgent = false,
  });

  final dynamic data;
  final VoidCallback onTap;
  final bool showAgent;

  @override
  Widget build(BuildContext context) {
    final status = SendraTheme.status(data['etat']?.toString());
    final imageUrl = data['image_url']?.toString();
    final title = (data['vehicle_kind'] ?? data['titre'] ?? '').toString();
    final agent = data['pris_en_charge_par']?.toString();
    // Après constatation : marque, modèle et plaque à côté du type.
    final marqueModele =
        '${data['marque'] ?? ''} ${data['model'] ?? ''}'.trim();
    final plaque = (data['numero_vehicule'] ?? '').toString().trim();
    final parMoi = data['pris_en_charge_par_moi'] == true;
    final commune = (data['commune'] ?? '').toString();
    final date = (data['formatted_date'] ?? '').toString();
    final width = MediaQuery.sizeOf(context).width;
    final thumb = width < 360 ? 84.0 : 100.0;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SendraTheme.radius),
            side: const BorderSide(color: SendraTheme.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox.square(
                      dimension: thumb,
                      child: imageUrl == null || imageUrl.isEmpty
                          ? const _ThumbPlaceholder()
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              cacheWidth: (thumb * dpr).round(),
                              gaplessPlayback: true,
                              frameBuilder: (_, child, frame, sync) =>
                                  sync || frame != null
                                      ? child
                                      : const _ThumbPlaceholder(),
                              errorBuilder: (_, __, ___) =>
                                  const _ThumbPlaceholder(),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatusPill(
                            color: status.color,
                            label: status.label,
                            icon: status.icon),
                        const SizedBox(height: 8),
                        Text(
                          [
                            title.isEmpty ? 'Sans titre' : title,
                            if (marqueModele.isNotEmpty) marqueModele,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SendraTheme.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (plaque.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _Plaque(plaque),
                        ],
                        if (commune.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _InfoLine(
                              icon: Icons.place_outlined, text: commune),
                        ],
                        if (date.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          _InfoLine(
                              icon: Icons.schedule_rounded, text: date),
                        ],
                        if (showAgent && agent != null && agent.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          _InfoLine(
                            icon: parMoi
                                ? Icons.lock_open_rounded
                                : Icons.lock_rounded,
                            text: parMoi
                                ? 'Pris en charge par vous'
                                : 'Pris en charge par $agent',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: SendraTheme.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Plaque d'immatriculation, façon plaque réelle.
class _Plaque extends StatelessWidget {
  const _Plaque(this.texte);
  final String texte;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF15201A),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          texte.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      );
}

/// Grand bouton « Signaler » du tiers haut de l'accueil, animé : l'icône
/// « respire » et des ondes s'en échappent pour inviter à toucher.
class _SignalerHero extends StatefulWidget {
  const _SignalerHero({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SignalerHero> createState() => _SignalerHeroState();
}

class _SignalerHeroState extends State<_SignalerHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  bool _appuye = false;

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    final reduit = MediaQuery.of(context).disableAnimations;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Material(
        color: SendraTheme.green,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onHighlightChanged: (v) => setState(() => _appuye = v),
          child: AnimatedScale(
            scale: _appuye ? .97 : 1,
            duration: const Duration(milliseconds: 120),
            child: Ink(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [SendraTheme.green, SendraTheme.forest],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final icone = (c.maxHeight * .42).clamp(52.0, 92.0);
                return Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -40,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: .07),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox.square(
                              dimension: icone * 1.35,
                              child: AnimatedBuilder(
                                animation: _anim,
                                builder: (context, child) {
                                  final t = reduit ? 0.0 : _anim.value;
                                  // Respiration douce de l'icône.
                                  final souffle = reduit
                                      ? 1.0
                                      : 1 + .06 * (1 - (2 * t - 1).abs());
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Deux ondes décalées qui s'élargissent.
                                      if (!reduit)
                                        for (final decalage in const [0.0, .5])
                                          Builder(builder: (_) {
                                            final p = (t + decalage) % 1;
                                            return Container(
                                              width: icone * (1 + .35 * p),
                                              height: icone * (1 + .35 * p),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: .55 * (1 - p)),
                                                  width: 2.5,
                                                ),
                                              ),
                                            );
                                          }),
                                      Transform.scale(scale: souffle, child: child),
                                    ],
                                  );
                                },
                                child: Container(
                                  width: icone,
                                  height: icone,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: .15),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(Icons.add_a_photo_rounded,
                                      color: SendraTheme.green, size: icone * .48),
                                ),
                              ),
                            ),
                            SizedBox(height: c.maxHeight > 190 ? 14 : 8),
                            const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Signaler',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.3,
                                ),
                              ),
                            ),
                            if (c.maxHeight > 170) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Touchez pour photographier le véhicule',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: .85),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(
      {required this.color, required this.label, required this.icon});
  final Color color;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: SendraTheme.muted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: SendraTheme.muted, fontSize: 13.5),
          ),
        ),
      ],
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFEAF1ED),
      child: Center(
        child: Icon(Icons.directions_car_outlined,
            color: SendraTheme.muted, size: 28),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: const Color(0xFFECF1EE),
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SendraTheme.radius),
        border: Border.all(color: SendraTheme.border),
      ),
      child: Row(
        children: [
          bar(96, 96),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(70, 18),
                const SizedBox(height: 10),
                bar(double.infinity, 16),
                const SizedBox(height: 8),
                bar(120, 13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message, this.onRetry});
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 0),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: SendraTheme.greenSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: SendraTheme.green),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: SendraTheme.muted, fontSize: 15, height: 1.45),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ],
      ),
    );
  }
}

