import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../controller/sign_in_controller.dart';
import '../../routes/routes.dart';
import '../../utils/session.dart';
import '../../utils/strings.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  static const _green = Color(0xFF07883F);
  static const _forest = Color(0xFF075C32);
  static const _ink = Color(0xFF18221D);
  static const _muted = Color(0xFF66716B);

  final SignInController _controller = Get.put(SignInController());
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _errorMessage = '';
  bool _obscureText = true;
  bool _isLoading = false;

  String _formatPhoneNumber(String text) {
    final digits = text.replaceAll(' ', '');
    final limited = digits.length > 9 ? digits.substring(0, 9) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i == 2 || i == 5 || i == 7) buffer.write(' ');
      buffer.write(limited[i]);
    }
    return buffer.toString();
  }

  String _cleanPhoneNumber(String phone) => phone.replaceAll(' ', '');

  Future<void> _saveUserData(
    String fullName,
    String phone,
    String id,
    String token,
    int? roleId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', fullName);
    await prefs.setString('phone', phone);
    await prefs.setString('userId', id);
    await prefs.setString('token', token);
    await Session.saveRoleId(roleId);
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final phone = _cleanPhoneNumber(_controller.emailOrUserNameController.text);
    final password = _controller.passwordController.text;

    try {
      final response = await http.post(
        Uri.parse('${Strings.apiURI}login'),
        body: {'telephone': phone, 'password': password},
      ).timeout(const Duration(seconds: 25));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        if (jsonResponse['success'] == true) {
          final roleId = jsonResponse['role_id'] is int
              ? jsonResponse['role_id'] as int
              : int.tryParse(jsonResponse['role_id']?.toString() ?? '');
          await _saveUserData(
            jsonResponse['fullName'].toString(),
            phone,
            jsonResponse['userId'].toString(),
            jsonResponse['token'].toString(),
            roleId,
          );
          if (!mounted) return;
          setState(() => _isLoading = false);
          Get.offAllNamed(Routes.bottomNavigationScreen);
          return;
        }
        setState(() {
          _errorMessage = jsonResponse['error']?.toString() ??
              'Impossible de vous connecter.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _errorMessage = response.statusCode == 401
            ? 'Numéro de téléphone ou mot de passe incorrect.'
            : 'Le service est momentanément indisponible. Réessayez plus tard.';
        _isLoading = false;
      });
    } on SocketException {
      _showRequestError(
        'Connexion indisponible. Vérifiez votre accès à Internet.',
      );
    } on TimeoutException {
      _showRequestError(
          'La connexion prend trop de temps. Veuillez réessayer.');
    } catch (_) {
      _showRequestError(
          'Une erreur inattendue est survenue. Veuillez réessayer.');
    }
  }

  void _showRequestError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9AA39E)),
      prefixIcon: Icon(icon, color: _muted, size: 21),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      enabledBorder: border(const Color(0xFFD8E1DC)),
      focusedBorder: border(_green, 1.6),
      errorBorder: border(const Color(0xFFD92D20), 1.3),
      focusedErrorBorder: border(const Color(0xFFD92D20), 1.6),
      errorMaxLines: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: Stack(
        children: [
          const Positioned(
            top: -105,
            left: -95,
            child: _DecorativeCircle(size: 255, color: Color(0xFFE1F3E8)),
          ),
          const Positioned(
            top: 115,
            right: -85,
            child: _DecorativeCircle(size: 190, color: Color(0xFFECF7F0)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 38,
                    ),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _brand(),
                            const SizedBox(height: 28),
                            const Text(
                              'Bienvenue',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _ink,
                                fontSize: 30,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 9),
                            const Text(
                              'Connectez-vous pour accéder à vos signalements',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _muted,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 30),
                            _label('Numéro de téléphone'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _controller.emailOrUserNameController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.telephoneNumber
                              ],
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(12),
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9 ]'),
                                ),
                              ],
                              onChanged: (value) {
                                final formatted = _formatPhoneNumber(value);
                                if (formatted != value) {
                                  _controller.emailOrUserNameController.value =
                                      TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                      offset: formatted.length,
                                    ),
                                  );
                                }
                                if (_errorMessage.isNotEmpty) {
                                  setState(() => _errorMessage = '');
                                }
                              },
                              validator: (value) {
                                final cleaned =
                                    _cleanPhoneNumber(value?.trim() ?? '');
                                if (cleaned.isEmpty) {
                                  return 'Veuillez saisir votre numéro de téléphone.';
                                }
                                if (!RegExp(r'^\d{9}$').hasMatch(cleaned)) {
                                  return 'Le numéro doit contenir exactement 9 chiffres.';
                                }
                                return null;
                              },
                              decoration: _fieldDecoration(
                                hint: '77 123 45 67',
                                icon: Icons.phone_outlined,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _label('Mot de passe'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _controller.passwordController,
                              obscureText: _obscureText,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _signIn(),
                              onChanged: (_) {
                                if (_errorMessage.isNotEmpty) {
                                  setState(() => _errorMessage = '');
                                }
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Veuillez saisir votre mot de passe.'
                                      : null,
                              decoration: _fieldDecoration(
                                hint: 'Votre mot de passe',
                                icon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  tooltip: _obscureText
                                      ? 'Afficher le mot de passe'
                                      : 'Masquer le mot de passe',
                                  onPressed: () => setState(
                                    () => _obscureText = !_obscureText,
                                  ),
                                  icon: Icon(
                                    _obscureText
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: _muted,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _forgotPasswordScreen(context),
                                child: const Text(
                                  'Mot de passe oublié ?',
                                  style: TextStyle(
                                    color: _forest,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            if (_errorMessage.isNotEmpty) ...[
                              _errorBanner(),
                              const SizedBox(height: 14),
                            ],
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signIn,
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: _green,
                                  disabledBackgroundColor:
                                      _green.withValues(alpha: .65),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox.square(
                                        dimension: 23,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Se connecter',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Vous n’avez pas encore de compte ?',
                                    style: TextStyle(
                                      color: _muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => Get.toNamed(Routes.signUpScreen),
                                  child: const Text(
                                    'Créer un compte',
                                    style: TextStyle(
                                      color: _forest,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const SizedBox(height: 26),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  color: _green,
                                  size: 19,
                                ),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Accès réservé aux agents autorisés',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _muted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _brand() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 86,
          width: 250,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.recycling_rounded,
            size: 72,
            color: _green,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Sénégalaise de Déconstruction et de Recyclage Automobile',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 10.5),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _forest,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFD92D20), size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _errorMessage,
              style: const TextStyle(
                color: Color(0xFF9E1C13),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _forgotPasswordScreen(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const CircleAvatar(
          radius: 28,
          backgroundColor: Color(0xFFE5F4EB),
          child: Icon(Icons.lock_reset_rounded, color: _green, size: 30),
        ),
        title: const Text(
          'Mot de passe oublié',
          textAlign: TextAlign.center,
          style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Nous allons vérifier votre numéro de téléphone avant de réinitialiser votre mot de passe.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Get.toNamed(Routes.otpVerificationScreen);
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continuer',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
