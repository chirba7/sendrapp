import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../utils/strings.dart';
import 'deposit_money_details_screen.dart'; // Pour encoder les données en JSON

class RemovalForm extends StatefulWidget {
  final int signalementId;

  RemovalForm({required this.signalementId});

  @override
  _RemovalFormState createState() => _RemovalFormState();
}

class _RemovalFormState extends State<RemovalForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController _motifController = TextEditingController();
  final TextEditingController _lieuController = TextEditingController();
  final TextEditingController _nomResponsableController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Enlèvement',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold, // Mettre le texte en gras
          ),
        ),
        backgroundColor: Colors.green[700],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(
                  'Motif d\'enlèvement',
                  _motifController,
                      (value) {
                    if (value == null || value.isEmpty) {
                      return _isSubmitting ? 'Ce champ est obligatoire' : null;
                    }
                    if (value.length > 255) {
                      return 'Le motif ne peut pas dépasser 255 caractères';
                    }
                    return null;
                  },
                ),
                _buildDateField('Date de l\'enlèvement'),
                _buildField(
                  'Lieu de l\'enlèvement',
                  _lieuController,
                      (value) {
                    if (value == null || value.isEmpty) {
                      return _isSubmitting ? 'Ce champ est obligatoire' : null;
                    }
                    if (value.length > 255) {
                      return 'Le lieu ne peut pas dépasser 255 caractères';
                    }
                    return null;
                  },
                ),
                _buildField(
                  'Nom Responsable de l\'enlèvement',
                  _nomResponsableController,
                      (value) {
                    if (value == null || value.isEmpty) {
                      return _isSubmitting ? 'Ce champ est obligatoire' : null;
                    }
                    if (value.length > 255) {
                      return 'Le nom du responsable ne peut pas dépasser 255 caractères';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, FormFieldValidator<String>? validator) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.text_fields, color: Colors.green[700]),
          labelText: label,
          labelStyle: TextStyle(color: Colors.black),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green[700]!, width: 2),
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDateField(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: TextFormField(
        controller: dateController,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.calendar_today, color: Colors.green[700]),
          labelText: label,
          labelStyle: TextStyle(color: Colors.black),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green[700]!, width: 2),
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        keyboardType: TextInputType.url,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return _isSubmitting ? 'Ce champ est obligatoire' : null;
          }
          try {
            DateFormat('yyyy-MM-dd').parseStrict(value);
          } catch (e) {
            return 'La date doit être au format YYYY-MM-DD';
          }
          return null;
        },
        onTap: () async {
          FocusScope.of(context).requestFocus(FocusNode()); // Ferme le clavier
          DateTime? selectedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
          );

          if (selectedDate != null) {
            String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
            setState(() {
              dateController.text = formattedDate;
            });
          }
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _isSubmitting = true;
          });
          if (_formKey.currentState!.validate()) {
            _submitForm();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Veuillez remplir tous les champs'),),
            );
          }
        },
        child: Text(
          'Enregistrer',
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 40.0),
          textStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    final url = '${Strings.apiURI}enlevement/${widget.signalementId}';
    print(url);

    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'motif': _motifController.text,
        'date': dateController.text,
        'lieu': _lieuController.text,
        'nom_responsable': _nomResponsableController.text,
      }),
    );

    print(response.statusCode);
    print(response.body);
    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enlèvement enregistré avec succès'),
          duration: Duration(seconds: 1),
        ),
      );

      // Rediriger vers la page de d'accueil
      Future.delayed(Duration(seconds: 1), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DepositMoneyDetailsScreen(),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de l\'enregistrement de l\'enlèvement')),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }
}
