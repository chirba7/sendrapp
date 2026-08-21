import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletium/views/screens/vehicle_details_screen.dart';
import 'package:walletium/views/screens/vehicle_list_screen.dart';
import '../../utils/strings.dart';
import 'infraction_screen.dart';

class VehicleForm extends StatefulWidget {
  final int signalementId; // Identifiant du véhicule à mettre à jour

  VehicleForm({required this.signalementId}) {
    print('Signalement ID: $signalementId');
  }
  @override
  _VehicleFormState createState() => _VehicleFormState();
}
class _VehicleFormState extends State<VehicleForm> {
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _marqueController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _modeleController = TextEditingController();
  final TextEditingController _categorieController = TextEditingController();
  final TextEditingController _couleurController = TextEditingController();

  String? _entretien;
  String? _paysEtranger;
  Map<String, bool> _details = {
    'Défaut de contrôle technique': false,
    'Pneumatiques manquantes': false,
    'Véhicule immergé': false,
    'Défauts techniques irréversibles': false,
    'Véhicule non identifiable': false,
    'Véhicule brûlé': false,
    'Châssis non réparable': false,
  };

  @override
  void initState() {
    super.initState();
    _fetchVehicleDetails(widget.signalementId);
  }

  Future<void> _fetchVehicleDetails(int signalementId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = '${Strings.apiURI}vehicule/$signalementId';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Données du véhicule: $data');
      print('Détails:');
      print('  - Défaut de contrôle technique: ${data['defaut_controle_technique']}');
      print('  - Pneumatiques manquantes: ${data['pneumatiques_manquantes']}');
      print('  - Véhicule immergé: ${data['vehicule_immerge']}');
      print('  - Défauts techniques irréversibles: ${data['defauts_techniques_irreversibles']}');
      print('  - Véhicule non identifiable: ${data['vehicule_non_identifiable']}');
      print('  - Véhicule brûlé: ${data['vehicule_brule']}');
      print('  - Châssis non réparable: ${data['chassis_non_reparable']}');
      setState(() {
        _numeroController.text = data['numero'].toString();
        _marqueController.text = data['marque'].toString();
        _typeController.text = data['type'].toString();
        _modeleController.text = data['model'].toString();
        _categorieController.text = data['categorie'].toString();
        _couleurController.text = data['couleur'].toString();
        _entretien = data['entretien'].toString();
        _paysEtranger = data['pays_etranger'].toString();
        _details = {
          'Défaut de contrôle technique': (data['defaut_controle_technique'] == 1),
          'Pneumatiques manquantes': (data['pneumatiques_manquantes'] == 1),
          'Véhicule immergé': (data['vehicule_immerge'] == 1),
          'Défauts techniques irréversibles': (data['defauts_techniques_irreversibles'] == 1),
          'Véhicule non identifiable': (data['vehicule_non_identifiable'] == 1),
          'Véhicule brûlé': (data['vehicule_brule'] == 1),
          'Châssis non réparable': (data['chassis_non_reparable'] == 1),
        };
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec du chargement des détails du véhicule')),
      );
    }
  }

  Future<void> _updateVehicle() async {
    if (_numeroController.text.isEmpty ||
        _marqueController.text.isEmpty ||
        _typeController.text.isEmpty ||
        _modeleController.text.isEmpty ||
        _categorieController.text.isEmpty ||
        _couleurController.text.isEmpty ||
        _entretien == null ||
        _paysEtranger == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    final url = '${Strings.apiURI}vehicule/${widget.signalementId}';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    Map<String, dynamic> updatedDetails = {
      'defaut_controle_technique': _details['Défaut de contrôle technique'] == true ? 1 : 0,
      'pneumatiques_manquantes': _details['Pneumatiques manquantes'] == true ? 1 : 0,
      'vehicule_immerge': _details['Véhicule immergé'] == true ? 1 : 0,
      'defauts_techniques_irreversibles': _details['Défauts techniques irréversibles'] == true ? 1 : 0,
      'vehicule_non_identifiable': _details['Véhicule non identifiable'] == true ? 1 : 0,
      'vehicule_brule': _details['Véhicule brûlé'] == true ? 1 : 0,
      'chassis_non_reparable': _details['Châssis non réparable'] == true ? 1 : 0,
    };

    final response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({
        'numero_vehicule': _numeroController.text,
        'marque': _marqueController.text,
        'type': _typeController.text,
        'model': _modeleController.text,
        'categorie': _categorieController.text,
        'couleur': _couleurController.text,
        'entretien': _entretien,
        'pays_etranger': _paysEtranger,
        ...updatedDetails,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Véhicule mis à jour avec succès'),
          duration: Duration(seconds: 1),
        ),
      );

      // Redirection vers la page InfractionForm
      Future.delayed(Duration(seconds: 1), () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InfractionForm(signalementId: widget.signalementId),
          ),
        );
      });

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de la mise à jour du véhicule')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Modifier les détails',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VehicleListScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Scrollbar( // Ajouter l'indicateur de défilement
          thumbVisibility: true, // Rendre l'indicateur toujours visible
          thickness: 4.0, // Réduit l'épaisseur de l'indicateur
          radius: Radius.circular(5), // Arrondir les coins
          child: ListView(
            children: [
              Text(
                'Caractéristiques du Véhicule',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _buildField('Numéro du véhicule', _numeroController, Icons.numbers),
              _buildField('Marque', _marqueController, Icons.directions_car),
              _buildField('Type', _typeController, Icons.category),
              _buildField('Modèle', _modeleController, Icons.model_training),
              _buildField('Catégorie du véhicule', _categorieController, Icons.label),
              _buildField('Couleur', _couleurController, Icons.color_lens),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 10),
              _buildSectionTitle('État général'),
              _buildRadioGroup(['BON', 'MOYEN', 'DEGRADE'], _entretien, (value) {
                setState(() {
                  _entretien = value;
                });
              }),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 10),
              _buildSectionTitle('Pays étranger'),
              _buildRadioGroup(['OUI', 'NON'], _paysEtranger, (value) {
                setState(() {
                  _paysEtranger = value;
                });
              }),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 10),
              _buildSectionTitle('Détails du véhicule'),
              ..._details.keys.map((key) {
                return CheckboxListTile(
                  title: Text(key),
                  value: _details[key],
                  onChanged: (value) {
                    setState(() {
                      _details[key] = value ?? false;
                    });
                  },
                );
              }).toList(),
              SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _updateVehicle,
                icon: Icon(Icons.directions_car), // Ajoutez une icône ici
                label: Text(
                  'Mettre à jour le véhicule',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }


  Widget _buildField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildRadioGroup(List<String> options, String? groupValue, ValueChanged<String?> onChanged) {
    return Column(
      children: options.map((option) {
        return RadioListTile<String>(
          title: Text(option),
          value: option,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: Colors.green,
        );
      }).toList(),
    );
  }
}
