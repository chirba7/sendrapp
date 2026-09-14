import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:walletium/controller/deposit_controller.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/services/offline_signalement_service.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/labels/text_labels_widget.dart';
import 'package:walletium/widgets/others/back_button_widget.dart';

class DepositScreen extends StatefulWidget {
  DepositScreen({Key? key}) : super(key: key);

  @override
  _DepositScreenState createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _controller = Get.put(DepositController());
  final _offline = OfflineSignalementService.instance;

  // Une photo par angle. `null` = emplacement encore vide.
  final Map<String, File?> _photos = {
    for (final position in anglesSignalement.keys) position: null,
  };

  Position? locationData;
  String locality = '';
  String subLocality = '';
  double? latitude;
  double? longitude;

  bool _isLoading = false;

  int get _nbPhotos => _photos.values.where((f) => f != null).length;

  // Sur Android, le système peut tuer l'app pendant que l'appareil photo est
  // ouvert (mémoire basse, fréquent à partir de la 3e photo) : l'app
  // « redémarre » et perd le formulaire. Les chemins des photos déjà prises
  // et l'angle en cours de capture sont donc gardés dans les préférences,
  // puis restaurés ici, avec la photo « perdue » récupérée par image_picker.
  static const _clePhotosBrouillon = 'signalement_brouillon_photos';
  static const _cleCaptureEnCours = 'signalement_capture_en_cours';

  @override
  void initState() {
    super.initState();
    _restaurerBrouillon();
  }

  Future<void> _restaurerBrouillon() async {
    final prefs = await SharedPreferences.getInstance();
    final restaurees = <String, File>{};

    try {
      final brut = prefs.getString(_clePhotosBrouillon);
      if (brut != null) {
        (jsonDecode(brut) as Map<String, dynamic>).forEach((position, chemin) {
          final fichier = File(chemin.toString());
          if (_photos.containsKey(position) && fichier.existsSync()) {
            restaurees[position] = fichier;
          }
        });
      }

      final enCours = prefs.getString(_cleCaptureEnCours);
      if (Platform.isAndroid && enCours != null && _photos.containsKey(enCours)) {
        final perdue = await ImagePicker().retrieveLostData();
        if (!perdue.isEmpty && perdue.file != null) {
          restaurees[enCours] = File(perdue.file!.path);
        }
      }
    } catch (e) {
      print('Restauration du brouillon impossible: $e');
    }

    await prefs.remove(_cleCaptureEnCours);
    if (restaurees.isEmpty || !mounted) return;

    setState(() => _photos.addAll(restaurees));
    await _sauverBrouillon();
    _message('Photos du signalement en cours restaurées.');
  }

  Future<void> _sauverBrouillon() async {
    final prefs = await SharedPreferences.getInstance();
    final chemins = {
      for (final e in _photos.entries)
        if (e.value != null) e.key: e.value!.path,
    };
    if (chemins.isEmpty) {
      await prefs.remove(_clePhotosBrouillon);
    } else {
      await prefs.setString(_clePhotosBrouillon, jsonEncode(chemins));
    }
  }

