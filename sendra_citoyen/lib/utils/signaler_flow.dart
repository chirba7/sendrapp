import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../routes/routes.dart';
import 'app_prefs.dart';

/// Parcours « Signaler » : le bouton ouvre directement l'appareil photo,
/// puis la photo prise ouvre le formulaire (type de véhicule, description
/// facultative, validation).
class SignalerFlow {
  SignalerFlow._();

  static bool _ouvert = false;

  /// Marque une capture en cours : sur Android, le système peut tuer l'app
  /// pendant que l'appareil photo est ouvert (mémoire basse). Au redémarrage,
  /// [recupererPhotoPerdue] retrouve la photo et ouvre le formulaire.
  static const _cleCapture = 'signaler_capture_en_cours';

  static Future<void> demarrer(BuildContext context) async {
    if (_ouvert) return;
    _ouvert = true;
    try {
      final prefs = await AppPrefs.init();
      await prefs.setBool(_cleCapture, true);
      XFile? prise;
      try {
        prise = await prendrePhoto();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Impossible d’ouvrir l’appareil photo. Vérifiez l’autorisation Caméra.'),
          ));
        }
      }
      await prefs.remove(_cleCapture);
      if (prise == null) return;
      final photo = await optimiser(prise);
      await Get.toNamed(Routes.depositScreen, arguments: photo);
    } finally {
      _ouvert = false;
    }
  }

  /// Ouvre l'appareil photo arrière. La photo est déjà réduite par le
  /// téléphone (2000 px) : capture plus rapide et moins de mémoire.
  static Future<XFile?> prendrePhoto() => ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
        requestFullMetadata: false,
      );

  /// À appeler à l'arrivée sur l'accueil : si l'app a été tuée pendant la
  /// capture, on récupère la photo et on rouvre le formulaire.
  static Future<void> recupererPhotoPerdue() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final prefs = await AppPrefs.init();
    if (prefs.getBool(_cleCapture) != true) return;
    await prefs.remove(_cleCapture);
    try {
      final perdue = await ImagePicker().retrieveLostData();
      final fichier = perdue.file;
      if (perdue.isEmpty || fichier == null) return;
      final photo = await optimiser(fichier);
      Get.toNamed(Routes.depositScreen, arguments: photo);
    } catch (_) {
      // Rien à récupérer : l'utilisateur relancera la capture.
    }
  }

  /// Redresse la photo selon l'orientation du téléphone (EXIF appliquée aux
  /// pixels), la réduit à ~1600 px et la réencode en JPEG : l'envoi est
  /// 3 à 5 fois plus léger et la photo n'apparaît plus pivotée.
  static Future<XFile> optimiser(XFile source) async {
    // Web (démo) : pas de recompression, le navigateur garde la photo telle quelle.
    if (kIsWeb) return source;
    try {
      final dossier = await getTemporaryDirectory();
      final cible =
          '${dossier.path}/signalement_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final resultat = await FlutterImageCompress.compressAndGetFile(
        source.path,
        cible,
        minWidth: 1280,
        minHeight: 1280,
        quality: 72,
        autoCorrectionAngle: true,
        keepExif: false,
        format: CompressFormat.jpeg,
      );
      if (resultat != null) return XFile(resultat.path);
    } catch (e) {
      if (kDebugMode) debugPrint('Optimisation photo impossible : $e');
    }
    return source;
  }
}
