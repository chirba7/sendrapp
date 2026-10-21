import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletium/views/screens/vehicle_details_screen.dart';
import 'package:walletium/views/screens/vehicle_list_screen.dart';
import '../../utils/strings.dart';
import '../../utils/sendra_theme.dart';
import '../../utils/vehicle_brands.dart';
import 'infraction_screen.dart';

/// Formate la saisie de plaque en AA-<chiffres>-AA au fil de la frappe
/// (majuscules forcées, tirets automatiques). Le nombre de chiffres n'est
/// pas fixe (0, 00, 000, 0000... selon la plaque) : le segment se termine
/// dès qu'une lettre suit, pas après un nombre de caractères donné. La
/// validation stricte du format se fait séparément, à la soumission.
class _PlateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.toUpperCase();
    final letters1 = <String>[];
    final digits = <String>[];
    final letters2 = <String>[];

    for (final char in raw.split('')) {
      final isLetter = RegExp(r'[A-Z]').hasMatch(char);
      final isDigit = RegExp(r'[0-9]').hasMatch(char);
      if (isLetter) {
        if (digits.isEmpty && letters1.length < 2) {
          letters1.add(char);
        } else if (digits.isNotEmpty && letters2.length < 2) {
          letters2.add(char);
        }
      } else if (isDigit) {
        // Le segment chiffres se termine dès que letters2 a commencé —
        // pas de longueur fixe imposée avant ça.
        if (letters1.length == 2 && letters2.isEmpty) {
          digits.add(char);
        }
      }
    }

    final buffer = StringBuffer(letters1.join());
    if (letters1.length == 2) {
      buffer.write('-');
      buffer.write(digits.join());
    }
    if (letters2.isNotEmpty) {
      buffer.write('-');
      buffer.write(letters2.join());
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class VehicleForm extends StatefulWidget {
  final int signalementId; // Identifiant du véhicule à mettre à jour

  VehicleForm({required this.signalementId}) {
    print('Signalement ID: $signalementId');
  }
  @override
  _VehicleFormState createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm> {
  static const List<String> _vehicleTypes = [
    'Berline',
    'VUS',
    'SUV',
    'Hayon',
    'Camion',
    'Electrique',
  ];
  static const List<String> _vehicleCategories = [
    'VPP',
    'VUS',
    'VUL',
    'VTM',
    'CYCL',
  ];
  static const Map<String, Color> _vehicleColors = {
    'Blanc': Color(0xFFF5F5F5),
    'Noir': Color(0xFF202124),
    'Gris': Color(0xFF8B9298),
    'Argent': Color(0xFFC5CBD0),
    'Rouge': Color(0xFFD93636),
    'Bleu': Color(0xFF2767C5),
    'Vert': Color(0xFF278652),
    'Jaune': Color(0xFFF2C230),
    'Orange': Color(0xFFE87924),
    'Marron': Color(0xFF795548),
  };
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _marqueController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _modeleController = TextEditingController();
  final TextEditingController _categorieController = TextEditingController();
  final TextEditingController _couleurController = TextEditingController();

  // Sélecteur en tête d'écran : filtre la liste de marques suggérées
  // (voiture/moto) — n'est pas envoyé au serveur, juste une aide de saisie.
  String _vehicleKind = 'Voiture';
  // Ne remonte qu'une fois, après le chargement initial des données, pour
  // forcer un seul remontage du champ Autocomplete (afficher la marque déjà
  // enregistrée) sans perturber la frappe de l'utilisateur ensuite.
  int _brandFieldVersion = 0;
  List<String> get _brandOptions =>
      _vehicleKind == 'Moto' ? VehicleBrands.moto : VehicleBrands.voiture;

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
      print(
          '  - Défaut de contrôle technique: ${data['defaut_controle_technique']}');
      print('  - Pneumatiques manquantes: ${data['pneumatiques_manquantes']}');
      print('  - Véhicule immergé: ${data['vehicule_immerge']}');
      print(
          '  - Défauts techniques irréversibles: ${data['defauts_techniques_irreversibles']}');
      print(
          '  - Véhicule non identifiable: ${data['vehicule_non_identifiable']}');
      print('  - Véhicule brûlé: ${data['vehicule_brule']}');
      print('  - Châssis non réparable: ${data['chassis_non_reparable']}');
      setState(() {
        _numeroController.text = _cleanValue(data['numero']).toUpperCase();
        // Marque : saisie libre (suggestions seulement) depuis cette
        // correction — on charge la valeur enregistrée telle quelle, sans
        // la restreindre à une liste fermée.
        _marqueController.text = _cleanValue(data['marque']);
        _brandFieldVersion++;
        _typeController.text =
            _canonicalChoice(_cleanValue(data['type']), _vehicleTypes);
        _modeleController.text = _cleanValue(data['model']);
        _categorieController.text = _canonicalChoice(
            _cleanValue(data['categorie']), _vehicleCategories);
        final loadedColor = _cleanValue(data['couleur']);
        _couleurController.text = _vehicleColors.keys.firstWhere(
          (color) => color.toLowerCase() == loadedColor.toLowerCase(),
          orElse: () => '',
        );
        _entretien = _cleanValue(data['entretien']).toUpperCase();
        _paysEtranger = _cleanValue(data['pays_etranger']).toUpperCase();
        _details = {
          'Défaut de contrôle technique':
              (data['defaut_controle_technique'] == 1),
          'Pneumatiques manquantes': (data['pneumatiques_manquantes'] == 1),
          'Véhicule immergé': (data['vehicule_immerge'] == 1),
          'Défauts techniques irréversibles':
              (data['defauts_techniques_irreversibles'] == 1),
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

  String _cleanValue(dynamic value) =>
      value == null || value.toString() == 'null' ? '' : value.toString();

  String _canonicalChoice(String value, List<String> choices) {
    if (value.isEmpty) return '';
    return choices.firstWhere(
      (choice) => choice.toLowerCase() == value.toLowerCase(),
      orElse: () => '',
    );
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
        SnackBar(
            content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    // Le nombre de chiffres varie selon la plaque (0, 00, 000, 0000...) —
    // seul le nombre de lettres de part et d'autre est fixe.
    if (!RegExp(r'^[A-Z]{2}-\d+-[A-Z]{2}$')
        .hasMatch(_numeroController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Le numéro du véhicule doit être au format AB-0000-KO (le nombre de chiffres peut varier).'),
        ),
      );
      return;
    }

    final url = '${Strings.apiURI}vehicule/${widget.signalementId}';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    Map<String, dynamic> updatedDetails = {
      'defaut_controle_technique':
          _details['Défaut de contrôle technique'] == true ? 1 : 0,
      'pneumatiques_manquantes':
          _details['Pneumatiques manquantes'] == true ? 1 : 0,
      'vehicule_immerge': _details['Véhicule immergé'] == true ? 1 : 0,
      'defauts_techniques_irreversibles':
          _details['Défauts techniques irréversibles'] == true ? 1 : 0,
      'vehicule_non_identifiable':
          _details['Véhicule non identifiable'] == true ? 1 : 0,
      'vehicule_brule': _details['Véhicule brûlé'] == true ? 1 : 0,
      'chassis_non_reparable':
          _details['Châssis non réparable'] == true ? 1 : 0,
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
        SnackBar(
          content: Text('Véhicule mis à jour avec succès'),
          duration: Duration(seconds: 1),
        ),
      );

      // Redirection vers la page InfractionForm
      Future.delayed(Duration(seconds: 1), () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                InfractionForm(signalementId: widget.signalementId),
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
        title: const Text('Véhicule'),
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
        child: Scrollbar(
          // Ajouter l'indicateur de défilement
          thumbVisibility: true, // Rendre l'indicateur toujours visible
          thickness: 4.0, // Réduit l'épaisseur de l'indicateur
          radius: Radius.circular(5), // Arrondir les coins
          child: ListView(
            children: [
              _buildSectionTitle('Type de véhicule'),
              const SizedBox(height: 10),
              _buildVehicleKindSelector(),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 10),
              Text(
                'Caractéristiques du Véhicule',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _buildPlateField(),
              _buildBrandField(),
              _buildDropdown(
                  'Type', _typeController, Icons.category, _vehicleTypes),
              _buildField('Modèle', _modeleController, Icons.model_training),
              _buildDropdown('Catégorie du véhicule', _categorieController,
                  Icons.label, _vehicleCategories),
              _buildColorPalette(),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 10),
              _buildSectionTitle('État général'),
              _buildChoiceGroup(const {
                'BON': '✅  Bon',
                'MOYEN': '🟠  Moyen',
                'DEGRADE': '🛠️  Dégradé'
              }, _entretien, (value) {
                setState(() {
                  _entretien = value;
                });
              }),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 10),
              _buildSectionTitle('Pays étranger'),
              _buildChoiceGroup(
                  const {'NON': '🇸🇳  Non', 'OUI': '🌍  Oui'}, _paysEtranger,
                  (value) {
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

  Widget _buildVehicleKindSelector() {
    return Row(
      children: [
        Expanded(
          child: _kindChoice('Voiture', Icons.directions_car_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kindChoice('Moto', Icons.two_wheeler_rounded),
        ),
      ],
    );
  }

  Widget _kindChoice(String label, IconData icon) {
    final selected = _vehicleKind == label;
    return ChoiceChip(
      showCheckmark: false,
      avatar: Icon(icon, color: selected ? SendraTheme.forest : Colors.grey),
      label: SizedBox(
        width: double.infinity,
        child: Text(label, textAlign: TextAlign.center),
      ),
      selected: selected,
      onSelected: (_) => setState(() {
        // Change seulement la liste de marques suggérées — n'efface pas une
        // marque déjà saisie, y compris hors-liste.
        _vehicleKind = label;
      }),
      selectedColor: const Color(0xFFE1F3E8),
      side: BorderSide(
          color: selected ? SendraTheme.green : SendraTheme.border),
    );
  }

  Widget _buildPlateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: _numeroController,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [_PlateInputFormatter()],
        decoration: InputDecoration(
          labelText: 'Numéro du véhicule',
          hintText: 'AB-0000-KO',
          prefixIcon: const Icon(Icons.numbers),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildBrandField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Autocomplete<String>(
        key: ValueKey('marque-$_brandFieldVersion'),
        initialValue: TextEditingValue(text: _marqueController.text),
        optionsBuilder: (TextEditingValue value) {
          if (value.text.isEmpty) return _brandOptions;
          return _brandOptions.where(
            (brand) =>
                brand.toLowerCase().contains(value.text.toLowerCase()),
          );
        },
        onSelected: (selection) => _marqueController.text = selection,
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
          controller.addListener(() {
            _marqueController.text = controller.text;
          });
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: 'Marque',
              hintText: 'Choisissez dans la liste ou saisissez librement',
              prefixIcon: const Icon(Icons.directions_car),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      title: Text(option),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(
      String label, TextEditingController controller, IconData icon) {
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

  Widget _buildDropdown(
    String label,
    TextEditingController controller,
    IconData icon,
    List<String> options,
  ) {
    final selectedValue =
        options.contains(controller.text) ? controller.text : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        initialValue: selectedValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        hint: Text('Sélectionnez ${label.toLowerCase()}'),
        items: options
            .map((option) => DropdownMenuItem(
                  value: option,
                  child: Text(option),
                ))
            .toList(),
        onChanged: (value) => setState(() => controller.text = value ?? ''),
      ),
    );
  }

  Widget _buildColorPalette() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Couleur',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _vehicleColors.entries.map((entry) {
              final selected = _couleurController.text == entry.key;
              return Semantics(
                label: 'Couleur ${entry.key}',
                selected: selected,
                child: InkWell(
                  onTap: () =>
                      setState(() => _couleurController.text = entry.key),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 58,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFE1F3E8) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            selected ? SendraTheme.green : SendraTheme.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: entry.value,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black26),
                          ),
                          child: selected
                              ? Icon(Icons.check,
                                  size: 18,
                                  color: entry.key == 'Noir'
                                      ? Colors.white
                                      : Colors.black87)
                              : null,
                        ),
                        const SizedBox(height: 5),
                        Text(entry.key, style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceGroup(
    Map<String, String> options,
    String? groupValue,
    ValueChanged<String?> onChanged,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.entries.map((entry) {
        final selected = groupValue == entry.key;
        return ChoiceChip(
          label: Text(entry.value),
          selected: selected,
          onSelected: (_) => onChanged(entry.key),
          selectedColor: const Color(0xFFE1F3E8),
          side: BorderSide(
              color: selected ? SendraTheme.green : SendraTheme.border),
          labelStyle: TextStyle(
            color: selected ? SendraTheme.forest : SendraTheme.ink,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRadioGroup(List<String> options, String? groupValue,
      ValueChanged<String?> onChanged) {
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
