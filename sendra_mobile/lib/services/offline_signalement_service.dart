import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:walletium/utils/strings.dart';

/// Les cinq angles de prise de vue d'un signalement, dans l'ordre d'affichage.
/// La clé est la valeur envoyée au backend (`car_photos.position`) ; la valeur
/// est le libellé montré à l'utilisateur.
const Map<String, String> anglesSignalement = {
  'vue_ensemble': "Vue d'ensemble",
  'devant': 'Devant',
  'derriere': 'Derrière',
  'cote_gauche': 'Côté gauche',
  'cote_droit': 'Côté droit',
};

/// Une photo d'un signalement, associée à son angle.
class PhotoSignalement {
  final String position;
  final String imageBase64;

  PhotoSignalement({required this.position, required this.imageBase64});

  Map<String, dynamic> toJson() => {'position': position, 'image': imageBase64};

  factory PhotoSignalement.fromJson(Map<String, dynamic> json) =>
      PhotoSignalement(
        position: json['position'] as String,
        imageBase64: json['image'] as String,
      );
}

enum StatutEnvoi { envoye, rejete, aReessayer }

/// Issue d'un envoi au backend. `message` n'est renseigné que pour un rejet.
class ResultatEnvoi {
  final StatutEnvoi statut;
  final String? message;

  const ResultatEnvoi._(this.statut, [this.message]);

  factory ResultatEnvoi.envoye() => const ResultatEnvoi._(StatutEnvoi.envoye);
  factory ResultatEnvoi.rejete(String message) =>
      ResultatEnvoi._(StatutEnvoi.rejete, message);
  // `message` sert au diagnostic (code HTTP ou erreur réseau) : il permet de
  // distinguer un vrai hors-ligne d'un échec serveur (413, 5xx, TLS...).
  factory ResultatEnvoi.aReessayer([String? message]) =>
      ResultatEnvoi._(StatutEnvoi.aReessayer, message);
}

/// Un signalement complet, tel que stocké localement en attendant l'envoi.
class PendingSignalement {
  final String uuid;
  final String titre;
  final String commune;
  final double? latitude;
  final double? longitude;
  final List<PhotoSignalement> photos;
  final String createdAt;

