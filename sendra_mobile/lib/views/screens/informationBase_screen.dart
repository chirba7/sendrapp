import 'package:flutter/material.dart';

class BasicInfoForm extends StatelessWidget {
  final Map<String, dynamic> signalementData;

  BasicInfoForm({required this.signalementData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Informations de base',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,  // Mise en gras du texte
          ),
        ),
        backgroundColor: Colors.green[700],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            _buildImageContainer(signalementData['image_url'], context),
            SizedBox(height: 20),
            _buildReadOnlyField('Titre', signalementData['titre']),
            _buildReadOnlyField('Commune', signalementData['commune']),
            _buildReadOnlyField('Date et heure du signalement', signalementData['formatted_date']),
            // _buildReadOnlyField('Nom Auteur', signalementData['nomAuteur']),
            // _buildReadOnlyField('Prenom Auteur', signalementData['prenomAuteur']),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600),
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

  Widget _buildImageContainer(String imageUrl, BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        );
      },
      child: Column(
        children: [
          Text(
            'Appuyez pour agrandir l\'image',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 3), // décalage de l'ombre
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
