import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../utils/app_prefs.dart';
import '../../utils/sendra_theme.dart';
import '../../utils/strings.dart';

/// Données de la carte gardées en mémoire pour toute la session.
///
/// Avant : à chaque affichage, l'écran attendait le GPS (jusqu'à 12 s) avant
/// même de créer la carte, puis retéléchargeait tous les signalements —
/// d'où l'impression que la carte « recharge à chaque fois ». Désormais la
/// carte s'affiche tout de suite à la dernière position connue, avec les
/// marqueurs déjà chargés ; la mise à jour se fait en arrière-plan.
class _MapCache {
  static List<Map<String, dynamic>> items = const [];
  static DateTime? fetchedAt;
  static LatLng? userPosition;
  static CameraPosition? camera;

  static bool get isFresh =>
      fetchedAt != null &&
      DateTime.now().difference(fetchedAt!) < const Duration(minutes: 3);
}

class CartographyScreen extends StatefulWidget {
  const CartographyScreen({super.key});

  @override
  State<CartographyScreen> createState() => _CartographyScreenState();
}

class _CartographyScreenState extends State<CartographyScreen>
    with AutomaticKeepAliveClientMixin {
  static const LatLng _senegalCenter = LatLng(14.4974, -14.4524);

  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng? _userPosition = _MapCache.userPosition;
  List<Map<String, dynamic>> _items = _MapCache.items;
  late Set<Marker> _markers = _buildMarkers();
  bool _isLoading = !_MapCache.isFresh;
  String? _errorMessage;

  // Citoyen : tous les signalements, les siens ou ceux des autres.
  late final bool _isStaff = AppPrefs.isStaff;
  String _portee = 'tous';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!_MapCache.isFresh) _loadSignalements();
    _locateUser(recenter: _MapCache.camera == null);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  void _setUserPosition(LatLng p) {
    _MapCache.userPosition = p;
    if (mounted) setState(() => _userPosition = p);
  }

  /// Position : d'abord la dernière connue (instantané), puis la position
  /// précise en arrière-plan. La carte n'attend jamais le GPS.
  Future<void> _locateUser({bool recenter = true, bool userAction = false}) async {
    try {
      if (!await _ensurePermission()) throw Exception();
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        final p = LatLng(last.latitude, last.longitude);
        _setUserPosition(p);
        if (recenter) {
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(p, 15));
        }
      }
      final pos = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 12));
      final p = LatLng(pos.latitude, pos.longitude);
      _setUserPosition(p);
      if (recenter || userAction) {
        await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(p, 15));
      }
    } catch (_) {
      if (!mounted || !userAction) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Position indisponible. Activez la localisation pour recentrer la carte.'),
      ));
    }
  }

  Future<void> _loadSignalements() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final prefs = await AppPrefs.init();
      final token = prefs.getString('token') ?? '';
      // Le citoyen voit aussi les signalements des autres (données
      // réduites, champ `est_mien`) pour pouvoir filtrer.
      final endpoint =
          AppPrefs.isStaff ? 'listerSignalements' : 'signalementsCommunaute';
      final response = await http.get(
        Uri.parse('${Strings.apiURI}$endpoint'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final items = decoded is List
          ? decoded
          : (decoded['data'] as List<dynamic>? ?? const []);
      _MapCache.items = [
        for (final item in items)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
      _MapCache.fetchedAt = DateTime.now();
      if (!mounted) return;
      setState(() {
        _items = _MapCache.items;
        _markers = _buildMarkers();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossible de charger les signalements.';
        _isLoading = false;
      });
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    for (final item in _items) {
      final mien = item['est_mien'] == true;
      if (!_isStaff && _portee == 'miens' && !mien) continue;
      if (!_isStaff && _portee == 'autres' && mien) continue;
      final latitude = double.tryParse(item['latitude']?.toString() ?? '');
      final longitude = double.tryParse(item['longitude']?.toString() ?? '');
      if (latitude == null || longitude == null) continue;
      final etat = item['etat']?.toString();
      markers.add(
        Marker(
          markerId: MarkerId(
            item['signalementId']?.toString() ?? '$latitude,$longitude',
          ),
          position: LatLng(latitude, longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(_markerHue(etat)),
          infoWindow: InfoWindow(
            title: '${item['vehicle_kind'] ?? item['titre'] ?? 'Signalement'}'
                ' · ${SendraTheme.status(etat).label}',
            snippet: [
              item['commune']?.toString() ?? '',
              if (!_isStaff) mien ? 'Mon signalement' : 'Signalé par un autre citoyen',
            ].where((t) => t.isNotEmpty).join(' · '),
          ),
        ),
      );
    }
    return markers;
  }

  void _choisirPortee(String portee) {
    setState(() {
      _portee = portee;
      _markers = _buildMarkers();
    });
  }

  double _markerHue(String? status) => switch (status) {
        'ENLEVE' => BitmapDescriptor.hueGreen,
        'EN COURS' => BitmapDescriptor.hueOrange,
        'NON RESOLU' => BitmapDescriptor.hueRose,
        'REJETE' => BitmapDescriptor.hueViolet,
        _ => BitmapDescriptor.hueRed,
      };

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return;
    final matching = _markers.where((marker) {
      final title = marker.infoWindow.title?.toLowerCase() ?? '';
      final commune = marker.infoWindow.snippet?.toLowerCase() ?? '';
      return title.contains(query) || commune.contains(query);
    }).toList();
    if (matching.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun signalement correspondant.')),
      );
      return;
    }
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(matching.first.position, 15),
    );
  }

  CameraPosition get _initialCamera =>
      _MapCache.camera ??
      CameraPosition(
        target: _userPosition ?? _senegalCenter,
        zoom: _userPosition == null ? 6.5 : 15,
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Cartographie'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _isLoading ? null : _loadSignalements,
            icon: _isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          // La carte est créée immédiatement, une seule fois.
          RepaintBoundary(
            child: GoogleMap(
              initialCameraPosition: _initialCamera,
              onMapCreated: (controller) => _mapController = controller,
              onCameraMove: (position) => _MapCache.camera = position,
              markers: _markers,
              myLocationEnabled: _userPosition != null,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              buildingsEnabled: false,
              padding: EdgeInsets.only(top: _isStaff ? 76 : 120, bottom: 90),
            ),
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Material(
              elevation: 2,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(16),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'Rechercher un lieu ou une commune…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: _search,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          if (!_isStaff)
            Positioned(
              top: 72,
              left: 16,
              right: 16,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in const [
                      ('tous', 'Tous', Icons.layers_rounded),
                      ('miens', 'Les miens', Icons.person_rounded),
                      ('autres', 'Les autres', Icons.groups_rounded),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(f.$3, size: 18),
                          label: Text(f.$2),
                          selected: _portee == f.$1,
                          showCheckmark: false,
                          backgroundColor: Colors.white,
                          selectedColor: SendraTheme.greenSoft,
                          elevation: 2,
                          shadowColor: Colors.black26,
                          side: BorderSide(
                            color: _portee == f.$1
                                ? SendraTheme.green
                                : SendraTheme.border,
                          ),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _portee == f.$1
                                ? SendraTheme.forest
                                : SendraTheme.ink,
                          ),
                          onSelected: (_) => _choisirPortee(f.$1),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Positioned(
            right: 16,
            bottom: 96,
            child: FloatingActionButton.small(
              heroTag: 'map-center',
              onPressed: () => _locateUser(userAction: true),
              backgroundColor: Colors.white,
              foregroundColor: SendraTheme.green,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 96,
            child: _legend(),
          ),
          if (!_isLoading && _errorMessage != null)
            Positioned(
              left: 24,
              right: 24,
              top: _isStaff ? 84 : 124,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _loadSignalements,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Réessayer'),
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

  Widget _legend() {
    Widget item(Color color, String label) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            item(SendraTheme.statusSignale, 'Signalé'),
            item(SendraTheme.statusEnCours, 'En cours'),
            item(SendraTheme.statusResolu, 'Résolu'),
            item(const Color(0xFFE91E63), 'Non résolu'),
            item(const Color(0xFF8E24AA), 'Rejeté'),
          ],
        ),
      ),
    );
  }
}
