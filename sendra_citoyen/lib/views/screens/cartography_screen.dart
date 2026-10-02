import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/sendra_theme.dart';
import '../../utils/session.dart';
import '../../utils/strings.dart';

class CartographyScreen extends StatefulWidget {
  const CartographyScreen({super.key});

  @override
  State<CartographyScreen> createState() => _CartographyScreenState();
}

class _CartographyScreenState extends State<CartographyScreen> {
  static const LatLng _senegalCenter = LatLng(14.4974, -14.4524);

  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  Set<Marker> _markers = const {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSignalements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadSignalements() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final endpoint =
          await Session.isStaff() ? 'listerSignalements' : 'voirSignalements';
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
      final markers = <Marker>{};
      for (final item in items) {
        final latitude = double.tryParse(item['latitude']?.toString() ?? '');
        final longitude = double.tryParse(item['longitude']?.toString() ?? '');
        if (latitude == null || longitude == null) continue;
        markers.add(
          Marker(
            markerId: MarkerId(
              item['signalementId']?.toString() ?? '$latitude,$longitude',
            ),
            position: LatLng(latitude, longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _markerHue(item['etat']?.toString()),
            ),
            infoWindow: InfoWindow(
              title: item['titre']?.toString() ?? 'Signalement',
              snippet: item['commune']?.toString(),
            ),
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _markers = markers;
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

  double _markerHue(String? status) => switch (status) {
        'ENLEVE' => BitmapDescriptor.hueGreen,
        'EN COURS' => BitmapDescriptor.hueOrange,
        _ => BitmapDescriptor.hueRed,
      };

  Future<void> _search() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Cartographie',
                      style: TextStyle(
                        color: SendraTheme.ink,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Actualiser',
                    onPressed: _isLoading ? null : _loadSignalements,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _senegalCenter,
                      zoom: 6.5,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    markers: _markers,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    padding: const EdgeInsets.only(top: 92, bottom: 90),
                  ),
                  Positioned(
                    top: 14,
                    left: 16,
                    right: 16,
                    child: Material(
                      elevation: 3,
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
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 92,
                    child: FloatingActionButton.small(
                      heroTag: 'map-center',
                      onPressed: () => _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_senegalCenter, 6.5),
                      ),
                      backgroundColor: Colors.white,
                      foregroundColor: SendraTheme.green,
                      child: const Icon(Icons.my_location_rounded),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 92,
                    child: _legend(),
                  ),
                  if (_isLoading)
                    const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 18,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox.square(
                                dimension: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                              SizedBox(width: 12),
                              Text('Chargement de la carte…'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (!_isLoading &&
                      (_errorMessage != null || _markers.isEmpty))
                    Positioned(
                      left: 24,
                      right: 24,
                      top: 90,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                _errorMessage ??
                                    'Aucun signalement récent à afficher.',
                                textAlign: TextAlign.center,
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 10),
                                TextButton.icon(
                                  onPressed: _loadSignalements,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Réessayer'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            item(Colors.red, 'Signalé'),
            item(Colors.orange, 'En cours'),
            item(Colors.green, 'Résolu'),
          ],
        ),
      ),
    );
  }
}
