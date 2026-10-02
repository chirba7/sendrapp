import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletium/views/screens/vehicle_details_screen.dart';
import '../../utils/strings.dart';

class VehicleListScreen extends StatefulWidget {
  @override
  _VehicleListScreenState createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  List<dynamic> _vehicles = [];
  bool _isLoading = true;
  ScrollController _scrollController = ScrollController();  // ScrollController for explicit scroll indicator

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token non trouvé')),
      );
      return;
    }

    final url = Strings.apiURI + 'vehicule';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la récupération des véhicules : ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la récupération des véhicules : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Liste des Véhicules',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold, // Met le texte en gras
          ),
        ),
        backgroundColor: Colors.green[700],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text('Chargement des véhicules...', style: TextStyle(fontSize: 16)),
          ],
        ),
      )
          : _vehicles.isEmpty
          ? Center(
        child: Text(
          'Aucun véhicule trouvé',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      )
          : Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,  // Show scrollbar when scrolling
        thickness: 4, // Épaisseur de la barre de défilement
        radius: Radius.circular(4),
        child: ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(10),
          itemCount: _vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = _vehicles[index];
            return Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green[700],
                  child: Icon(Icons.directions_car, color: Colors.white),
                ),
                title: Text(
                  vehicle['numero'].toString(),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  '${vehicle['marque'].toString()} ${vehicle['model'].toString()}',
                  style: TextStyle(fontSize: 14),
                ),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
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
    );
  }
}
