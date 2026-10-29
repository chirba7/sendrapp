import 'package:flutter/material.dart';

class InfractionDetailPage extends StatelessWidget {
  final Map<String, dynamic> infraction;

  const InfractionDetailPage({super.key, required this.infraction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Détails de l\'infraction',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 6,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24), // Angles arrondis plus doux
              ),
              color: Colors.white,
              shadowColor: Colors.black.withValues(alpha: 0.1), // Ombre douce
              child: Padding(
                padding: const EdgeInsets.all(24.0), // Espace autour du contenu
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      context,
                      icon: Icons.location_pin,
                      title: 'Adresse Précise',
                      value: infraction['adresse_precise'] ??
                          'Adresse non disponible',
                    ),
                    _divider(),
                    _buildDetailRow(
                      context,
                      icon: Icons.warning_amber_outlined,
                      title: 'Motif de l\'Infraction',
                      value: infraction['motif_infraction'] ??
                          'Motif non disponible',
                    ),
                    _divider(),
                    _buildDetailRow(
                      context,
                      icon: Icons.map,
                      title: 'Lieu',
                      value: infraction['lieu'] ?? 'Lieu non disponible',
                    ),
                    _divider(),
                    _buildDetailRow(
                      context,
                      icon: Icons.nightlight_round,
                      title: 'Nuit',
                      value: infraction['nuit'] == 1 ? 'Oui' : 'Non',
                    ),
                    _divider(),
                    _buildDetailRow(
                      context,
                      icon: Icons.water_drop,
                      title: 'Pluie',
                      value: infraction['pluie'] == 1 ? 'Oui' : 'Non',
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context,
      {required IconData icon, required String title, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.green[50],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2), // Ombre légère sous l'icône
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Icon(icon, size: 30, color: Colors.green[700]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // Plus de poids pour le titre
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Divider(
      thickness: 1.5,
      height: 30,
      color: Colors.grey[300],
    );
  }
}
