import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:walletium/controller/sign_up_controller.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/strings.dart';
import 'signup_layout.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _controller = Get.put(SignUpController());
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final phone =
        _controller.phoneNumberController.text.replaceAll(' ', '').trim();
    try {
      final response = await http.post(
        Uri.parse('${Strings.apiURI}send-verification-code'),
        body: {'telephone': phone},
      ).timeout(const Duration(seconds: 25));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (response.statusCode == 200 && body['success'] == true) {
        Get.toNamed(Routes.phoneVerificationScreen);
      } else {
        setState(() => _error =
            body['message']?.toString() ?? 'Envoi du code impossible.');
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
        title: 'Votre numéro de téléphone',
        subtitle: 'Nous vous enverrons un code pour vérifier votre numéro.',
        step: 1,
        children: [
          Form(
              key: _formKey,
              child: TextFormField(
                controller: _controller.phoneNumberController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                  LengthLimitingTextInputFormatter(12)
                ],
                decoration: signupField(
                    'Numéro de téléphone', Icons.phone_outlined,
                    hint: '77 123 45 67'),
                validator: (value) => RegExp(r'^\d{9}$')
                        .hasMatch((value ?? '').replaceAll(' ', '').trim())
                    ? null
                    : 'Saisissez un numéro de 9 chiffres.',
                onFieldSubmitted: (_) => _continue(),
              )),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFD92D20))),
          ],
          const SizedBox(height: 24),
          signupButton('Continuer', _continue, busy: _busy),
          const SizedBox(height: 12),
          TextButton(
              onPressed: () => Get.offNamed(Routes.signInScreen),
              child: const Text('Déjà inscrit ? Se connecter')),
        ],
      );
}
