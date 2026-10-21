import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/sendra_theme.dart';
import '../../widgets/others/auth_widgets.dart';

/// Gabarit des 3 étapes d'inscription — même habillage que l'écran de
/// connexion (fond, carte logo, titres, champs, bouton).
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

  static const totalSteps = 3;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: SendraTheme.surface,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Retour',
          ),
        ),
        body: AuthBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AuthBrand(compact: true),
                        const SizedBox(height: 24),
                        // Progression de l'inscription.
                        Row(
                          children: [
                            for (var i = 1; i <= totalSteps; i++) ...[
                              Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: i <= step
                                        ? SendraTheme.green
                                        : SendraTheme.border,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                              if (i < totalSteps) const SizedBox(width: 6),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('Étape $step sur $totalSteps',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: SendraTheme.green,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 14),
                        AuthHeading(title: title, subtitle: subtitle),
                        const SizedBox(height: 28),
                        ...children,
                      ]),
                ),
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
    );

Widget signupButton(String label, VoidCallback? onPressed,
        {bool busy = false}) =>
    SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: busy ? null : onPressed,
          child: busy
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
        ));
