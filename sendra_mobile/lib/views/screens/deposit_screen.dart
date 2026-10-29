import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/services/offline_signalement_service.dart';
import 'package:walletium/utils/app_prefs.dart';
import 'package:walletium/utils/sendra_theme.dart';
import 'package:walletium/utils/signaler_flow.dart';

/// Formulaire de signalement, ouvert juste après la photo.
///
/// Le bouton « Signaler » ouvre directement l'appareil photo ; ici on choisit
/// le type de véhicule (trois bulles qui remplacent l'ancien titre libre),
/// on ajoute éventuellement une description, puis on valide.
class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

/// Les trois types proposés : valeur envoyée au backend, libellé, icône.
const _typesVehicule = <(String, String, IconData)>[
  ('Voiture', 'Voiture', Icons.directions_car_filled_rounded),
  ('Moto', 'Moto', Icons.two_wheeler_rounded),
  ('Camion', 'Camion', Icons.local_shipping_rounded),
];

/// Angles supplémentaires (facultatifs), réservés aux agents : le backend
/// n'accepte qu'une photo pour un citoyen.
const _anglesSupplementaires = [
  'devant',
  'derriere',
  'cote_gauche',
  'cote_droit'
];

class _DepositScreenState extends State<DepositScreen> {
  final _offline = OfflineSignalementService.instance;
  final _description = TextEditingController();
  late final bool _isStaff = AppPrefs.isStaff;

  File? _photo;
  final Map<String, File> _angles = {};
  String? _type;
  bool _envoi = false;
  bool _typeManquant = false;

  // Position cherchée dès l'ouverture, pour ne pas attendre le GPS au moment
  // de valider.
  Future<void>? _localisation;
  double? _latitude;
  double? _longitude;
  String _commune = '';
  String _adresse = '';

  @override
  void initState() {
    super.initState();
    final argument = Get.arguments;
    if (argument is File) {
      _photo = argument;
    } else {
      // Ouvert sans photo (ancien lien) : on lance l'appareil photo.
      WidgetsBinding.instance.addPostFrameCallback((_) => _reprendre());
    }
    _localisation = _localiser();
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _localiser() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 20));
      _latitude = position.latitude;
      _longitude = position.longitude;
      try {
        final lieux = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (lieux.isNotEmpty) {
          final lieu = lieux.first;
          final sousLocalite = lieu.subLocality ?? '';
          _commune = AppPrefs.isStaff && sousLocalite.isNotEmpty
              ? sousLocalite
              : (lieu.locality ?? lieu.subAdministrativeArea ?? '');
          _adresse = [lieu.street, sousLocalite, lieu.locality]
              .where((p) => p != null && p.trim().isNotEmpty)
              .map((p) => p!.trim())
              .toSet()
              .join(', ');
        }
      } catch (_) {
        // Hors ligne : la commune sera complétée à la synchronisation.
      }
    } catch (_) {
      // Position indisponible : dernier recours, la dernière connue.
      final derniere = await Geolocator.getLastKnownPosition();
      _latitude ??= derniere?.latitude;
      _longitude ??= derniere?.longitude;
    }
    if (mounted) setState(() {});
  }

  Future<void> _reprendre() async {
    final prise = await SignalerFlow.prendrePhoto();
    if (prise == null) {
      if (_photo == null && mounted) Get.back();
      return;
    }
    final photo = await SignalerFlow.optimiser(File(prise.path));
    if (mounted) setState(() => _photo = photo);
  }

  Future<void> _ajouterAngle(String angle) async {
    final prise = await SignalerFlow.prendrePhoto();
    if (prise == null) return;
    final photo = await SignalerFlow.optimiser(File(prise.path));
    if (mounted) setState(() => _angles[angle] = photo);
  }

  Future<void> _valider() async {
    if (_type == null) {
      setState(() => _typeManquant = true);
      _message('Choisissez le type de véhicule.');
      return;
    }
    if (_photo == null) {
      _message('Prenez une photo du véhicule.');
      return;
    }
    setState(() => _envoi = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        _message('Session expirée, veuillez vous reconnecter.');
        return;
      }

      await _localisation?.timeout(const Duration(seconds: 25),
          onTimeout: () {});
      if (_latitude == null || _longitude == null) {
        _message(
            'Position introuvable : activez la localisation puis réessayez.');
        return;
      }

      final photos = <PhotoSignalement>[
        PhotoSignalement(
          position: 'vue_ensemble',
          imageBase64: base64Encode(await _photo!.readAsBytes()),
        ),
        if (_isStaff)
          for (final e in _angles.entries)
            PhotoSignalement(
              position: e.key,
              imageBase64: base64Encode(await e.value.readAsBytes()),
            ),
      ];

      final signalement = PendingSignalement(
        uuid: _offline.nouvelUuid(),
        titre: _type!,
        vehicleKind: _type!,
        description: _description.text.trim(),
        commune: _commune,
        adressePrecise: _adresse,
        latitude: _latitude,
        longitude: _longitude,
        createdAt: DateTime.now().toIso8601String(),
        photos: photos,
      );

      final resultat = await _offline.estEnLigne()
          ? await _offline.envoyer(signalement, token)
          : ResultatEnvoi.aReessayer();

      String message;
      switch (resultat.statut) {
        case StatutEnvoi.envoye:
          message = 'Votre signalement a été pris en compte. Merci !';
          break;
        case StatutEnvoi.rejete:
          _message('Signalement refusé : ${resultat.message}');
          return;
        case StatutEnvoi.aReessayer:
          await _offline.enfiler(signalement);
          message = 'Pas de connexion : signalement enregistré, il sera '
              'envoyé automatiquement dès que possible.';
          break;
      }

      // Retour à l'accueil en vidant la pile : le bouton retour du téléphone
      // ne ramène plus sur ce formulaire déjà envoyé.
      Get.offAllNamed(Routes.bottomNavigationScreen);
      Get.rawSnackbar(
        message: message,
        backgroundColor: SendraTheme.forest,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      _message('Une erreur s’est produite : $e');
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  void _message(String texte) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texte),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_envoi,
      child: Scaffold(
        backgroundColor: SendraTheme.surface,
        appBar: AppBar(title: const Text('Nouveau signalement')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _apercuPhoto(),
            const SizedBox(height: 22),
            _titreSection('Type de véhicule', obligatoire: true),
            const SizedBox(height: 12),
            _bullesType(),
            if (_typeManquant && _type == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Choisissez un type pour continuer.',
                    style: TextStyle(color: SendraTheme.statusSignale)),
              ),
            const SizedBox(height: 22),
            _titreSection('Description'),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              maxLines: 3,
              minLines: 2,
              maxLength: 254,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Facultatif : un repère, la situation…',
              ),
            ),
            if (_isStaff) ...[
              const SizedBox(height: 10),
              _titreSection('Autres angles'),
              const SizedBox(height: 10),
              _anglesAgent(),
            ],
            const SizedBox(height: 14),
            _lignePosition(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _envoi ? null : _valider,
                icon: _envoi
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_envoi ? 'Envoi…' : 'Valider le signalement',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _titreSection(String texte, {bool obligatoire = false}) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 6,
      children: [
        Text(texte,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: SendraTheme.ink)),
        if (!obligatoire)
          const Text('(facultatif)',
              style: TextStyle(color: SendraTheme.muted, fontSize: 13)),
      ],
    );
  }

  Widget _apercuPhoto() {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_photo != null)
              Image.file(_photo!, fit: BoxFit.cover, cacheWidth: 1000)
            else
              const ColoredBox(
                color: Color(0xFFEAF1ED),
                child: Center(child: CircularProgressIndicator()),
              ),
            Positioned(
              right: 10,
              bottom: 10,
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: .55),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 40),
                ),
                onPressed: _envoi ? null : _reprendre,
                icon: const Icon(Icons.cameraswitch_rounded, size: 18),
                label: const Text('Reprendre'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullesType() {
    return Row(
      children: [
        for (final t in _typesVehicule)
          Expanded(
            child: _Bulle(
              libelle: t.$2,
              icone: t.$3,
              choisie: _type == t.$1,
              onTap: () => setState(() => _type = t.$1),
            ),
          ),
      ],
    );
  }

  Widget _anglesAgent() {
    const libelles = {
      'devant': 'Devant',
      'derriere': 'Derrière',
      'cote_gauche': 'Gauche',
      'cote_droit': 'Droite',
    };
    return LayoutBuilder(builder: (context, c) {
      final colonnes = c.maxWidth < 330 ? 2 : 4;
      return GridView.count(
        crossAxisCount: colonnes,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: [
          for (final angle in _anglesSupplementaires)
            _TuileAngle(
              libelle: libelles[angle]!,
              photo: _angles[angle],
              onTap: () => _ajouterAngle(angle),
              onRetirer: () => setState(() => _angles.remove(angle)),
            ),
        ],
      );
    });
  }

  Widget _lignePosition() {
    final ok = _latitude != null;
    return Row(
      children: [
        Icon(ok ? Icons.place_rounded : Icons.location_searching_rounded,
            size: 18, color: ok ? SendraTheme.green : SendraTheme.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            ok
                ? (_adresse.isNotEmpty ? _adresse : 'Position enregistrée')
                : 'Recherche de la position…',
            style: const TextStyle(color: SendraTheme.muted, fontSize: 13.5),
          ),
        ),
      ],
    );
  }
}

