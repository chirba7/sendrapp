import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletium/routes/routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _continue(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);
    Get.offAllNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo_epavie.png',
                      width: double.infinity, height: 130, fit: BoxFit.contain),
                  const SizedBox(height: 30),
                  const Text('Bienvenue sur epaVie',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10251A))),
                  const SizedBox(height: 12),
                  const Text(
                      'Signalez un véhicule et suivez son traitement en toute simplicité.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16, height: 1.5, color: Color(0xFF52665A))),
                  const SizedBox(height: 34),
                  _button(context, 'Se connecter', Routes.signInScreen),
                  const SizedBox(height: 12),
                  _button(context, 'Créer un compte', Routes.signUpScreen,
                      outlined: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _button(BuildContext context, String label, String route,
          {bool outlined = false}) =>
      SizedBox(
        width: double.infinity,
        height: 54,
        child: outlined
            ? OutlinedButton(
                onPressed: () => _continue(route), child: Text(label))
            : FilledButton(
                onPressed: () => _continue(route), child: Text(label)),
      );
}
