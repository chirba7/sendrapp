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

  const InfractionForm({super.key, required this.signalementId});

  @override
  State<InfractionForm> createState() => _InfractionFormState();
}

class _InfractionFormState extends State<InfractionForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _motifController = TextEditingController();
  final TextEditingController _explicationController = TextEditingController();
  // Liste de travail à remplacer par les 13 libellés officiels validés.
  static const _motifs = <String>[
    'Stationnement prolongé',
    'Véhicule abandonné sur la voie publique',
    'Véhicule gênant la circulation',
    'Véhicule dangereux pour les usagers',
    'Véhicule incendié',
    'Véhicule accidenté non déplacé',
    'Véhicule hors d’usage',
    'Véhicule sans identification lisible',
    'Occupation irrégulière du domaine public',
    'Obstruction d’un accès',
    'Risque de pollution',
    'Atteinte à la salubrité publique',
    'Autre motif à préciser',
  ];

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

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _adresseController.text = data['adresse_precise'] ?? '';
        _motifController.text = data['motif_infraction'] ?? '';
        _explicationController.text = data['explication_infraction'] ?? '';
        _lieu = data['lieu'] ?? '';
        _meteo = data['pluie'] == 1
            ? 'Pluie'
            : (data['nuit'] == 1 ? 'Nuit' : 'Jour');
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
          'explication_infraction': _explicationController.text.trim(),
          'lieu': _lieu,
          'nuit': nuit,
          'pluie': pluie,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Infraction mise à jour avec succès'),
            duration: Duration(seconds: 1),
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  DommagesScreen(signalementId: widget.signalementId),
            ),
          );
        });
      } else {
        final responseData = json.decode(response.body);
        if (responseData is! Map || responseData['errorList'] is! Map) {
          // 409 (pris en charge par un autre agent), 423 (déjà transmis)…
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(responseData is Map && responseData['message'] != null
                ? responseData['message'].toString()
                : 'Mise à jour impossible (${response.statusCode}).'),
          ));
          return;
        }
        final errors = responseData['errorList'] as Map<String, dynamic>;
        final errorMessages = errors.entries.map((entry) {
          final field = entry.key;
          final messages = (entry.value as List<dynamic>).join(', ');
          return '$field: $messages';
        }).join('\n');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de validation: \n$errorMessages')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const InfractionListPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
          child: Padding(
        // Marges réduites sur petit écran pour laisser la place au contenu.
        padding:
            EdgeInsets.all(MediaQuery.sizeOf(context).width < 360 ? 16 : 25),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Adresse issue de la géolocalisation du signalement : grisée,
              // l'agent ne la modifie pas.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: TextFormField(
                  controller: _adresseController,
                  readOnly: true,
                  enabled: false,
                  style: const TextStyle(color: Color(0xFF6B7570)),
                  decoration: InputDecoration(
                    labelText: 'Adresse précise',
                    helperText: 'Renseignée automatiquement, non modifiable',
                    filled: true,
                    fillColor: const Color(0xFFEDEFEE),
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: _motifs.contains(_motifController.text)
                    ? _motifController.text
                    : null,
                isExpanded: true,
                decoration:
                    const InputDecoration(labelText: 'Motif de l’infraction'),
                items: _motifs
                    .map((motif) => DropdownMenuItem(
                          value: motif,
                          child: Text(motif, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _motifController.text = value ?? ''),
                validator: (value) =>
                    value == null ? 'Choisissez un motif.' : null,
              ),
              TextFormField(
                controller: _explicationController,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Explication',
                    hintText: 'Justifiez le motif retenu'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Expliquez le motif.'
                    : null,
              ),
              const SizedBox(height: 20),
              const Text('Lieu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _choiceRow(const {'PUBLIC': '🏛️  Public', 'PRIVE': '🔒  Privé'},
                  _lieu, (value) => setState(() => _lieu = value)),
              if (_isSubmitting && _lieu == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Ce champ est obligatoire',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              const Text('Moment du constat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _timeChoiceRow(),
              if (_isSubmitting && _meteo == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Ce champ est obligatoire',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 30),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Mettre à jour',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      )),
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
            // Tuile étroite (petit écran, 3 tuiles côte à côte) : l'icône
            // passe au-dessus du libellé au lieu de déborder sur le côté.
            LayoutBuilder(builder: (context, c) {
              final libelle = Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              );
              return Center(
                child: c.maxWidth < 110
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [icon, const SizedBox(height: 4), libelle],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          icon,
                          const SizedBox(width: 10),
                          Flexible(child: libelle),
                        ],
                      ),
              );
            }),
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
