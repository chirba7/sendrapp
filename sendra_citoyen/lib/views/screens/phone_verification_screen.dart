import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:walletium/controller/sign_up_controller.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/strings.dart';
import 'signup_layout.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _signup = Get.find<SignUpController>();
  final _code = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  bool _resending = false;
  int _resendSeconds = 0;
  Timer? _resendTimer;
  String? _error;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _resendCode() async {
    if (_resending || _resendSeconds > 0) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      final response = await http.post(
        Uri.parse('${Strings.apiURI}send-verification-code'),
        body: {
          'telephone':
              _signup.phoneNumberController.text.replaceAll(' ', '').trim(),
        },
      ).timeout(const Duration(seconds: 25));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (response.statusCode == 200 && body['success'] == true) {
        _code.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Un nouveau code a été envoyé.')),
        );
        _demarrerCompteARebours(60);
      } else {
        setState(() => _error =
            body['message']?.toString() ?? 'Le code n’a pas pu être renvoyé.');
        // 429 : le serveur dit combien de temps attendre (60 s entre deux
        // codes, 5 par jour) — le bouton « Renvoyer » suit ce délai.
        final attente = int.tryParse(body['retry_after']?.toString() ?? '');
        if (response.statusCode == 429 && attente != null && attente > 0) {
          _demarrerCompteARebours(attente);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Envoi impossible. Vérifiez votre connexion.');
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _demarrerCompteARebours(int secondes) {
    setState(() => _resendSeconds = secondes);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _resendSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response =
          await http.post(Uri.parse('${Strings.apiURI}verify-code'), body: {
        'code': _code.text.trim(),
        'telephone':
            _signup.phoneNumberController.text.replaceAll(' ', '').trim(),
      }).timeout(const Duration(seconds: 25));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (response.statusCode == 200 && body['success'] == true) {
        Get.toNamed(Routes.signUpFinalScreen);
      } else {
        final restants = int.tryParse(body['essais_restants']?.toString() ?? '');
        final message = body['message']?.toString() ?? 'Code invalide.';
        setState(() => _error = (restants != null && restants > 0)
            ? '$message ($restants essai${restants > 1 ? 's' : ''} restant${restants > 1 ? 's' : ''})'
            : message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Vérification impossible. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SignupLayout(
        title: 'Vérifiez votre numéro',
        subtitle:
            'Saisissez le code envoyé au ${_signup.phoneNumberController.text}.',
        step: 2,
        children: [
          Form(
              key: _formKey,
              child: TextFormField(
                controller: _code,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6)
                ],
                decoration: signupField(
                    'Code de vérification', Icons.lock_clock_outlined,
                    hint: '000000'),
                validator: (value) => RegExp(r'^\d{6}$').hasMatch(value ?? '')
                    ? null
                    : 'Saisissez le code à 6 chiffres.',
                onFieldSubmitted: (_) => _verify(),
              )),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFD92D20))),
          ],
          const SizedBox(height: 24),
          signupButton('Vérifier le code', _verify, busy: _busy),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _resending || _resendSeconds > 0 ? null : _resendCode,
            child: Text(_resending
                ? 'Envoi en cours…'
                : _resendSeconds > 0
                    ? 'Renvoyer le code dans $_resendSeconds s'
                    : 'Je n’ai pas reçu le code — renvoyer'),
          ),
        ],
      );
}
