import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../utils/app_brand.dart';
import '../../utils/app_prefs.dart';
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
  String _filter = 'TOUS';
  String _nextPageUrl = '';
  String _token = '';
  late final bool _isStaff = AppPrefs.isStaff;


  static const _filters = <({String value, String label})>[
    (value: 'TOUS', label: 'Tous'),
    (value: 'SIGNALE', label: 'Signalés'),
    (value: 'EN COURS', label: 'En cours'),
    (value: 'ENLEVE', label: 'Résolus'),
    (value: 'NON RESOLU', label: 'Non résolus'),
  ];

  List<dynamic> get _filtered => _filter == 'TOUS'
      ? _items
      : _items.where((s) => s['etat'] == _filter).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _fetchData();
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
    final counts = <String, int>{'TOUS': _items.length};
    for (final s in _items) {
      final etat = s['etat']?.toString() ?? '';
      counts[etat] = (counts[etat] ?? 0) + 1;
    }
    _counts = counts;
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
        toolbarHeight: 60,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(AppBrand.isPro ? 8 : 0),
          child: Image.asset(
            AppBrand.appBarLogo,
            height: AppBrand.isPro ? 36 : 40,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
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
      body: RefreshIndicator(
        color: SendraTheme.green,
        onRefresh: _fetchData,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverToBoxAdapter(child: _filterBar()),
            ..._content(),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: _loadingMore
                    ? const Center(
                        child: SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final n = _items.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isStaff ? 'Signalements à proximité' : 'Mes signalements',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            _initialLoading
                ? 'Chargement…'
                : '$n dossier${n > 1 ? 's' : ''} disponible${n > 1 ? 's' : ''}',
            style: const TextStyle(color: SendraTheme.muted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Filtres en une ligne défilante : l'ancienne grille 2×3 occupait la
  /// moitié de l'écran et repoussait la liste hors de vue.
  Widget _filterBar() {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = _filters[i];
          final selected = _filter == f.value;
          final color = f.value == 'TOUS'
              ? SendraTheme.green
              : SendraTheme.status(f.value).color;
          final count = _counts[f.value] ?? 0;
          return Material(
            color: selected ? color : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: selected ? color : SendraTheme.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _filter = f.value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (f.value != 'TOUS') ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      f.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : SendraTheme.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: .22)
                            : color.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _content() {
    if (_initialLoading) {
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
    if (_items.isEmpty || _filtered.isEmpty) {
      final error = _items.isEmpty ? _loadError : null;
      return [
        SliverToBoxAdapter(
          child: _EmptyState(
            icon: error != null
                ? Icons.wifi_off_rounded
                : Icons.inbox_outlined,
            message: error ??
                (_items.isEmpty
                    ? 'Aucun signalement pour le moment.'
                    : 'Aucun signalement dans cette catégorie.'),
            onRetry: error != null ? _fetchData : null,
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
            key: ValueKey(list[i]['id'] ?? i),
            data: list[i],
            onTap: () => Navigator.pushNamed(
              context,
              '/depositMoneyDetailsScreen',
              arguments: list[i],
            ),
          ),
        ),
      ),
    ];
  }
}

// ───────────────────────────── Carte d'un signalement ─────────────────────

class _SignalementCard extends StatelessWidget {
  const _SignalementCard({super.key, required this.data, required this.onTap});

  final dynamic data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = SendraTheme.status(data['etat']?.toString());
    final imageUrl = data['image_url']?.toString();
    final title = (data['titre'] ?? '').toString();
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
                          title.isEmpty ? 'Sans titre' : title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SendraTheme.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

