import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignupLayout extends StatelessWidget {
  const SignupLayout(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.step,
      required this.children});

  final String title;
  final String subtitle;
  final int step;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF7FAF8),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7FAF8),
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Retour',
          ),
          title: const Text('Créer un compte'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset('assets/images/logo.png',
                          height: 82, fit: BoxFit.contain),
                      const SizedBox(height: 26),
                      Text('Étape $step sur 3',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Color(0xFF07883F),
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Text(title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF18221D))),
                      const SizedBox(height: 8),
                      Text(subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15, color: Color(0xFF66716B))),
                      const SizedBox(height: 30),
                      ...children,
                      const SizedBox(height: 28),
                      const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user_outlined,
                                color: Color(0xFF07883F), size: 19),
                            SizedBox(width: 8),
                            Text('Espace citoyen',
                                style: TextStyle(color: Color(0xFF66716B))),
                          ]),
                    ]),
              ),
            ),
          ),
        ),
      );
}

InputDecoration signupField(String label, IconData icon, {String? hint}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD8E1DC))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF07883F), width: 1.6)),
    );

Widget signupButton(String label, VoidCallback? onPressed,
        {bool busy = false}) =>
    SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: busy ? null : onPressed,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF07883F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14))),
          child: busy
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
        ));
