import 'package:flutter/material.dart';

/// Ce qui distingue l'application Pro (agents) de l'application Citoyen.
/// Les écrans communs (splash, accueil, menu) lisent ces constantes, ce qui
/// permet de garder le même code dans les deux projets.
class AppBrand {
  static const bool isPro = true;
  static const String name = 'epaVie';
  static const String badge = 'PRO';
  static const String tagline = 'Agir pour un environnement plus sûr';

  /// Logo horizontal (bannière verte, lettres noires) pour la barre du haut.
  static const String appBarLogo = 'assets/images/logo_epavie_pro.png';

  /// Logo sur fond transparent, posé directement sur le vert du menu.
  static const String? drawerLogo = 'assets/images/logo_epavie_pro.png';

  /// Icône de l'application (identique au splash natif Android).
  static const String appIcon = 'assets/images/splash/app_icon.png';

  /// Clé du guide de prise en main (affiché une seule fois, après la
  /// première connexion).
  static const String guideSeenKey = 'hasSeenSlides';

  static const List<GuideStep> guide = [
    GuideStep(
      icon: Icons.waving_hand_rounded,
      title: "Bienvenue sur epaVie Pro",
      text:
          "Votre outil de terrain pour constater, traiter et enlever les véhicules signalés.",
    ),
    GuideStep(
      icon: Icons.list_alt_rounded,
      title: "Les signalements",
      text:
          "L'onglet Participations liste les dossiers. Filtrez par statut et touchez un dossier pour l'ouvrir.",
    ),
    GuideStep(
      icon: Icons.fact_check_rounded,
      title: "La constatation",
      text:
          "Dans un dossier, complétez dans l'ordre : véhicule, infraction, dommages, puis soumettez à l'approbation.",
    ),
    GuideStep(
      icon: Icons.local_shipping_rounded,
      title: "Les missions",
      text:
          "L'onglet Mission regroupe les enlèvements qui vous sont affectés, avec leur suivi.",
    ),
    GuideStep(
      icon: Icons.map_rounded,
      title: "La cartographie",
      text:
          "Visualisez les signalements autour de vous et lancez l'itinéraire en un geste.",
    ),
  ];
}

class GuideStep {
  const GuideStep({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;
}