/// Bulle ronde d'un type de véhicule.
class _Bulle extends StatelessWidget {
  const _Bulle({
    required this.libelle,
    required this.icone,
    required this.choisie,
    required this.onTap,
  });

  final String libelle;
  final IconData icone;
  final bool choisie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: choisie,
      label: libelle,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: LayoutBuilder(builder: (context, c) {
          // Bulle proportionnelle à la place disponible (jamais plus large
          // que sa colonne, même sur un Fold fermé).
          final taille = (c.maxWidth - 12).clamp(40.0, 92.0).toDouble();
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: taille,
                height: taille,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: choisie ? SendraTheme.green : Colors.white,
                  border: Border.all(
                    color: choisie ? SendraTheme.green : SendraTheme.border,
                    width: choisie ? 3 : 1.4,
                  ),
                  boxShadow: choisie
                      ? [
                          BoxShadow(
                            color: SendraTheme.green.withValues(alpha: .3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Icon(icone,
                    size: taille * .46,
                    color: choisie ? Colors.white : SendraTheme.forest),
              ),
              const SizedBox(height: 8),
              Text(
                libelle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: choisie ? FontWeight.w800 : FontWeight.w600,
                  color: choisie ? SendraTheme.forest : SendraTheme.ink,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _TuileAngle extends StatelessWidget {
  const _TuileAngle({
    required this.libelle,
    required this.photo,
    required this.onTap,
    required this.onRetirer,
  });

  final String libelle;
  final File? photo;
  final VoidCallback onTap;
  final VoidCallback onRetirer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: photo != null ? SendraTheme.green : SendraTheme.border,
            width: photo != null ? 2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo != null)
              Image.file(photo!, fit: BoxFit.cover, cacheWidth: 300)
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined,
                      color: SendraTheme.green, size: 22),
                  const SizedBox(height: 4),
                  Text(libelle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            if (photo != null)
              Positioned(
                top: 2,
                right: 2,
                child: IconButton.filled(
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white),
                  onPressed: onRetirer,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
