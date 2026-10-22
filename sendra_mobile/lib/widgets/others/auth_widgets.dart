import 'package:flutter/material.dart';

import '../../utils/app_brand.dart';
import '../../utils/sendra_theme.dart';

/// Éléments communs aux écrans de connexion et d'inscription, pour qu'ils
/// partagent exactement le même habillage (fond, logo, titres).

/// Fond clair avec les deux cercles décoratifs verts.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          top: -105,
          left: -95,
          child: _Circle(size: 255, color: Color(0xFFE1F3E8)),
        ),
        const Positioned(
          top: 115,
          right: -85,
          child: _Circle(size: 190, color: Color(0xFFECF7F0)),
        ),
        child,
      ],
    );
  }
}

/// Carte blanche contenant le logo de l'application.
class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18, compact ? 16 : 22, 18, compact ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1EBE5)),
        boxShadow: [
          BoxShadow(
            color: SendraTheme.forest.withValues(alpha: .08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Image.asset(
        AppBrand.appBarLogo,
        height: compact ? 64 : 84,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Titre + sous-titre centrés, mêmes tailles sur tous les écrans d'accès.
class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: SendraTheme.ink,
            fontSize: 26,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: SendraTheme.muted,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});
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
