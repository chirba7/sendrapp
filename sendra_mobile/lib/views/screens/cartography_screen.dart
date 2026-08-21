import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/custom_color.dart';
import '../../utils/strings.dart';

class CartographyScreen extends StatefulWidget {
  const CartographyScreen({super.key});

  @override
  State<CartographyScreen> createState() => _CartographyScreenState();
}

class _CartographyScreenState extends State<CartographyScreen> {
  static const LatLng _senegalCenter = LatLng(14.4974, -14.4524);

  Set<Marker> _markers = const {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSignalements();
  }

  Future<void> _loadSignalements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.get(
        Uri.parse('${Strings.apiURI}voirSignalements'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      final List<dynamic> signalements = decoded is List
          ? decoded
          : (decoded['data'] as List<dynamic>? ?? const []);

      final markers = <Marker>{};
      for (final item in signalements) {
        final latitude = double.tryParse(item['latitude']?.toString() ?? '');
        final longitude = double.tryParse(item['longitude']?.toString() ?? '');
        if (latitude == null || longitude == null) continue;

        markers.add(
          Marker(
            markerId: MarkerId(item['signalementId']?.toString() ?? '$latitude,$longitude'),
            position: LatLng(latitude, longitude),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cartographie', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
        backgroundColor: CustomColor.primaryColor,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _senegalCenter,
              zoom: 6.5,
            ),
            markers: _markers,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (!_isLoading && _markers.isEmpty)
            Positioned(
              left: 24,
              right: 24,
              top: 24,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _errorMessage ??
                        'Aucun signalement à afficher. La carte reste accessible et vous pouvez créer le premier signalement avec le bouton « Signaler ».',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
