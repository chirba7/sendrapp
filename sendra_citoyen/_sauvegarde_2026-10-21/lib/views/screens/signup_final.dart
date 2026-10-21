import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:walletium/controller/sign_up_controller.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/strings.dart';
import 'signup_layout.dart';

class SignUpFinalScreen extends StatefulWidget {
  const SignUpFinalScreen({super.key});

  @override
  State<SignUpFinalScreen> createState() => _SignUpFinalScreenState();
}

class _SignUpFinalScreenState extends State<SignUpFinalScreen> {
  final _controller = Get.find<SignUpController>();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final fullName = _controller.nameController.text.trim();
    final nameParts = fullName.split(RegExp(r'\s+'));
    try {
      final response =
          await http.post(Uri.parse('${Strings.apiURI}register'), body: {
        'telephone':
            _controller.phoneNumberController.text.replaceAll(' ', '').trim(),
        'first_name': nameParts.first,
        'last_name': nameParts.length > 1
            ? nameParts.sublist(1).join(' ')
            : nameParts.first,
        'password': _controller.passwordController.text,
      }).timeout(const Duration(seconds: 25));
      if (!mounted) return;
      if (response.statusCode == 200) {
        Get.offAllNamed(Routes.signUpCongratulationsScreen);
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() =>
            _error = body['message']?.toString() ?? 'Inscription impossible.');
      }
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Connexion indisponible. Réessayez.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupLayout(
        title: 'Finalisez votre compte',
        subtitle: 'Renseignez votre nom et choisissez un mot de passe.',
        step: 3,
        children: [
          Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  controller: _controller.nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      signupField('Nom complet', Icons.person_outline_rounded),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Saisissez votre nom.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controller.passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration:
                      signupField('Mot de passe', Icons.lock_outline_rounded),
                  validator: (value) => (value ?? '').length < 8
                      ? 'Utilisez au moins 8 caractères.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controller.confirmPasswordController,
                  obscureText: true,
                  decoration: signupField(
                      'Confirmer le mot de passe', Icons.lock_reset_rounded),
                  validator: (value) =>
                      value != _controller.passwordController.text
                          ? 'Les mots de passe ne correspondent pas.'
                          : null,
                ),
              ])),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFD92D20))),
          ],
          const SizedBox(height: 24),
          signupButton('Créer mon compte', _register, busy: _busy),
        ],
      );
}
