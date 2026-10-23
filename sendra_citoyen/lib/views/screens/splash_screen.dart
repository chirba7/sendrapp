import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/app_brand.dart';
import '../../utils/sendra_theme.dart';

/// Splash animé.
///
/// Il démarre EXACTEMENT dans l'état du splash natif Android (même fond
/// vert #075C32, même icône, même taille, au centre) : le passage du natif
/// au Flutter est donc invisible. L'icône monte ensuite légèrement pendant
/// que le nom de l'application apparaît. Seules des animations de
/// transformation/opacité sont utilisées (pas d'ombre, pas de flou) pour
/// rester à 60 i/s même sur les téléphones d'entrée de gamme.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Taille de l'icône dans le splash natif (288 dp × 50 %).
  static const double nativeIconSize = 144;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  late final Animation<double> _iconMove = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, .65, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _textIn = CurvedAnimation(
    parent: _c,
    curve: const Interval(.3, .9, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _footerIn = CurvedAnimation(
    parent: _c,
    curve: const Interval(.6, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    // Petite pause pour que la première image soit identique au natif.
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SendraTheme.overlayGreen,
      child: Scaffold(
        backgroundColor: SendraTheme.forest,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Décor discret, qui apparaît en fondu.
            FadeTransition(
              opacity: _footerIn,
              child: const Stack(children: [
                Positioned(
                  top: -90,
                  right: -70,
                  child: _SplashCircle(size: 260, opacity: .06),
                ),
                Positioned(
                  bottom: -130,
                  left: -105,
                  child: _SplashCircle(size: 330, opacity: .05),
                ),
              ]),
            ),
            // Icône + nom, centrés comme le splash natif.
            Center(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final t = _iconMove.value;
                  final text = _textIn.value;
                  return Transform.translate(
                    offset: Offset(0, -64 * t),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: 1 - .18 * t,
                          child: Image.asset(
                            AppBrand.appIcon,
                            width: SplashScreen.nativeIconSize,
                            height: SplashScreen.nativeIconSize,
                            filterQuality: FilterQuality.medium,
                            gaplessPlayback: true,
                          ),
                        ),
                        // La hauteur du texte est réservée dès le départ
                        // (Opacity), l'icône reste donc parfaitement centrée.
                        Opacity(
                          opacity: text,
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - text)),
                            child: const _BrandText(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Indicateur de chargement en bas.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: FadeTransition(
                    opacity: _footerIn,
                    child: const Center(
                      child: SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
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

class _BrandText extends StatelessWidget {
  const _BrandText();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 0,
      child: OverflowBox(
        maxHeight: 120,
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logotype « epAvie » (même dessin que le logo) à la place
                  // du nom écrit en police.
                  Image.asset(
                    AppBrand.wordmarkWhite,
                    height: 40,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    semanticLabel: AppBrand.name,
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
                          fontFamily: SendraTheme.fontFamily,
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
              const SizedBox(height: 8),
              Text(
                AppBrand.tagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: SendraTheme.fontFamily,
                  color: Colors.white.withValues(alpha: .82),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashCircle extends StatelessWidget {
  const _SplashCircle({required this.size, required this.opacity});

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
