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
        setState(() => _resendSeconds = 60);
        _resendTimer?.cancel();
        _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted || _resendSeconds <= 1) {
            timer.cancel();
            if (mounted) setState(() => _resendSeconds = 0);
          } else {
            setState(() => _resendSeconds--);
          }
        });
      } else {
        setState(() => _error =
            body['message']?.toString() ?? 'Le code n’a pas pu être renvoyé.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Envoi impossible. Vérifiez votre connexion.');
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
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
        setState(
            () => _error = body['message']?.toString() ?? 'Code invalide.');
      }
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Vérification impossible. Réessayez.');
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
