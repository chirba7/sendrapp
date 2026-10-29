import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletium/views/screens/vehicle_details_screen.dart';
import '../../utils/strings.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  List<dynamic> _vehicles = [];
  bool _isLoading = true;
  final ScrollController _scrollController =
      ScrollController(); // ScrollController for explicit scroll indicator

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token non trouvé')),
      );
      return;
    }

    final url = '${Strings.apiURI}vehicule';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _vehicles = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Échec de la récupération des véhicules : ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors de la récupération des véhicules : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Liste des Véhicules',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Met le texte en gras
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Chargement des véhicules...',
                        style: TextStyle(fontSize: 16)),
                  ],
                ),
              )
            : _vehicles.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun véhicule trouvé',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  )
                : Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true, // Show scrollbar when scrolling
                    thickness: 4, // Épaisseur de la barre de défilement
                    radius: const Radius.circular(4),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(10),
                      itemCount: _vehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = _vehicles[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[700],
                              child: const Icon(Icons.directions_car,
                                  color: Colors.white),
                            ),
                            title: Text(
                              vehicle['numero'].toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(
                              '${vehicle['marque'].toString()} ${vehicle['model'].toString()}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                color: Colors.grey),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => VehicleDetailsScreen(
                                    vehicleData: vehicle,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
