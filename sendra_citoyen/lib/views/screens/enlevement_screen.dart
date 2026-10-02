import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../routes/routes.dart';
import '../../utils/strings.dart';
import '../../utils/sendra_theme.dart';

class RemovalForm extends StatefulWidget {
  final int signalementId;

  const RemovalForm({super.key, required this.signalementId});

  @override
  _RemovalFormState createState() => _RemovalFormState();
}

class _RemovalFormState extends State<RemovalForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController _motifController = TextEditingController();
  final TextEditingController _lieuController = TextEditingController();
  final TextEditingController _nomResponsableController =
      TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enlèvement'),
        backgroundColor: Colors.white,
        foregroundColor: SendraTheme.ink,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informations d’enlèvement',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Renseignez les informations après approbation administrative.',
                  style: TextStyle(color: SendraTheme.muted, height: 1.4),
                ),
                const SizedBox(height: 14),
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
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: SendraTheme.border)),
          ),
          child: _buildSubmitButton(),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      FormFieldValidator<String>? validator) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.edit_outlined, color: SendraTheme.green),
          labelText: label,
          labelStyle: TextStyle(color: Colors.black),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: SendraTheme.green, width: 1.5),
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDateField(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: TextFormField(
        controller: dateController,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.calendar_today_outlined,
              color: SendraTheme.green),
          labelText: label,
          labelStyle: TextStyle(color: Colors.black),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: SendraTheme.green, width: 1.5),
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
            String formattedDate =
                DateFormat('yyyy-MM-dd').format(selectedDate);
            setState(() {
              dateController.text = formattedDate;
            });
          }
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _isSubmitting = true;
          });
          if (_formKey.currentState!.validate()) {
            _submitForm();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Veuillez remplir tous les champs'),
              ),
            );
          }
        },
        icon: _isSubmitting
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.check_circle_outline_rounded),
        label: const Text('Enregistrer l’enlèvement'),
        style: ElevatedButton.styleFrom(
          backgroundColor: SendraTheme.green,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Votre session a expiré. Veuillez vous reconnecter.')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
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
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.depositMoneyDetailsScreen,
          ModalRoute.withName(Routes.bottomNavigationScreen),
          arguments: widget.signalementId,
        );
      });
    } else {
      String message = 'Échec de l’enregistrement de l’enlèvement';
      try {
        final responseBody = jsonDecode(response.body);
        if (responseBody['message'] is String) {
          message = responseBody['message'];
        } else if (response.statusCode == 422 &&
            responseBody['errors'] is Map) {
          message = (responseBody['errors'] as Map)
              .values
              .expand((errors) => errors is List ? errors : [errors])
              .join('\n');
        }
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }
}
