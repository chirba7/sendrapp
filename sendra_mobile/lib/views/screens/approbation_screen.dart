import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/strings.dart';
import 'enlevement_screen.dart'; // Assurez-vous que ce fichier contient les URLs nécessaires

class ApprovalForm extends StatefulWidget {
  final int signalementId; // ID du signalement à approuver

  ApprovalForm({required this.signalementId}) {
    print(' ID: $signalementId');
  }

  @override
  _ApprovalFormState createState() => _ApprovalFormState();
}

class _ApprovalFormState extends State<ApprovalForm> {
  final _formKey = GlobalKey<FormState>(); // Key for the form
  bool _isSubmitting = false; // Variable to track if the form is being submitted

  int? _approbation; // Changer le type de _approbation à int
  String? _motifApprobation; // Variable to store the approval reason

  @override
  void initState() {
    super.initState();
    _fetchApprovalDetails(); // Get the current approval details
  }

  Future<void> _fetchApprovalDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = '${Strings.apiURI}motifsApprobation/${widget.signalementId}';

    print(url);
    final response = await http.get(Uri.parse(url), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    print('Response body (récupérée): ${response.body}');
    print('Status code (récupérée): ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _approbation = data['approbation']; // La valeur est maintenant un int
        _motifApprobation = data['motifApprobation'];
      });
    } else {
      print('Échec de la récupération des motifs d\'approbation');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de la récupération des motifs d\'approbation')),
      );
    }
  }

  Future<void> _submitApproval() async {
    if (!_formKey.currentState!.validate()) {
      return; // Arrête si le formulaire n'est pas valide
    }

    _formKey.currentState!.save(); // Sauvegarde les valeurs des champs

    setState(() {
      _isSubmitting = true;
    });

    final token = await SharedPreferences.getInstance().then((prefs) => prefs.getString('token'));

    if (_motifApprobation == null || _motifApprobation!.isEmpty) {
      print('Motif saisi : $_motifApprobation'); // Debug
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le motif d\'approbation est obligatoire.')),
      );
      return;
    }

    final url = '${Strings.apiURI}soumettreApprobation/${widget.signalementId}';
    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'approbation': _approbation == null ? null : (_approbation == 1 ? 'OUI' : 'NON'),
        'motifApprobation': _motifApprobation,
      }),
    );

    print('Request body: ${json.encode({
      'approbation': _approbation == null ? null : (_approbation == 1 ? 'OUI' : 'NON'),
      'motifApprobation': _motifApprobation,
    })}');
    print('Response body (submit): ${response.body}');
    print('Status code (submit): ${response.statusCode}');

    setState(() {
      _isSubmitting = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approbation soumise avec succès'),
          duration: Duration(seconds: 1),
        ),
      );
      // Redirection avec le signalementId
      Future.delayed(Duration(seconds: 1), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RemovalForm(signalementId: widget.signalementId),
          ),
        );
      });
    } else {
      final responseData = json.decode(response.body);
      final errorMessage = responseData['message'] ?? 'Erreur inconnue';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de la soumission de l\'approbation: $errorMessage')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Approbation',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold, // Met le texte en gras
          ),
        ),
        backgroundColor: Colors.green[700],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Form(
          key: _formKey, // Associate the key with the form
          child: ListView(
            children: [
              SizedBox(height: 20),
              Text('Approuver ?', style: TextStyle(fontSize: 16)),
              _buildApprovalRadios(),
              _buildField(
                'Motif d\'Approbation',
                    (value) {
                  if (value == null || value.isEmpty) {
                    return _isSubmitting ? 'Ce champ est obligatoire' : null;
                  }
                  return null; // Validation successful
                },
                    (value) => _motifApprobation = value, // Handle null value
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitApproval,
                child: Text(
                  'Enregistrer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,  // Mettre le texte en gras
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: TextStyle(fontSize: 18.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalRadios() {
    return FormField<String>(
      validator: (value) {
        if (_approbation == null) {
          return _isSubmitting ? 'Ce champ est obligatoire' : null;
        }
        return null; // Validation successful
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('OUI'),
                    value: 'OUI',
                    groupValue: _approbation == 1 ? 'OUI' : 'NON',
                    onChanged: (value) {
                      setState(() {
                        _approbation = value == 'OUI' ? 1 : 0;
                        state.didChange(value); // Update validation state
                      });
                    },
                    activeColor: Colors.green, // Color when selected
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('NON'),
                    value: 'NON',
                    groupValue: _approbation == 0 ? 'NON' : 'OUI',
                    onChanged: (value) {
                      setState(() {
                        _approbation = value == 'NON' ? 0 : 1;
                        state.didChange(value); // Update validation state
                      });
                    },
                    activeColor: Colors.green, // Color when selected
                  ),
                ),
              ],
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  state.errorText!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildField(
      String label,
      FormFieldValidator<String>? validator,
      FormFieldSetter<String>? onSaved) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }
}