  PendingSignalement({
    required this.uuid,
    required this.titre,
    required this.commune,
    required this.latitude,
    required this.longitude,
    required this.photos,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'titre': titre,
        'commune': commune,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': createdAt,
        'photos': photos.map((p) => p.toJson()).toList(),
      };

  factory PendingSignalement.fromJson(Map<String, dynamic> json) =>
      PendingSignalement(
        uuid: json['uuid'] as String,
        titre: json['titre'] as String? ?? '',
        commune: json['commune'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        createdAt: json['createdAt'] as String? ?? '',
        photos: (json['photos'] as List<dynamic>? ?? [])
            .map((e) => PhotoSignalement.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// File d'attente locale des signalements + synchronisation automatique.
///
/// Un signalement créé hors ligne (ou dont l'envoi échoue) est écrit sur le
/// disque du téléphone. Dès que la connexion revient, la file est renvoyée au
/// backend. Chaque signalement porte un `uuid` stable : si le réseau coupe en
/// plein envoi et que la synchro réessaie, le backend reconnaît l'uuid et ne
/// crée pas de doublon (voir CarPositionController::store()).
class OfflineSignalementService {
  OfflineSignalementService._();
  static final OfflineSignalementService instance = OfflineSignalementService._();

  static const _uuidGen = Uuid();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _syncing = false;

  String nouvelUuid() => _uuidGen.v4();

  Future<Directory> _dossier() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/pending_signalements');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Enregistre un signalement en attente d'envoi.
  Future<void> enfiler(PendingSignalement signalement) async {
    final dir = await _dossier();
    final fichier = File('${dir.path}/${signalement.uuid}.json');
    await fichier.writeAsString(jsonEncode(signalement.toJson()));
  }

  /// Liste les signalements encore en attente, du plus ancien au plus récent.
  Future<List<PendingSignalement>> enAttente() async {
    final dir = await _dossier();
    final fichiers = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final resultats = <PendingSignalement>[];
    for (final fichier in fichiers) {
      try {
        final contenu = await fichier.readAsString();
        resultats.add(
          PendingSignalement.fromJson(
            jsonDecode(contenu) as Map<String, dynamic>,
          ),
        );
      } catch (_) {
        // Fichier corrompu : on le retire pour ne pas bloquer la file.
        await fichier.delete();
      }
    }
    return resultats;
  }

  Future<int> nombreEnAttente() async => (await enAttente()).length;

  Future<void> _supprimer(String uuid) async {
    final dir = await _dossier();
    final fichier = File('${dir.path}/$uuid.json');
    if (await fichier.exists()) {
      await fichier.delete();
    }
  }

  Future<bool> estEnLigne() async {
    final etats = await Connectivity().checkConnectivity();
    return etats.any((e) => e != ConnectivityResult.none);
  }

  /// Envoie un signalement au backend.
  ///
  /// Distingue trois issues : accepté, rejeté par le serveur (validation —
  /// un renvoi à l'identique échouerait pareil) et échec à réessayer (réseau,
  /// timeout, jeton expiré, 5xx). Seul ce dernier cas justifie la file
  /// hors ligne : un rejet ne doit jamais s'afficher comme « pas de connexion ».
  Future<ResultatEnvoi> envoyer(PendingSignalement s, String token) async {
    try {
      final reponse = await http
          .post(
            Uri.parse('${Strings.apiURI}faireSignalement'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'titre': s.titre,
              'commune': s.commune,
              'latitude': s.latitude,
              'longitude': s.longitude,
              'uuid': s.uuid,
              'photos': s.photos.map((p) => p.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 60));

      final corps = _decoder(reponse.body);
      final message = corps['message']?.toString() ?? '';

      if (reponse.statusCode == 200) {
        // Succès réel du contrat v1.
        if (message.contains('succès')) {
          return ResultatEnvoi.envoye();
        }
        // 200 mais erreur de validation (failedValidation renvoie 200 avec
        // status_code 422).
        if (corps['status_code'] == 422 || corps['error'] == true) {
          return ResultatEnvoi.rejete(_detailValidation(corps));
        }
        return ResultatEnvoi.aReessayer('Réponse inattendue (HTTP 200)');
      }

      // 422 réel (image invalide) : rejet définitif, inutile de réessayer.
      if (reponse.statusCode == 422) {
        return ResultatEnvoi.rejete(message.isNotEmpty ? message : 'Signalement refusé.');
      }

      // 401/403 (jeton expiré), 413 (payload trop volumineux), 5xx... : on
      // garde pour une tentative ultérieure, en remontant le code pour le
      // diagnostic (une limite serveur ne se résout pas en réessayant).
      return ResultatEnvoi.aReessayer('HTTP ${reponse.statusCode}');
    } catch (e) {
      // Réseau coupé, timeout, erreur TLS : on réessaiera.
      return ResultatEnvoi.aReessayer(e.toString());
    }
  }

  /// Premier message d'erreur de `errorList`, sinon le message générique.
  String _detailValidation(Map<String, dynamic> corps) {
    final erreurs = corps['errorList'];
    if (erreurs is Map && erreurs.isNotEmpty) {
      final premiere = erreurs.values.first;
      if (premiere is List && premiere.isNotEmpty) {
        return premiere.first.toString();
      }
    }
    return corps['message']?.toString() ?? 'Signalement refusé.';
  }

  /// Hors ligne, le géocodage inverse échoue et la commune part vide. Au
  /// moment de la synchro le réseau est revenu : on la calcule à partir des
  /// coordonnées et on met à jour le fichier en attente. En cas d'échec, le
  /// signalement part tel quel (le backend accepte une commune vide).
  Future<PendingSignalement> _completerCommune(PendingSignalement s) async {
    if (s.commune.isNotEmpty || s.latitude == null || s.longitude == null) {
      return s;
    }
    try {
      final lieux = await placemarkFromCoordinates(s.latitude!, s.longitude!)
          .timeout(const Duration(seconds: 10));
      if (lieux.isEmpty) return s;
      final lieu = lieux.first;
      final commune = (lieu.subLocality?.isNotEmpty ?? false)
          ? lieu.subLocality!
          : (lieu.locality ?? '');
      if (commune.isEmpty) return s;

      final complete = PendingSignalement(
        uuid: s.uuid,
        titre: s.titre,
        commune: commune,
        latitude: s.latitude,
        longitude: s.longitude,
        photos: s.photos,
        createdAt: s.createdAt,
      );
      await enfiler(complete);
      return complete;
    } catch (_) {
      return s;
    }
  }

  /// Les versions précédentes refusaient côté serveur tout signalement créé
  /// hors ligne (commune vide) et le mettaient de côté en `.rejete`. Le
  /// backend l'accepte désormais : on les remet une fois dans la file pour
  /// qu'ils partent à la prochaine synchro.
  Future<void> _reintegrerRejetesUneFois() async {
    const cle = 'signalements_rejetes_reintegres_v1';
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(cle) == true) return;

      final dir = await _dossier();
      final rejetes = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.rejete'));
      for (final fichier in rejetes) {
        await fichier.rename(
          fichier.path.replaceFirst(RegExp(r'\.rejete$'), '.json'),
        );
      }
      await prefs.setBool(cle, true);
    } catch (_) {
      // Sans effet bloquant : la synchro normale continue.
    }
  }

  /// Écarte un signalement rejeté par le serveur sans le détruire : renommé
  /// en `.rejete`, il sort de la file (plus de boucle de renvoi) mais reste
  /// sur le téléphone pour diagnostic.
  Future<void> _mettreDeCote(String uuid) async {
    final dir = await _dossier();
    final fichier = File('${dir.path}/$uuid.json');
    if (await fichier.exists()) {
      await fichier.rename('${dir.path}/$uuid.rejete');
    }
  }

  Map<String, dynamic> _decoder(String corps) {
    try {
      final decode = jsonDecode(corps);
      return decode is Map<String, dynamic> ? decode : {};
    } catch (_) {
      return {};
    }
  }

  /// Renvoie toute la file. Sans effet s'il n'y a rien à envoyer, pas de
  /// jeton, ou pas de connexion.
  Future<void> synchroniser() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final file = await enAttente();
      if (file.isEmpty) return;

      if (!await estEnLigne()) return;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) return;

      for (final stocke in file) {
        final signalement = await _completerCommune(stocke);
        final resultat = await envoyer(signalement, token);
        if (resultat.statut == StatutEnvoi.envoye) {
          await _supprimer(signalement.uuid);
        } else if (resultat.statut == StatutEnvoi.rejete) {
          await _mettreDeCote(signalement.uuid);
        } else {
          // Un échec « à réessayer » (réseau/serveur) : inutile d'insister
          // sur les suivants maintenant, on relancera au prochain signal.
          break;
        }
      }
    } finally {
      _syncing = false;
    }
  }

  /// À appeler une fois au démarrage de l'app : tente une synchro immédiate
  /// puis en relance une à chaque retour de connexion.
  void demarrerSynchroAuto() {
    _reintegrerRejetesUneFois().whenComplete(synchroniser);
    _subscription ??= Connectivity().onConnectivityChanged.listen((etats) {
      final enLigne = etats.any((e) => e != ConnectivityResult.none);
      if (enLigne) {
        synchroniser();
      }
    });
  }

  void arreter() {
    _subscription?.cancel();
    _subscription = null;
  }
}
