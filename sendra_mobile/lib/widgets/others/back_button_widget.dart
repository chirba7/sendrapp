import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bouton retour unifié : icône vectorielle qui prend la couleur de la barre
/// du haut (au lieu d'une image PNG blanche ou noire selon les écrans).
/// Le paramètre [backButtonImage] est conservé pour compatibilité.
class BackButtonWidget extends StatelessWidget {
  const BackButtonWidget({Key? key, this.backButtonImage}) : super(key: key);
  final String? backButtonImage;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Retour',
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => Get.back(),
    );
  }
}
