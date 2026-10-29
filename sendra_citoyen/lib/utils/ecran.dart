import 'package:flutter/widgets.dart';

/// Repères de mise en page communs à tous les écrans.
extension Ecran on BuildContext {
  /// Écran étroit : Fold fermé, petits Android (moins de 360 dp de large).
  bool get ecranEtroit => MediaQuery.sizeOf(this).width < 360;

  /// Hauteur de la barre de navigation du téléphone à laisser libre en bas
  /// d'une liste. Vaut 0 quand elle est déjà gérée plus haut (SafeArea,
  /// barre d'onglets) : on peut l'ajouter sans risque de double marge.
  double get margeBasSysteme => MediaQuery.paddingOf(this).bottom;
}

/// Photo décodée à la taille où elle est affichée (vignette, tuile) plutôt
/// qu'en pleine résolution : beaucoup moins de mémoire et de calcul, donc un
/// défilement fluide même avec plusieurs photos de 1 800 px à l'écran.
ImageProvider vignette(
  BuildContext context,
  ImageProvider image,
  double largeurAffichee,
) {
  final pixels =
      (largeurAffichee * MediaQuery.devicePixelRatioOf(context)).round();
  return ResizeImage.resizeIfNeeded(pixels, null, image);
}
