import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletium/routes/routes.dart';

import '../../utils/app_brand.dart';
import '../../utils/sendra_theme.dart';

/// Écran de bienvenue (première ouverture de l'application).
///
/// Il occupe toute la page, barre d'état et barre de navigation comprises,
/// dans le vert du splash : le passage splash → bienvenue est continu. Le
/// contenu défile seulement si l'écran est trop petit (Fold fermé).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _continue(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);
    Get.offAllNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    const points = AppBrand.isPro
        ? <(IconData, String)>[
            (Icons.assignment_turned_in_rounded, 'Prenez en charge les signalements proches'),
            (Icons.fact_check_rounded, 'Constatez, annotez les dommages et signez le PV'),
            (Icons.local_shipping_rounded, 'Suivez vos missions d’enlèvement'),
          ]
        : <(IconData, String)>[
            (Icons.add_a_photo_rounded, 'Signalez un véhicule en une photo'),
            (Icons.timeline_rounded, 'Suivez chaque étape du traitement'),
            (Icons.map_rounded, 'Voyez les signalements autour de vous'),
          ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SendraTheme.overlayGreen.copyWith(
        systemNavigationBarColor: SendraTheme.forest,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: SendraTheme.forest,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(top: -90, right: -70, child: _Circle(260, .07)),
            const Positioned(bottom: -130, left: -105, child: _Circle(330, .06)),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, c) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: c.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const Spacer(flex: 2),
                          const SizedBox(height: 24),
                          Image.asset(AppBrand.appIcon, width: 96, height: 96),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Image.asset(
                                  AppBrand.wordmarkWhite,
                                  height: 46,
                                  fit: BoxFit.contain,
                                  semanticLabel: AppBrand.name,
                                ),
                              ),
                              if (AppBrand.badge.isNotEmpty) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF111111),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    AppBrand.badge,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppBrand.tagline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .85),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(flex: 2),
                          const SizedBox(height: 28),
                          for (final p in points) _Point(icon: p.$1, text: p.$2),
                          const Spacer(),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: SendraTheme.forest,
                                textStyle: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              onPressed: () => _continue(Routes.signInScreen),
                              child: const Text('Se connecter'),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle(this.size, this.opacity);
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
