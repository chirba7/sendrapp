import 'package:flutter/material.dart';
import '../../utils/sendra_theme.dart';
import '../../widgets/others/galerie_photos_signalement.dart';
import 'vehicule_screen.dart';

class BasicInfoForm extends StatelessWidget {
  final Map<String, dynamic> signalementData;

  const BasicInfoForm({super.key, required this.signalementData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations de base'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          children: [
            GaleriePhotosSignalement(signalementData: signalementData),
            const SizedBox(height: 20),
            _buildReadOnlyField('Titre', signalementData['titre']?.toString()),
            _buildReadOnlyField(
                'Commune', signalementData['commune']?.toString()),
            _buildReadOnlyField('Date et heure du signalement',
                signalementData['formatted_date']?.toString()),
            // _buildReadOnlyField('Nom Auteur', signalementData['nomAuteur']),
            // _buildReadOnlyField('Prenom Auteur', signalementData['prenomAuteur']),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: SendraTheme.border)),
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              final id =
                  int.tryParse(signalementData['signalementId'].toString());
              if (id == null) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (_) => VehicleForm(signalementId: id)),
              );
            },
            icon: const Icon(Icons.directions_car_outlined),
            label: const Text('Continuer vers le véhicule'),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: TextFormField(
        initialValue: value == null || value == 'null' ? '' : value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600),
          hintText: 'Non renseigné', // Valeur par défaut si vide
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.green[700]!, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.green[700]!, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.green[300]!, width: 1),
          ),
        ),
        readOnly: true,
        style: TextStyle(color: Colors.black, fontSize: 16),
      ),
    );
  }
}
