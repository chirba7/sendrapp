import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dommages_screen.dart';
import 'infraction_list_page.dart'; // Assurez-vous que ce chemin est correct

import '../../utils/strings.dart';
import '../../utils/sendra_theme.dart';

class InfractionForm extends StatefulWidget {
  final int
      signalementId; // Identifiant de l'infraction à mettre à jour, ne sera jamais nul

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
    final url =
        '${Strings.apiURI}infraction/$signalementId'; // Remplacez par votre URL API

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
        _meteo = data['pluie'] == 1
            ? 'Pluie'
            : (data['nuit'] == 1 ? 'Nuit' : 'Jour');
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Échec du chargement des détails de l\'infraction')),
      );
    }
  }

  Future<void> _updateInfraction() async {
    if (_formKey.currentState!.validate() && _lieu != null && _meteo != null) {
      final url = '${Strings.apiURI}infraction/${widget.signalementId}';
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Le backend conserve ses deux booléens historiques. « Jour » signifie
      // simplement nuit=false et pluie=false.
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
          SnackBar(
            content: Text('Infraction mise à jour avec succès'),
            duration: Duration(seconds: 1),
          ),
        );

        Future.delayed(Duration(seconds: 1), () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  DommagesScreen(signalementId: widget.signalementId),
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
        SnackBar(
            content: Text('Veuillez remplir tous les champs obligatoires')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infraction'),
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
              const Text('Lieu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _choiceRow(const {'PUBLIC': '🏛️  Public', 'PRIVE': '🔒  Privé'},
                  _lieu, (value) => setState(() => _lieu = value)),
              if (_isSubmitting && _lieu == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Ce champ est obligatoire',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 20),
              const Text('Moment du constat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _timeChoiceRow(),
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
                  if (_formKey.currentState!.validate() &&
                      _lieu != null &&
                      _meteo != null) {
                    setState(() {
                      _isSubmitting = true;
                    });
                    await _updateInfraction();
                  } else {
                    setState(() {
                      _isSubmitting =
                          true; // Afficher les erreurs si des champs sont manquants
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

  Widget _choiceRow(
    Map<String, String> choices,
    String? selectedValue,
    ValueChanged<String> onChanged,
  ) {
    return Row(
      children: choices.entries.map((entry) {
        final selected = selectedValue == entry.key;
        return Expanded(
          child: Padding(
            padding:
                EdgeInsets.only(right: entry.key == choices.keys.first ? 8 : 0),
            child: InkWell(
              onTap: () => onChanged(entry.key),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFE1F3E8) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? SendraTheme.green : SendraTheme.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? SendraTheme.forest : SendraTheme.ink,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _timeChoiceRow() {
    return Row(
      children: [
        Expanded(
          child: _timeChoice(
            value: 'Jour',
            backgroundColor: const Color(0xFF62B8ED),
            icon: const Icon(
              Icons.wb_sunny_rounded,
              color: Color(0xFFFFD54F),
              size: 30,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _timeChoice(
            value: 'Nuit',
            backgroundColor: const Color(0xFF101722),
            icon: const _NightSkyIcon(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _timeChoice(
            value: 'Pluie',
            backgroundColor: const Color(0xFF4A6572),
            icon: const Icon(
              Icons.water_drop_rounded,
              color: Color(0xFF9AD4E8),
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeChoice({
    required String value,
    required Color backgroundColor,
    required Widget icon,
  }) {
    final selected = _meteo == value;
    return InkWell(
      onTap: () => setState(() => _meteo = value),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 82,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? SendraTheme.green : SendraTheme.border,
            width: selected ? 3 : 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x33008F4C),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                right: 8,
                top: 8,
                child: Icon(Icons.check_circle, color: Colors.white, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

class _NightSkyIcon extends StatelessWidget {
  const _NightSkyIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 42,
      height: 34,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Icon(Icons.nightlight_round, color: Colors.white, size: 30),
          ),
          Positioned(right: 2, top: 2, child: _Star(size: 4)),
          Positioned(right: 10, top: 12, child: _Star(size: 3)),
          Positioned(right: 0, bottom: 5, child: _Star(size: 3)),
        ],
      ),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}
