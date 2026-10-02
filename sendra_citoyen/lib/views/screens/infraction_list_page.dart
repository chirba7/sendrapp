import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/strings.dart';
import 'infraction_details_screen.dart';

class InfractionListPage extends StatefulWidget {
  @override
  _InfractionListPageState createState() => _InfractionListPageState();
}

class _InfractionListPageState extends State<InfractionListPage> {
  List<dynamic> _infractions = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _fetchInfractions();
  }

  Future<void> _fetchInfractions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Strings.apiURI + 'infraction'; // Remplacez par votre URL API

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });

     // print('Response body: ${response.body}');
     // print(response.statusCode);

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        setState(() {
          _infractions = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Si vous avez des tâches asynchrones en cours, annulez-les ici
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Liste des Infractions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Colors.green[700],
        ),
      )
          : _hasError
          ? Center(
        child: Text(
          'Erreur de chargement des infractions',
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      )
          : Padding(
        padding: const EdgeInsets.only(right: 8.0),
          child: Scrollbar(
        thumbVisibility: true, // Always show the scrollbar
        thickness: 4.0,
        radius: Radius.circular(10),
        child: ListView.builder(
          itemCount: _infractions.length,
          itemBuilder: (context, index) {
            final infraction = _infractions[index];
            return Card(
              elevation: 6,
              margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: Colors.white,
              shadowColor: Colors.black26,
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.green[700],
                  child: Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                title: Text(
                  infraction['adresse_precise'] ?? 'Adresse non disponible',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        infraction['motif_infraction'] ?? 'Motif non disponible',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_pin,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            infraction['lieu'] ?? 'Lieu inconnu',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.green[700],
                  size: 22,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InfractionDetailPage(infraction: infraction),
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