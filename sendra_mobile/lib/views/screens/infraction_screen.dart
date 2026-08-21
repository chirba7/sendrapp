import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dommages_screen.dart';
import 'infraction_list_page.dart'; // Assurez-vous que ce chemin est correct

import '../../utils/strings.dart';

class InfractionForm extends StatefulWidget {
  final int signalementId; // Identifiant de l'infraction à mettre à jour, ne sera jamais nul

  InfractionForm({required this.signalementId});

  @override
  _InfractionFormState createState() => _InfractionFormState();
}

class _InfractionFormState extends State<InfractionForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _motifController = TextEditingController();

  String? _lieu;
  String? _meteo;

  @override
  void initState() {
    super.initState();
    _fetchInfractionDetails(widget.signalementId);
  }

  Future<void> _fetchInfractionDetails(int signalementId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = '${Strings.apiURI}infraction/$signalementId'; // Remplacez par votre URL API

    final response = await http.get(Uri.parse(url), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    print('DONNEES DU GET: ${response.body}');
    print(response.statusCode);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _adresseController.text = data['adresse_precise'] ?? '';
        _motifController.text = data['motif_infraction'] ?? '';
        _lieu = data['lieu'] ?? '';
        _meteo = data['nuit'] == 1 ? 'Nuit' : data['pluie'] == 1 ? 'Pluie' : 'Aucun';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec du chargement des détails de l\'infraction')),
      );
    }
  }

  Future<void> _updateInfraction() async {
    if (_formKey.currentState!.validate() && _lieu != null && _meteo != null) {
      final url = '${Strings.apiURI}infraction/${widget.signalementId}';
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Déterminer les valeurs pour nuit et pluie
      bool nuit = _meteo == 'Nuit';
      bool pluie = _meteo == 'Pluie';

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'adresse_precise': _adresseController.text,
          'motif_infraction': _motifController.text,
          'lieu': _lieu,
          'nuit': nuit,
          'pluie': pluie,
        }),
      );

      print('Données envoyées :');
      print('-Adresse: ${_adresseController.text}');
      print('-Motif: ${_motifController.text}');
      print('-Lieu: $_lieu');
      print('-Météo: $_meteo');
      print('-Nuit: $nuit');
      print('-Pluie: $pluie');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Infraction mise à jour avec succès'),
            duration: Duration(seconds: 1),
          ),
        );

        Future.delayed(Duration(seconds: 1), () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DommagesScreen(signalementId: widget.signalementId),
            ),
          );
        });

      } else {
        final responseData = json.decode(response.body);
        final errors = responseData['errorList'] as Map<String, dynamic>;
        final errorMessages = errors.entries.map((entry) {
          final field = entry.key;
          final messages = (entry.value as List<dynamic>).join(', ');
          return '$field: $messages';
        }).join('\n');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de validation: \n$errorMessages')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Modifier l\'infraction',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green[700],
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InfractionListPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildField('Adresse précise', _adresseController),
              _buildField('Motif de l\'infraction', _motifController),

              SizedBox(height: 20),
              Text('Lieu :', style: TextStyle(fontSize: 16)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('PUBLIC'),
                      value: 'PUBLIC',
                      groupValue: _lieu,
                      onChanged: (value) {
                        setState(() {
                          _lieu = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('PRIVE'),
                      value: 'PRIVE',
                      groupValue: _lieu,
                      onChanged: (value) {
                        setState(() {
                          _lieu = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                ],
              ),
              if (_isSubmitting && _lieu == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Ce champ est obligatoire',
                    style: TextStyle(color: Colors.red),
                  ),
                ),

              SizedBox(height: 20),
              Text('Météo :', style: TextStyle(fontSize: 16)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Nuit'),
                      value: 'Nuit',
                      groupValue: _meteo,
                      onChanged: (value) {
                        setState(() {
                          _meteo = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Pluie'),
                      value: 'Pluie',
                      groupValue: _meteo,
                      onChanged: (value) {
                        setState(() {
                          _meteo = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                ],
              ),
              if (_isSubmitting && _meteo == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Ce champ est obligatoire',
                    style: TextStyle(color: Colors.red),
                  ),
                ),

              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() && _lieu != null && _meteo != null) {
                    setState(() {
                      _isSubmitting = true;
                    });
                    await _updateInfraction();
                  } else {
                    setState(() {
                      _isSubmitting = true; // Afficher les erreurs si des champs sont manquants
                    });
                  }
                },
                child: Text(
                  'Mettre à jour',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ce champ est obligatoire';
          }
          return null;
        },
      ),
    );
  }

}
