import 'package:flutter/material.dart';

class VehicleDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> vehicleData;

  VehicleDetailsScreen({required this.vehicleData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détails du Véhicule',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight
                .bold, // Ajout de la propriété fontWeight pour le gras
          ),
        ),
        backgroundColor: Colors.green[700],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Scrollbar(
          thumbVisibility:
              true, // Rendre la barre de défilement toujours visible
          thickness: 4, // Épaisseur de la barre de défilement
          radius: Radius.circular(4), // Coins arrondis pour la barre
          child: ListView(
            children: [
              _buildDetailCard('Numéro du véhicule',
                  vehicleData['numero'].toString(), Icons.directions_car),
              _buildDetailCard('Marque', vehicleData['marque'].toString(),
                  Icons.local_car_wash),
              _buildDetailCard(
                  'Type', vehicleData['type'].toString(), Icons.class_),
              _buildDetailCard('Modèle', vehicleData['model'].toString(),
                  Icons.settings_input_component),
              _buildDetailCard('Catégorie', vehicleData['categorie'].toString(),
                  Icons.category),
              _buildDetailCard(
                  'Couleur', vehicleData['couleur'].toString(), Icons.palette),
              _buildDetailCard('État général',
                  vehicleData['entretien'].toString(), Icons.build),
              _buildDetailCard(
                  'Pays étranger',
                  vehicleData['pays_etranger']?.toString() ?? 'Non spécifié',
                  Icons.public),
              _buildBooleanDetail('Défaut contrôle technique',
                  vehicleData['defaut_controle_technique']),
              _buildBooleanDetail('Pneumatiques manquantes',
                  vehicleData['pneumatiques_manquantes']),
              _buildBooleanDetail(
                  'Véhicule immergé', vehicleData['vehicule_immerge']),
              _buildBooleanDetail('Défauts techniques irréversibles',
                  vehicleData['defauts_techniques_irreversibles']),
              _buildBooleanDetail('Véhicule non identifiable',
                  vehicleData['vehicule_non_identifiable']),
              _buildBooleanDetail(
                  'Véhicule brûlé', vehicleData['vehicule_brule']),
              _buildBooleanDetail('Châssis non réparable',
                  vehicleData['chassis_non_reparable']),
              if ((vehicleData['autre_situation']?.toString().trim() ?? '')
                  .isNotEmpty)
                _buildDetailCard(
                    'Autre situation constatée',
                    vehicleData['autre_situation'].toString(),
                    Icons.edit_note_outlined),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.green[700]),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    value,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooleanDetail(String label, int? value) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              value == 1 ? Icons.check_circle : Icons.cancel,
              color: value == 1 ? Colors.green[700] : Colors.red,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    value == 1 ? 'Oui' : 'Non',
                    style: TextStyle(
                        fontSize: 14,
                        color: value == 1 ? Colors.green : Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
