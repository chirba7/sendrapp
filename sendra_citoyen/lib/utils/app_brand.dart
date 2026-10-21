import 'package:flutter/material.dart';

/// Ce qui distingue l'application Pro (agents) de l'application Citoyen.
/// Les écrans communs (splash, accueil, menu) lisent ces constantes, ce qui
/// permet de garder le même code dans les deux projets.
class AppBrand {
  static const bool isPro = false;
  static const String name = 'epaVie';
  static const String badge = '';
  static const String tagline = 'Agir pour un environnement plus sûr';

  /// Logo horizontal pour la barre du haut.
  static const String appBarLogo = 'assets/images/logo.png';

  /// Pas de logo transparent pour l'application citoyen : le menu affiche
  /// l'icône de l'application et le nom en blanc sur le vert.
  static const String? drawerLogo = null;

  /// Icône de l'application (identique au splash natif Android).
  static const String appIcon = 'assets/images/splash/app_icon.png';

  /// Clé du guide de prise en main (affiché une seule fois, après la
  /// première connexion).
  static const String guideSeenKey = 'hasSeenSlides';

  static const List<GuideStep> guide = [
    GuideStep(
      icon: Icons.waving_hand_rounded,
      title: "Bienvenue sur epaVie",
      text:
          "Aidez à libérer l'espace public en signalant les véhicules abandonnés près de chez vous.",
    ),
    GuideStep(
      icon: Icons.add_a_photo_rounded,
      title: "Signaler en 1 minute",
      text:
          "Touchez « Signaler », prenez une photo du véhicule : la position est ajoutée automatiquement.",
    ),
    GuideStep(
      icon: Icons.track_changes_rounded,
      title: "Suivre vos signalements",
      text:
          "L'onglet Participations affiche chacun de vos signalements et l'avancement de son traitement.",
    ),
    GuideStep(
      icon: Icons.map_rounded,
      title: "La cartographie",
      text: "Visualisez les signalements autour de vous sur la carte.",
    ),
  ];
}

class GuideStep {
  const GuideStep({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;
}