  Future<void> getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      locationData = null;
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        locationData = null;
        return;
      }
    }

    Position currentPosition = await Geolocator.getCurrentPosition();
    latitude = currentPosition.latitude;
    longitude = currentPosition.longitude;
    locationData = currentPosition;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        currentPosition.latitude,
        currentPosition.longitude,
      );
      if (placemarks.isNotEmpty) {
        locality = placemarks.first.locality ?? '';
        subLocality = placemarks.first.subLocality ?? '';
        if (subLocality.isNotEmpty) {
          locality = subLocality;
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _capturer(String position) async {
    final picker = ImagePicker();

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Photo — ${anglesSignalement[position]}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomColor.primaryColor,
                foregroundColor: CustomColor.whiteColor,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 10),
                  Text('Appareil photo'),
                ],
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: CustomColor.whiteColor,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.photo_library),
                  SizedBox(width: 10),
                  Text('Galerie'),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cleCaptureEnCours, position);

    // 1600px suffit (le backend redimensionne à 1600px de toute façon) et
    // garde les 5 photos en base64 sous le post_max_size (8 Mo) du serveur :
    // au-delà, PHP vide la requête et le signalement est refusé.
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    await prefs.remove(_cleCaptureEnCours);
    if (pickedFile == null || !mounted) return;

    setState(() {
      _photos[position] = File(pickedFile.path);
    });
    await _sauverBrouillon();
  }

  void _retirer(String position) {
    setState(() {
      _photos[position] = null;
    });
    _sauverBrouillon();
  }

  Future<void> _soumettre() async {
    if (!_controller.formKey.currentState!.validate()) return;

    if (_nbPhotos == 0) {
      _message('Ajoutez au moins une photo du véhicule.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        _message('Session expirée, veuillez vous reconnecter.');
        return;
      }

      // Encode les photos remplies, dans l'ordre des angles.
      final photos = <PhotoSignalement>[];
      for (final entry in _photos.entries) {
        final fichier = entry.value;
        if (fichier == null) continue;
        final bytes = await fichier.readAsBytes();
        photos.add(PhotoSignalement(
          position: entry.key,
          imageBase64: base64.encode(bytes),
        ));
      }

      await getLocation();

      // uuid stable : sert de clé de déduplication si l'envoi est rejoué
      // (hors ligne puis synchro, ou réseau instable).
      final signalement = PendingSignalement(
        uuid: _offline.nouvelUuid(),
        titre: _controller.titreController.text,
        commune: locality,
        latitude: latitude,
        longitude: longitude,
        createdAt: DateTime.now().toIso8601String(),
        photos: photos,
      );

      final resultat = await _offline.estEnLigne()
          ? await _offline.envoyer(signalement, token)
          : ResultatEnvoi.aReessayer();

      switch (resultat.statut) {
        case StatutEnvoi.envoye:
          _message('Votre signalement a été pris en compte !');
          break;
        case StatutEnvoi.rejete:
          // Refus du serveur (validation) : ce n'est pas un problème de
          // réseau, un renvoi automatique échouerait pareil. On laisse le
          // formulaire rempli pour que l'utilisateur corrige.
          _message('Signalement refusé : ${resultat.message}');
          return;
        case StatutEnvoi.aReessayer:
          // Hors ligne, timeout ou erreur serveur : on stocke localement, la
          // synchro automatique s'en chargera au retour de la connexion.
          await _offline.enfiler(signalement);
          _message(
            'Envoi impossible pour le moment : signalement enregistré. Il '
            'sera envoyé automatiquement dès que possible.',
          );
          break;
      }

      _reinitialiser();
      Get.toNamed(Routes.bottomNavigationScreen);
    } catch (e) {
      print('Erreur lors du signalement: $e');
      _message('Une erreur s\'est produite : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _reinitialiser() {
    _controller.titreController.text = '';
    for (final position in _photos.keys.toList()) {
      _photos[position] = null;
    }
    _sauverBrouillon();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Strings.signalement,
          style: TextStyle(color: CustomColor.whiteColor),
        ),
        leading: const BackButtonWidget(
          backButtonImage: Strings.backButtonWhite,
        ),
        backgroundColor: CustomColor.primaryColor,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
        children: [
          addVerticalSpace(20.h),
          _champTitre(),
          addVerticalSpace(20.h),
          TextLabelsWidget(
            textLabels: 'Photos du véhicule ($_nbPhotos/5)',
            textColor: CustomColor.textColor,
          ),
          addVerticalSpace(6.h),
          Text(
            'Prenez le véhicule sous plusieurs angles (au moins une photo).',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          addVerticalSpace(12.h),
          _grillePhotos(),
          addVerticalSpace(24.h),
          _boutonSignaler(),
          addVerticalSpace(20.h),
        ],
      ),
    );
  }

  Widget _champTitre() {
    return Form(
      key: _controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextLabelsWidget(
            textLabels: Strings.titre,
            textColor: CustomColor.textColor,
          ),
          addVerticalSpace(6.h),
          TextFormField(
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            cursorColor: Colors.black,
            controller: _controller.titreController,
            decoration: InputDecoration(
              hintText: 'Que voulez-vous signaler ?',
              hintStyle: const TextStyle(color: CustomColor.gray),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.black),
                borderRadius: BorderRadius.circular(10.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.black),
                borderRadius: BorderRadius.circular(10.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.black),
                borderRadius: BorderRadius.circular(10.0),
              ),
              filled: true,
              fillColor: CustomColor.whiteColor,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez saisir un titre.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _grillePhotos() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: anglesSignalement.entries
          .map((entry) => _tuilePhoto(entry.key, entry.value))
          .toList(),
    );
  }

  Widget _tuilePhoto(String position, String libelle) {
    final fichier = _photos[position];
    final rempli = fichier != null;

    return GestureDetector(
      onTap: () => _capturer(position),
      child: Container(
        decoration: BoxDecoration(
          color: CustomColor.whiteColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: rempli ? CustomColor.primaryColor : Colors.grey.shade400,
            width: rempli ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (rempli)
              // Vignette décodée en petit : 5 photos en pleine résolution
              // en mémoire suffisaient à faire tuer l'app par Android.
              Image.file(fichier, fit: BoxFit.cover, cacheWidth: 400)
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: Colors.grey.shade500, size: 28),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      libelle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
            // Bandeau du libellé sur les tuiles remplies.
            if (rempli)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.55),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  child: Text(
                    libelle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            if (rempli)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _retirer(position),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _boutonSignaler() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _soumettre,
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomColor.primaryColor,
        foregroundColor: CustomColor.whiteColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        elevation: 3,
        padding: const EdgeInsets.symmetric(vertical: 14.0),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 24.0,
              height: 24.0,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.send, size: 22.0, color: Colors.white),
                SizedBox(width: 10.0),
                Text(
                  Strings.signaler,
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
    );
  }
}
