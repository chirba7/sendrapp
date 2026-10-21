import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletium/utils/strings.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  File? _photo;
  String? _photoUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = prefs.getString('fullName')?.trim() ?? '';
    if (!mounted) return;
    setState(() {
      _firstName.text =
          prefs.getString('firstName') ??
          (fullName.contains(' ') ? fullName.split(' ').first : fullName);
      _lastName.text =
          prefs.getString('lastName') ??
          (fullName.contains(' ')
              ? fullName.substring(fullName.indexOf(' ') + 1)
              : '');
      _photoUrl = prefs.getString('profilePhotoUrl');
    });
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('Photo de profil')),
          ListTile(leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Prendre une photo'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Importer une photo'),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery)),
        ],
      )),
    );
    if (source == null) return;
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (file != null && mounted) setState(() => _photo = File(file.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) throw Exception('Session expirée');
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Strings.apiURI}profile'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['first_name'] = _firstName.text.trim();
      request.fields['last_name'] = _lastName.text.trim();
      if (_photo != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', _photo!.path),
        );
      }
      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 404) {
        throw Exception(
          'La mise à jour du profil n’est pas encore disponible sur le serveur. '
          'Contactez l’administrateur pour déployer l’API.',
        );
      }
      if (response.statusCode != 200) {
        throw Exception('Enregistrement impossible (${response.statusCode}).');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await prefs.setString('firstName', data['first_name'] as String);
      await prefs.setString('lastName', data['last_name'] as String);
      await prefs.setString('fullName', data['fullName'] as String);
      if (data['photo_url'] != null) {
        await prefs.setString('profilePhotoUrl', data['photo_url'] as String);
      }
      if (!mounted) return;
      Get.back(result: true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _photo != null
        ? FileImage(_photo!) as ImageProvider
        : (_photoUrl != null && _photoUrl!.isNotEmpty
              ? NetworkImage(_photoUrl!) as ImageProvider
              : null);
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le profil')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: InkWell(
                  onTap: _pickPhoto,
                  borderRadius: BorderRadius.circular(60),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundImage: image,
                    child: image == null
                        ? const Icon(Icons.add_a_photo, size: 36)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: Text('Touchez la photo pour la modifier')),
              const SizedBox(height: 28),
              Text('Informations personnelles', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: _firstName,
                decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.words,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Saisissez votre prénom.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastName,
                decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(Icons.badge_outlined), border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.words,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Saisissez votre nom.'
                    : null,
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                icon: const Icon(Icons.check),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52),
                  backgroundColor: const Color(0xFF0B7D4A)),
                onPressed: _saving ? null : _save,
                label: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
