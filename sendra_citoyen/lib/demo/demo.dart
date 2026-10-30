// Mode démo (compilé seulement avec --dart-define=DEMO=true).
//
// L'application est identique à celle du Play Store, mais :
//  - tous les appels à l'API sont servis par un faux serveur en mémoire
//    (même JSON que le backend Laravel, données fictives) ;
//  - l'appareil photo propose des photos d'exemple ;
//  - la position est fixée à Dakar (Médina) et le géocodage est simulé.
// Rien ne sort du navigateur : chaque visiteur a sa propre copie des données.
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import '../utils/app_brand.dart';
import '../utils/strings.dart';

const bool kDemo = bool.fromEnvironment('DEMO');
// Environnement de démonstration partagé : la même API Laravel sert PUBLIC,
// PRO et WEB. L'adresse est injectée à la compilation, jamais choisie par le
// visiteur. Sans cette valeur, la démo autonome conserve son faux serveur.
const String kDemoApiHost = String.fromEnvironment('DEMO_API_HOST');

class Demo {
  Demo._();

  /// Adresse d'une ressource publiée avec l'application web (dossier web/demo).
  static String fichier(String nom) => Uri.base.resolve('demo/$nom').toString();
  static String photo(String nom) => fichier('photos/$nom');

  static void installer() {
    Strings.apiHost = kDemoApiHost.isEmpty ? 'https://api.demo-epavie.sn' : kDemoApiHost;
    GeolocatorPlatform.instance = _DemoGeolocator();
    GeocodingPlatform.instance = _DemoGeocoding();
    _pickerReel = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = _DemoPicker();
  }

  static ImagePickerPlatform? _pickerReel;

  static http.Client client(http.Client reel) =>
      kDemoApiHost.isEmpty ? _DemoClient(reel) : reel;
}

// ───────────────────────── Position et géocodage ─────────────────────────

const _lat = 14.68370, _lng = -17.44830;

class _DemoGeolocator extends GeolocatorPlatform {
  Position get _position => Position(
        latitude: _lat,
        longitude: _lng,
        timestamp: DateTime.now(),
        accuracy: 6,
        altitude: 12,
        altitudeAccuracy: 3,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.whileInUse;
  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.whileInUse;
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<Position?> getLastKnownPosition({bool forceLocationManager = false}) async => _position;
  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return _position;
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) => Stream.value(_position);
  @override
  Future<bool> openAppSettings() async => true;
  @override
  Future<bool> openLocationSettings() async => true;
}

class _DemoGeocoding extends GeocodingPlatform {
  @override
  Future<List<Placemark>> placemarkFromCoordinates(double latitude, double longitude) async => [
        const Placemark(
          street: 'Rue 11 × Avenue Blaise Diagne',
          subLocality: 'Médina',
          locality: 'Dakar',
          subAdministrativeArea: 'Dakar',
          administrativeArea: 'Dakar',
          country: 'Sénégal',
          isoCountryCode: 'SN',
        ),
      ];
}

// ───────────────────────── Appareil photo de démonstration ─────────────────────────

const _photosExemple = [
  'exemple_1.jpg', 'exemple_2.jpg', 'exemple_3.jpg', 'exemple_4.jpg',
  'exemple_5.jpg', 'exemple_6.jpg', 'exemple_7.jpg', 'exemple_8.jpg',
];
const _fichesExemple = ['fiche_1.jpg', 'fiche_2.jpg', 'fiche_3.jpg', 'fiche_4.jpg'];

class _DemoPicker extends ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    final choix = await Get.bottomSheet<String>(
      const _FeuillePhotos(),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    );
    if (choix == null) return null;
    if (choix == '__import__') {
      return Demo._pickerReel?.getImageFromSource(source: ImageSource.gallery, options: options);
    }
    return XFile(Demo.photo(choix), name: choix, mimeType: 'image/jpeg');
  }

  @override
  Future<LostDataResponse> getLostData() async => LostDataResponse.empty();
}

class _FeuillePhotos extends StatelessWidget {
  const _FeuillePhotos();

  @override
  Widget build(BuildContext context) {
    Widget grille(List<String> noms) => GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (final n in noms)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Get.back(result: n),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(Demo.photo(n), fit: BoxFit.cover),
                ),
              ),
          ],
        );
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .8),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                      color: const Color(0xFFCFD6D2), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text('Appareil photo (démo)',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Choisissez une photo d’exemple, comme si vous la preniez sur place.',
                  style: TextStyle(color: Color(0xFF5F6B65))),
              const SizedBox(height: 14),
              grille(_photosExemple),
              const SizedBox(height: 16),
              const Text('Fiches papier', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              grille(_fichesExemple),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => Get.back(result: '__import__'),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Importer une photo depuis cet appareil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Client HTTP intercepté ─────────────────────────

class _DemoClient extends http.BaseClient {
  _DemoClient(this._reel);
  final http.Client _reel;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest req) async {
    final url = req.url.toString();
    if (!url.startsWith(Strings.apiURI)) return _reel.send(req);
    final chemin = url.substring(Strings.apiURI.length).split('?').first;
    final donnees = <String, dynamic>{};
    final fichiers = <String, Uint8List>{};
    if (req is http.Request) {
      final type = req.headers['content-type'] ?? req.headers['Content-Type'] ?? '';
      if (req.body.isNotEmpty) {
        if (type.contains('x-www-form-urlencoded')) {
          donnees.addAll(req.bodyFields);
        } else {
          try {
            final d = jsonDecode(req.body);
            if (d is Map) donnees.addAll(Map<String, dynamic>.from(d));
          } catch (_) {}
        }
      }
    } else if (req is http.MultipartRequest) {
      donnees.addAll(req.fields);
      for (final f in req.files) {
        fichiers[f.field] = await f.finalize().toBytes();
      }
    }
    final r = _Serveur.instance.traiter(req.method, chemin, donnees, fichiers);
    await Future<void>.delayed(Duration(milliseconds: 220 + Random().nextInt(260)));
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(r.corps))),
      r.statut,
      headers: {'content-type': 'application/json; charset=utf-8'},
      request: req,
    );
  }
}

class _Reponse {
  const _Reponse(this.corps, [this.statut = 200]);
  final Object? corps;
  final int statut;
}

// ───────────────────────── Faux serveur ─────────────────────────

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} à ${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
String _dataUri(Uint8List octets, [String type = 'image/jpeg']) => 'data:$type;base64,${base64Encode(octets)}';

class _Serveur {
  _Serveur._() {
    _graines();
  }
  static final instance = _Serveur._();

  // Comptes : l'utilisateur connecté selon l'application.
  static const _agentMoi = 2, _agentAutre = 3, _agentReception = 4, _agentQuatre = 5, _citoyenMoi = 10, _citoyenAutre = 11;
  final _noms = <int, String>{
    _agentMoi: 'Cheikh Ndiaye', _agentAutre: 'Aminata Sow', _agentReception: 'Ibrahima Sarr', _agentQuatre: 'Moussa Diallo',
    _citoyenMoi: 'Awa Diop', _citoyenAutre: 'Fatou Ba',
  };
  int get _moi => AppBrand.isPro ? _agentMoi : _citoyenMoi;
  String _prenom = AppBrand.isPro ? 'Cheikh' : 'Awa', _nom = AppBrand.isPro ? 'Ndiaye' : 'Diop', _tel = '771234567';
  String? _photoProfil;

  final List<Map<String, dynamic>> _sigs = [];
  final List<Map<String, dynamic>> _missions = [];
  int _idSig = 1089, _idPhoto = 5000, _idRemoval = 700, _numPv = 191;

  // ───────── Données de départ ─────────
  Map<String, dynamic> _sig(int id, String kind, String marque, String modele, String plaque, String commune, String adresse,
      String etat, DateTime date,
      {int user = _citoyenAutre, int? agent, bool soumis = false, bool approuve = false, String? motifRejet, String? motifNon,
      String desc = '', double dLat = 0, double dLng = 0, bool pv = false, int photosAgent = 0}) {
    final moto = kind == 'Moto';
    return {
      'id': id, 'user_id': user, 'title': kind, 'vehicle_kind': kind, 'description': desc, 'commune': commune,
      'adresse_precise': adresse, 'latitude': (_lat + dLat).toStringAsFixed(6), 'longitude': (_lng + dLng).toStringAsFixed(6),
      'etat': etat, 'is_approve': approuve, 'soumis': soumis, 'dommage_image': soumis ? Demo.photo('s${id}_detail.jpg') : null,
      'created': _date(date), 'agent_id': agent, 'pris_at': agent != null ? date.add(const Duration(hours: 20)).toIso8601String() : null,
      'photos': [
        {'url': Demo.photo('s${id}_left.jpg'), 'position': 'vue_ensemble', 'source': 'citoyen'}
      ],
      'photos_agent': [
        for (var i = 0; i < photosAgent; i++)
          {'id': _idPhoto++, 'url': Demo.photo('s${id}_${moto ? (i == 0 ? 'detail' : 'right') : (i == 0 ? 'detail' : 'front')}.jpg'), 'position': 'agent_constat'}
      ],
      'pv_numero': soumis ? 'PV-2026-0${150 + id % 40}' : null,
      'pv_signe_at': pv ? _date(date.add(const Duration(days: 1))) : null,
      'pv_signature': null,
      'pieces_manquantes': soumis ? (id.isOdd ? 'Roue avant gauche, rétroviseurs' : '') : null,
      'motif_approbation': motifRejet,
      'non_removal_reason': motifNon,
      'numero_vehicule': soumis ? plaque : null, 'marque': soumis ? marque : null, 'model': soumis ? modele : null,
      'type_car': soumis ? (moto ? 'CYCL — deux-roues' : kind == 'Camion' ? 'VTM — transport de marchandises' : 'VPP — voiture particulière') : null,
      'categorie': soumis ? (moto ? 'CYCL' : kind == 'Camion' ? 'Camion' : 'Berline') : null,
      'couleur': soumis ? 'Gris' : null, 'entretien': soumis ? 'DEGRADE' : null, 'pays_etranger': soumis ? 'NON' : null,
      'autre_situation': '', 'defaut_controle_technique': 0, 'pneumatiques_manquantes': soumis && id.isOdd ? 1 : 0,
      'vehicule_immerge': 0, 'defauts_techniques_irreversibles': soumis ? 1 : 0, 'vehicule_non_identifiable': 0, 'vehicule_brule': 0,
      'chassis_non_reparable': 0,
      'motif_infraction': soumis ? 'Véhicule abandonné sur la voie publique' : null,
      'explication_infraction': soumis ? 'Véhicule immobilisé depuis plusieurs mois, signalé par les riverains.' : null,
      'lieu': soumis ? 'PUBLIC' : null, 'nuit': 0, 'pluie': 0,
      // Réservé à la démo : véhicule déjà enlevé, en attente de réception.
      'cache': false, '_marque': marque, '_modele': modele, '_plaque': plaque,
    };
  }

  void _graines() {
    final j = DateTime(2026, 10, 29, 9, 41);
    DateTime il(int jours, int h, int m) => DateTime(j.year, j.month, j.day - jours, h, m);
    const citoyen = AppBrand.isPro ? _citoyenAutre : _citoyenMoi;
    _sigs.addAll([
      _sig(1088, 'Voiture', 'Hyundai', 'H100', 'DK-5502-AH', 'Ouakam', 'Cité Avion, rue OKM-12', 'SIGNALE', il(0, 7, 48), dLat: .012, dLng: -.03, desc: 'Fourgon abandonné, pneus à plat.'),
      _sig(1087, 'Voiture', 'Mitsubishi', 'L200', 'DK-2658-AH', 'Cambérène', 'Cambérène 2', 'SIGNALE', il(0, 6, 55), dLat: .07, dLng: .02),
      _sig(1086, 'Moto', 'TVS', 'Apache', '', 'Dieuppeul-Derklé', 'Derklé, rue DD-15', 'SIGNALE', il(1, 20, 10), dLat: .03, dLng: .004),
      _sig(1085, 'Voiture', 'Renault', 'Clio', 'DK-3307-AF', 'Mermoz-Sacré-Cœur', 'Rue MZ-74, face pharmacie', 'SIGNALE', il(1, 18, 5), user: citoyen, dLat: .02, dLng: -.02, desc: 'Garée depuis plus de trois mois, pneus à plat.'),
      _sig(1084, 'Camion', 'Isuzu', 'NPR', 'DK-9050-BA', 'Biscuiterie', 'Route de Rufisque', 'SIGNALE', il(1, 9, 44), dLat: .025, dLng: .03),
      _sig(1083, 'Voiture', 'Mercedes-Benz', '190', 'DK-0921-AC', 'Plateau', 'Avenue Pompidou', 'SIGNALE', il(2, 15, 31), agent: _agentAutre, dLat: -.017, dLng: .01),
      _sig(1082, 'Voiture', 'Renault', '19', 'DK-0412-AA', 'Ngor', 'Ngor village, route de la plage', 'EN COURS', il(4, 17, 17), agent: _agentAutre, soumis: true, pv: true, photosAgent: 1, dLat: .065, dLng: -.06),
      _sig(1081, 'Voiture', 'Peugeot', '406', 'DK-4821-BF', 'Médina', 'Rue 11 × Blaise Diagne', 'EN COURS', il(5, 9, 12), user: citoyen, agent: _agentMoi, soumis: true, pv: true, photosAgent: 2),
      _sig(1079, 'Voiture', 'Nissan', 'Sunny', 'DK-6618-AD', 'Yoff', 'Yoff Tonghor, rue YF-33', 'SIGNALE', il(3, 10, 15), agent: _agentMoi, dLat: .06, dLng: .01),
      _sig(1077, 'Voiture', 'Honda', 'Civic', 'DK-3981-AE', 'Hann Bel-Air', 'Zone de Hann, quai de pêche', 'EN COURS', il(15, 13, 40), agent: _agentMoi, soumis: true, approuve: true, pv: true, photosAgent: 1, dLat: .01, dLng: .05),
      _sig(1074, 'Voiture', 'Toyota', 'Corolla', 'DK-1196-AM', 'Sicap-Liberté', 'Liberté 6, près du rond-point', 'ENLEVE', il(17, 17, 40), user: citoyen, agent: _agentAutre, soumis: true, approuve: true, pv: true, dLat: .015, dLng: .002),
      _sig(1072, 'Voiture', 'Peugeot', '504 Break', 'DK-8403-AA', 'Hann Bel-Air', 'Hann Maristes, rue HB-8', 'EN COURS', il(18, 11, 11), agent: _agentAutre, soumis: true, approuve: true, pv: true, photosAgent: 1, dLat: .014, dLng: .055),
      _sig(1070, 'Voiture', 'Toyota', 'HiAce', 'DK-4471-AG', 'Parcelles Assainies', 'Unité 17', 'ENLEVE', il(19, 9, 0), agent: _agentQuatre, soumis: true, approuve: true, pv: true, dLat: .055, dLng: .03),
      _sig(1069, 'Camion', 'Mercedes-Benz', '1517', 'DK-7710-BB', 'Hann Bel-Air', 'Route du Front de Terre', 'EN COURS', il(20, 8, 20), user: citoyen, agent: _agentMoi, soumis: true, approuve: true, pv: true, photosAgent: 1, dLat: .008, dLng: .06),
      _sig(1066, 'Moto', 'Jakarta', 'JK 125', '', 'Grand Yoff', 'Arafat, rue GY-210', 'REJETE', il(24, 12, 2), user: citoyen, agent: _agentAutre, soumis: true, motifRejet: 'Véhicule en réparation, propriétaire identifié', dLat: .035, dLng: .02),
      _sig(1063, 'Voiture', 'Ford', 'Focus', 'DK-1735-AF', "Patte d'Oie", 'Patte d’Oie Builders', 'ENLEVE', il(27, 14, 0), agent: _agentQuatre, soumis: true, approuve: true, pv: true, dLat: .045, dLng: .025),
      _sig(1061, 'Voiture', 'Kia', 'Rio', 'DK-2240-AB', 'Fann-Point E-Amitié', 'Point E, rue de Kaolack', 'NON RESOLU', il(29, 16, 0), agent: _agentQuatre, soumis: true, approuve: true, pv: true, motifNon: 'Véhicule introuvable lors de la mission', dLat: .006, dLng: -.012),
      _sig(1059, 'Voiture', 'Peugeot', '307', 'DK-5530-AC', 'Biscuiterie', 'Rue BS-41', 'EN COURS', il(25, 10, 20), agent: _agentReception, soumis: true, approuve: true, pv: true, dLat: .028, dLng: .035)..['cache'] = true,
      _sig(1058, 'Voiture', 'Toyota', 'Yaris', 'DK-7123-AD', 'Biscuiterie', 'Cité Biscuiterie', 'EN COURS', il(26, 8, 5), agent: _agentReception, soumis: true, approuve: true, pv: true, photosAgent: 1, dLat: .027, dLng: .033)..['cache'] = true,
    ]);
    // Les signalements non constatés n'ont ni marque ni plaque côté serveur.
    final camions = [
      {'id': 1, 'trailer_brand': 'Renault Kerax', 'registration': 'DK-2210-AT', 'driver_name': 'Mamadou Faye', 'seats': 3, 'destination_pound_name': null},
      {'id': 2, 'trailer_brand': 'Mercedes Actros', 'registration': 'DK-8841-BC', 'driver_name': 'Ousmane Ba', 'seats': 2, 'destination_pound_name': null},
    ];
    Map<String, dynamic> enlevement(int sig, {int camion = 1, String? label, String? plaque, String? graine, bool recu = false}) {
      final g = graine ?? 's$sig';
      return {
        'id': _idRemoval++, 'car_position_id': sig == 0 ? null : sig, 'vehicle_label': label, 'plate': plaque, 'mission_truck_id': camion,
        'dispatch_id': null, 'pound_name': 'Fourrière de Hann', 'sheet_photo_url': Demo.photo('fiche_1.jpg'),
        'photos': {for (final a in ['front', 'back', 'left', 'right']) a: Demo.photo('${g}_$a.jpg')},
        'reception': recu ? {for (final a in ['front', 'back', 'left', 'right']) a: Demo.photo('${g}_$a.jpg'), 'sheet': Demo.photo('fiche_2.jpg')} : null,
      };
    }

    _missions.addAll([
      {
        'id': 14, 'code': 'MIS-2026-014', 'title': 'Enlèvement programmé — Hann Bel-Air', 'type': 'programmee', 'status': 'planifiee',
        'scheduled_at': DateTime(2026, 10, 29, 9, 0).toIso8601String(), 'commune': 'Hann Bel-Air', 'lat': _lat + .01, 'lng': _lng + .055, 'radius': 150,
        'provider': 'Transports Diallo & Fils', 'pounds': ['Fourrière de Hann'], 'trucks': camions.map((c) => Map<String, dynamic>.from(c)).toList(),
        'agents': [_agentMoi, _agentQuatre], 'pointes': <int>[], 'reception_agent': _agentReception, 'reception_pound': 'Fourrière de Hann',
        'reception_pointee': false, 'validated_at': null, 'completed_at': null, 'vehicles': [1069, 1072, 1077], 'non_removed': <int, Map<String, dynamic>>{},
        'removals': <Map<String, dynamic>>[],
      },
      {
        'id': 11, 'code': 'MIS-2026-011', 'title': 'Enlèvement ponctuel — Biscuiterie', 'type': 'brute', 'status': 'en_reception',
        'scheduled_at': DateTime(2026, 10, 28, 8, 30).toIso8601String(), 'commune': 'Biscuiterie', 'lat': _lat + .027, 'lng': _lng + .033, 'radius': 150,
        'provider': 'Transports Diallo & Fils', 'pounds': ['Fourrière de Hann'], 'trucks': [Map<String, dynamic>.from(camions[0])..['destination_pound_name'] = 'Fourrière de Hann'],
        'agents': [_agentReception], 'pointes': [_agentReception], 'reception_agent': AppBrand.isPro ? _agentMoi : _agentAutre, 'reception_pound': 'Fourrière de Hann',
        'reception_pointee': false, 'validated_at': DateTime(2026, 10, 28, 12, 10).toIso8601String(), 'completed_at': null, 'vehicles': [1058, 1059],
        'non_removed': <int, Map<String, dynamic>>{},
        'removals': [enlevement(1058), enlevement(1059), enlevement(0, camion: 1, label: 'Toyota Corolla grise (imprévu)', plaque: 'DK-6402-AB', graine: 's1050')],
      },
      {
        'id': 9, 'code': 'MIS-2026-009', 'title': 'Enlèvement ponctuel — Parcelles Assainies', 'type': 'brute', 'status': 'terminee',
        'scheduled_at': DateTime(2026, 10, 17, 8, 30).toIso8601String(), 'commune': 'Parcelles Assainies', 'lat': _lat + .055, 'lng': _lng + .03, 'radius': 150,
        'provider': 'SENDRA Logistique', 'pounds': ['Fourrière de Mbao'], 'trucks': [Map<String, dynamic>.from(camions[1])],
        'agents': [_agentMoi, _agentQuatre], 'pointes': [_agentMoi, _agentQuatre], 'reception_agent': _agentAutre, 'reception_pound': 'Fourrière de Mbao',
        'reception_pointee': true, 'validated_at': DateTime(2026, 10, 17, 11, 0).toIso8601String(), 'completed_at': DateTime(2026, 10, 17, 15, 20).toIso8601String(),
        'vehicles': [1070], 'non_removed': <int, Map<String, dynamic>>{}, 'removals': [enlevement(1070, camion: 2, recu: true)],
      },
    ]);
  }

  Map<String, dynamic>? _s(int id) {
    for (final s in _sigs) {
      if (s['id'] == id) return s;
    }
    return null;
  }

  Map<String, dynamic>? _m(int id) {
    for (final m in _missions) {
      if (m['id'] == id) return m;
    }
    return null;
  }

  bool get _staff => AppBrand.isPro;

  // ───────── Ressources (même forme que le backend) ─────────
  String _etatAffiche(Map<String, dynamic> s) => s['etat'] as String;

  Map<String, dynamic> _ressource(Map<String, dynamic> s) {
    final photos = List<Map<String, dynamic>>.from(s['photos'] as List);
    final agentId = s['agent_id'] as int?;
    final constate = s['soumis'] == true;
    return {
      'signalementId': s['id'],
      'latitude': s['latitude'],
      'longitude': s['longitude'],
      'titre': s['title'],
      'description': s['description'],
      'commune': s['commune'],
      'etat': _etatAffiche(s),
      'non_removal_reason': s['non_removal_reason'],
      'non_removed_at': null,
      'is_approve': s['is_approve'] == true,
      'dommages_saisis': s['dommage_image'] != null,
      'formatted_date': s['created'],
      'image_url': photos.isEmpty ? null : photos.first['url'],
      'image': photos.isEmpty ? null : 'signalement/${s['id']}.jpg',
      'images': photos,
      'photos_agent': s['photos_agent'],
      'agent_id': agentId,
      'pris_en_charge_par': _staff && agentId != null ? _noms[agentId] : null,
      'pris_en_charge_par_moi': agentId != null && agentId == _moi,
      'pris_en_charge_at': s['pris_at'],
      'pv_numero': s['pv_numero'],
      'pv_signe': s['pv_signe_at'] != null,
      'pv_signe_at': s['pv_signe_at'],
      'pieces_manquantes': s['pieces_manquantes'],
      'motif_approbation': s['motif_approbation'],
      'numero_vehicule': s['numero_vehicule'],
      'marque': s['marque'],
      'model': s['model'],
      'type': s['type_car'],
      'vehicle_kind': s['vehicle_kind'],
      'categorie': s['categorie'],
      'entretien': s['entretien'],
      'adresse_precise': s['adresse_precise'],
      'motif_infraction': s['motif_infraction'],
      'explication_infraction': s['explication_infraction'],
      'verrouille': constate,
      'soumis_approbation_at': constate ? s['created'] : null,
      'historique': const [],
      'est_mien': s['user_id'] == _moi,
    };
  }

  Map<String, dynamic> _publique(Map<String, dynamic> s) => {
        'signalementId': s['id'],
        'latitude': s['latitude'],
        'longitude': s['longitude'],
        'titre': s['vehicle_kind'] ?? s['title'],
        'vehicle_kind': s['vehicle_kind'],
        'commune': s['commune'],
        'etat': _etatAffiche(s),
        'formatted_date': s['created'],
        'image_url': (s['photos'] as List).isEmpty ? null : (s['photos'] as List).first['url'],
        'est_mien': s['user_id'] == _moi,
        'public': true,
      };

  Map<String, dynamic> _vehicule(Map<String, dynamic> s) => {
        'numero': s['numero_vehicule'],
        'marque': s['marque'],
        'type': s['type_car'],
        'vehicle_kind': s['vehicle_kind'],
        'model': s['model'],
        'categorie': s['categorie'],
        'couleur': s['couleur'],
        'entretien': s['entretien'],
        for (final k in ['pays_etranger', 'defaut_controle_technique', 'pneumatiques_manquantes', 'vehicule_immerge',
          'defauts_techniques_irreversibles', 'vehicule_non_identifiable', 'vehicule_brule', 'chassis_non_reparable', 'autre_situation'])
          k: s[k],
      };

  Map<String, dynamic> _infraction(Map<String, dynamic> s) => {
        'adresse_precise': s['adresse_precise'],
        'motif_infraction': s['motif_infraction'],
        'explication_infraction': s['explication_infraction'],
        'lieu': s['lieu'],
        'nuit': s['nuit'],
        'pluie': s['pluie'],
      };

  Map<String, dynamic> _etatPv(Map<String, dynamic> s) => {
        'pv_numero': s['pv_numero'],
        'pv_signe': s['pv_signe_at'] != null,
        'pv_signe_at': s['pv_signe_at'],
        'pv_signature': s['pv_signature'],
        'pv_agent': s['agent_id'] != null ? _noms[s['agent_id']] : null,
        'pv_url': s['pv_signe_at'] != null ? Demo.fichier('pv_exemple.pdf') : null,
        'pv_url_telechargement': s['pv_signe_at'] != null ? Demo.fichier('pv_exemple.pdf') : null,
      };

  Map<String, dynamic> _priseEnCharge(Map<String, dynamic> s) => {
        'success': true,
        'agent_id': s['agent_id'],
        'pris_en_charge_par': s['agent_id'] != null ? _noms[s['agent_id']] : null,
        'pris_en_charge_par_moi': s['agent_id'] == _moi,
        'pris_en_charge_at': s['pris_at'],
      };

  Map<String, dynamic> _pourAgent(Map<String, dynamic>? s) {
    if (s == null) return {'photos_signalement': const [], 'thumbnail_url': null};
    final photos = [
      for (final p in s['photos'] as List) {'url': p['url'], 'source': 'citoyen', 'position': p['position']},
      for (final p in s['photos_agent'] as List) {'url': p['url'], 'source': 'agent', 'position': 'agent_constat'},
    ];
    return {
      'signalement_id': s['id'],
      'latitude': s['latitude'],
      'longitude': s['longitude'],
      'commune': s['commune'],
      'adresse': s['adresse_precise'],
      'thumbnail_url': photos.isEmpty ? null : photos.first['url'],
      'photos_signalement': photos,
    };
  }

  Map<String, dynamic> _mission(Map<String, dynamic> m) {
    final pointe = (m['pointes'] as List).contains(_moi);
    final receveur = m['reception_agent'] == _moi;
    final receptionPointee = receveur && m['reception_pointee'] == true;
    final debloque = pointe || receptionPointee || (receveur && m['validated_at'] != null);
    final nonEnleves = m['non_removed'] as Map<int, Map<String, dynamic>>;
    final pounds = <String>{...List<String>.from(m['pounds'] as List), m['reception_pound'] as String}.toList();
    String libelle(Map<String, dynamic>? s) => s == null ? 'Véhicule' : '${s['marque'] ?? s['_marque'] ?? ''} ${s['model'] ?? s['_modele'] ?? ''}'.trim();
    return {
      'id': m['id'], 'code': m['code'], 'title': m['title'],
      'type': m['type'] == 'brute' ? 'directe' : m['type'],
      'status': m['status'], 'scheduled_at': m['scheduled_at'],
      'commune': m['commune'], 'address': m['commune'], 'latitude': m['lat'], 'longitude': m['lng'],
      'check_in_radius_meters': m['radius'], 'provider_name': m['provider'],
      'pounds': debloque ? pounds : const <String>[],
      'trucks': debloque ? m['trucks'] as List : const [],
      'checked_in': pointe, 'is_receiver': receveur, 'reception_checked_in': receptionPointee,
      'removal_validated': m['validated_at'] != null, 'reception_pound_name': m['reception_pound'],
      'completed': m['completed_at'] != null,
      'read_only': receveur ? m['completed_at'] != null : (m['validated_at'] != null || m['completed_at'] != null),
      'removal_validated_at': m['validated_at'], 'completed_at': m['completed_at'],
      'vehicles': debloque
          ? <Map<String, dynamic>>[
              for (final id in m['vehicles'] as List)
                if (_s(id as int) != null)
                  {
                    'id': id,
                    'label': libelle(_s(id)).isEmpty ? (_s(id)!['title'] ?? 'Véhicule') : libelle(_s(id)),
                    'plate': _s(id)!['numero_vehicule'] ?? _s(id)!['_plaque'],
                    'non_removal_reason': nonEnleves[id]?['reason'],
                    'non_removed_at': nonEnleves[id]?['at'],
                    ..._pourAgent(_s(id)),
                  }
            ]
          : const [],
      'removals': debloque
          ? <Map<String, dynamic>>[
              for (final r in m['removals'] as List<Map<String, dynamic>>)
                {
                  'id': r['id'], 'car_position_id': r['car_position_id'],
                  'vehicle_label': r['vehicle_label'] ?? (r['car_position_id'] != null ? libelle(_s(r['car_position_id'] as int)) : 'Véhicule'),
                  'plate': r['plate'] ?? (r['car_position_id'] != null ? (_s(r['car_position_id'] as int) ?? const <String, dynamic>{})['numero_vehicule'] : null),
                  'mission_truck_id': r['mission_truck_id'], 'dispatch_id': r['dispatch_id'], 'pound_name': r['pound_name'],
                  'sheet_photo_url': r['sheet_photo_url'], 'photos': r['photos'],
                  'received': r['reception'] != null,
                  'reception_photos': r['reception'] ?? <String, dynamic>{},
                  ..._pourAgent(r['car_position_id'] != null ? _s(r['car_position_id'] as int) : null),
                }
            ]
          : const [],
      'dispatches': const [],
    };
  }

  _Reponse _missionOk(Map<String, dynamic> m, [String message = 'Enregistré.']) =>
      _Reponse({'message': message, 'data': _mission(m)});

  // ───────── Routage ─────────
  _Reponse traiter(String methode, String chemin, Map<String, dynamic> d, Map<String, Uint8List> f) {
    final p = chemin.split('/').where((e) => e.isNotEmpty).toList();
    if (p.isEmpty) return const _Reponse({'message': 'Route inconnue'}, 404);
    final id = p.length > 1 ? int.tryParse(p[1]) : null;
    switch (p[0]) {
      case 'login':
        _tel = (d['telephone'] ?? _tel).toString();
        return _Reponse({
          'success': true, 'message': 'Connexion réussie.', 'token': 'demo-token', 'id': _moi,
          'fullName': '$_prenom $_nom', 'first_name': _prenom, 'last_name': _nom, 'photo_url': _photoProfil,
          'phone': _tel, 'role_id': AppBrand.isPro ? 2 : 5, 'token_type': 'bearer',
        });
      case 'send-verification-code':
        return const _Reponse({'success': true, 'message': 'Code de vérification envoyé.'});
      case 'check-phone':
        return const _Reponse({'exists': false});
      case 'verify-code':
        final ok = RegExp(r'^\d{6}$').hasMatch('${d['code'] ?? ''}');
        return ok
            ? const _Reponse({'success': true, 'message': 'Vérifié avec succés.'})
            : const _Reponse({'success': false, 'message': 'Le code de vérification est invalide.'}, 400);
      case 'register':
        _prenom = '${d['first_name'] ?? _prenom}';
        _nom = '${d['last_name'] ?? _nom}';
        _tel = '${d['telephone'] ?? _tel}';
        _noms[_moi] = '$_prenom $_nom';
        return const _Reponse({'message': 'Registration successful.'});
      case 'reset-password':
        return const _Reponse({'success': true, 'message': 'Mot de passe réinitialisé avec succès.'});
      case 'change-password':
        return const _Reponse({'success': true, 'message': 'Mot de passe modifié avec succès.'});
      case 'logout':
        return const _Reponse({'message': 'Successfully logged out'});
      case 'me':
        return _Reponse({'id': _moi, 'first_name': _prenom, 'last_name': _nom, 'telephone': _tel, 'role_id': AppBrand.isPro ? 2 : 5});
      case 'profile':
        _prenom = '${d['first_name'] ?? _prenom}';
        _nom = '${d['last_name'] ?? _nom}';
        if (f['photo'] != null) _photoProfil = _dataUri(f['photo']!);
        _noms[_moi] = '$_prenom $_nom';
        return _Reponse({'success': true, 'message': 'Profil mis à jour.', 'first_name': _prenom, 'last_name': _nom, 'photo_url': _photoProfil});
      case 'delete-user':
        return const _Reponse({'message': 'Utilisateur supprimé avec succès.'});
      case 'voirSignalements':
        return _Reponse([for (final s in _sigs.reversed.toList()..sort((a, b) => (b['id'] as int) - (a['id'] as int))) if (s['user_id'] == _moi) _ressource(s)]);
      case 'listerSignalements':
        final liste = _sigs.where((s) => s['cache'] != true).toList()..sort((a, b) => (b['id'] as int) - (a['id'] as int));
        return _Reponse({
          'data': [for (final s in liste) _ressource(s)],
          'links': {'first': null, 'last': null, 'prev': null, 'next': null},
          'meta': {'current_page': 1, 'last_page': 1, 'per_page': 50, 'total': liste.length},
        });
      case 'listerSignalement':
        final s = id == null ? null : _s(id);
        return s == null ? const _Reponse({'message': 'Introuvable'}, 404) : _Reponse({'data': [_ressource(s)]});
      case 'signalementsCommunaute':
        final liste = _sigs.where((s) => s['cache'] != true).toList()..sort((a, b) => (b['id'] as int) - (a['id'] as int));
        return _Reponse([for (final s in liste) _publique(s)]);
      case 'faireSignalement':
        return _creerSignalement(d);
      case 'signalements':
        return _signalementAgent(methode, p, d);
      case 'vehicule':
        final s = id == null ? null : _s(id);
        if (s == null) return const _Reponse([]);
        if (methode == 'PUT') {
          if (s['soumis'] == true) return const _Reponse({'success': false, 'message': 'Ce signalement a été envoyé pour approbation : il n\'est plus modifiable.'}, 423);
          const champs = ['numero_vehicule', 'marque', 'vehicle_kind', 'model', 'categorie', 'couleur', 'entretien', 'pays_etranger', 'autre_situation',
            'defaut_controle_technique', 'pneumatiques_manquantes', 'vehicule_immerge', 'defauts_techniques_irreversibles', 'vehicule_non_identifiable',
            'vehicule_brule', 'chassis_non_reparable'];
          for (final k in champs) {
            if (d.containsKey(k)) s[k] = d[k] is bool ? ((d[k] as bool) ? 1 : 0) : d[k];
          }
          if (d.containsKey('type')) s['type_car'] = d['type'];
          s['agent_id'] ??= _moi;
          return _Reponse({'success': true, 'data': _vehicule(s)});
        }
        return _Reponse(_vehicule(s));
      case 'infraction':
        final s = id == null ? null : _s(id);
        if (s == null) return const _Reponse([]);
        if (methode == 'PUT') {
          if (s['soumis'] == true) return const _Reponse({'success': false, 'message': 'Ce signalement a été envoyé pour approbation : il n\'est plus modifiable.'}, 423);
          for (final k in ['adresse_precise', 'motif_infraction', 'explication_infraction', 'lieu', 'nuit', 'pluie']) {
            if (d.containsKey(k)) s[k] = d[k] is bool ? ((d[k] as bool) ? 1 : 0) : d[k];
          }
          return _Reponse({'success': true, 'data': _infraction(s)});
        }
        return _Reponse(_infraction(s));
      case 'constatation':
        final s = id == null ? null : _s(id);
        if (s == null) return const _Reponse({'message': 'Introuvable'}, 404);
        final photos = s['photos_agent'] as List;
        if (methode == 'DELETE' && p.length > 3) {
          final pid = int.tryParse(p[3]);
          photos.removeWhere((x) => x['id'] == pid);
          return const _Reponse({'success': true});
        }
        if (photos.length >= 4) return const _Reponse({'success': false, 'message': 'Quatre photos au maximum : supprimez-en une pour en ajouter une autre.'}, 422);
        final octets = f['photo'];
        final nouvelle = {'id': _idPhoto++, 'url': octets != null ? _dataUri(octets) : Demo.photo('exemple_1.jpg'), 'position': 'agent_constat'};
        photos.add(nouvelle);
        s['agent_id'] ??= _moi;
        return _Reponse({'success': true, 'id': nouvelle['id'], 'url': nouvelle['url']}, 201);
      case 'enregistrerDommages':
        final s = id == null ? null : _s(id);
        if (s == null) return const _Reponse({'message': 'Introuvable'}, 404);
        s['dommage_image'] = d['signature'] ?? Demo.photo('s${s['id']}_detail.jpg');
        s['pieces_manquantes'] = d['pieces_manquantes'];
        s['soumis'] = true;
        s['etat'] = 'EN COURS';
        s['agent_id'] ??= _moi;
        s['pv_numero'] ??= 'PV-2026-0${_numPv++}';
        return _Reponse({'message': 'Les dommages ont été enregistrés. Une demande d’approbation a été envoyée à l’administration.', 'dommage_image': 'dommage.png', 'signalement': {'id': s['id']}});
      case 'voirDommages':
        final s = id == null ? null : _s(id);
        if (s == null) return const _Reponse({'message': 'Aucun signalement trouvé pour ce véhicule.'}, 404);
        return _Reponse({'message': 'Détails des dommages récupérés avec succès.', 'dommages': s['dommage_image']});
      case 'missions':
        return _routeMission(methode, p, d, f);
    }
    return _Reponse({'message': 'Fonction non disponible dans la démo ($chemin).'}, 404);
  }

  _Reponse _creerSignalement(Map<String, dynamic> d) {
    final id = _idSig++;
    final photos = <Map<String, dynamic>>[];
    for (final ph in (d['photos'] as List? ?? const [])) {
      final b64 = ph is Map ? '${ph['image'] ?? ''}' : '';
      photos.add({
        'url': b64.isEmpty ? Demo.photo('exemple_1.jpg') : 'data:image/jpeg;base64,$b64',
        'position': ph is Map ? (ph['position'] ?? 'vue_ensemble') : 'vue_ensemble',
        'source': 'citoyen',
      });
    }
    final kind = '${d['vehicle_kind'] ?? d['titre'] ?? 'Voiture'}';
    final s = _sig(id, kind, '', '', '', '${d['commune'] ?? ''}'.isEmpty ? 'Médina' : '${d['commune']}', '${d['adresse_precise'] ?? ''}', 'SIGNALE', DateTime.now(),
        user: _moi, desc: '${d['description'] ?? ''}');
    s['photos'] = photos.isEmpty ? s['photos'] : photos;
    s['latitude'] = '${d['latitude'] ?? _lat}';
    s['longitude'] = '${d['longitude'] ?? _lng}';
    _sigs.add(s);
    return const _Reponse({'message': 'Signalisation effectuée avec succès'});
  }

  _Reponse _signalementAgent(String methode, List<String> p, Map<String, dynamic> d) {
    final s = p.length > 1 ? _s(int.tryParse(p[1]) ?? -1) : null;
    if (s == null || p.length < 3) return const _Reponse({'message': 'Introuvable'}, 404);
    if (p[2] == 'prise-en-charge') {
      if (methode == 'DELETE') {
        if (s['agent_id'] != _moi) return const _Reponse({'success': false, 'message': 'Vous ne détenez pas ce signalement.'}, 409);
        if (s['soumis'] == true) return const _Reponse({'success': false, 'message': 'Constatation déjà transmise : le signalement ne peut plus être libéré.'}, 423);
        s['agent_id'] = null;
        s['pris_at'] = null;
        return _Reponse(_priseEnCharge(s));
      }
      if (s['agent_id'] != null && s['agent_id'] != _moi) {
        return _Reponse({'success': false, 'message': 'Ce signalement est déjà pris en charge par ${_noms[s['agent_id']]}.'}, 409);
      }
      s['agent_id'] = _moi;
      s['pris_at'] = DateTime.now().toIso8601String();
      return _Reponse(_priseEnCharge(s));
    }
    if (p[2] == 'pv') {
      if (p.length > 3 && p[3] == 'signer') {
        if (s['soumis'] != true) return const _Reponse({'success': false, 'message': 'La constatation doit d’abord être envoyée pour approbation.'}, 422);
        if (s['pv_signe_at'] != null) return _Reponse({'success': false, 'message': 'Le procès-verbal est déjà signé.', ..._etatPv(s)}, 409);
        s['pv_signature'] = d['signature'];
        s['pv_signe_at'] = _date(DateTime.now());
        return _Reponse({'success': true, 'message': 'Procès-verbal signé.', ..._etatPv(s)});
      }
      if (s['pv_signe_at'] == null) return const _Reponse({'success': false, 'message': 'Procès-verbal pas encore signé.'}, 404);
      return _Reponse({'success': true, ..._etatPv(s)});
    }
    return const _Reponse({'message': 'Introuvable'}, 404);
  }

  _Reponse _routeMission(String methode, List<String> p, Map<String, dynamic> d, Map<String, Uint8List> f) {
    if (p.length == 1) {
      final visibles = _missions.where((m) =>
          (m['agents'] as List).contains(_moi) || m['reception_agent'] == _moi || (m['type'] == 'brute' && (m['agents'] as List).isEmpty));
      return _Reponse({'data': [for (final m in visibles) _mission(m)]});
    }
    final m = _m(int.tryParse(p[1]) ?? -1);
    if (m == null) return const _Reponse({'message': 'Mission introuvable.'}, 404);
    if (p.length == 2) return _Reponse({'data': _mission(m)});
    final action = p[2];
    String? url(String champ) => f[champ] != null ? _dataUri(f[champ]!) : null;
    switch (action) {
      case 'pointer':
        (m['pointes'] as List).add(_moi);
        if (m['status'] == 'planifiee') m['status'] = 'en_cours';
        return _missionOk(m, 'Pointage enregistré.');
      case 'enlevements':
        if (p.length > 4 && p[4] == 'modifier') {
          final r = (m['removals'] as List<Map<String, dynamic>>).firstWhere((x) => '${x['id']}' == p[3], orElse: () => <String, dynamic>{});
          if (r.isEmpty) return const _Reponse({'message': 'Enlèvement introuvable.'}, 404);
          final photos = Map<String, dynamic>.from(r['photos'] as Map);
          for (final a in ['front', 'back', 'left', 'right']) {
            if (url(a) != null) photos[a] = url(a);
          }
          r['photos'] = photos;
          if (url('sheet') != null) r['sheet_photo_url'] = url('sheet');
          if (d['mission_truck_id'] != null) r['mission_truck_id'] = int.tryParse('${d['mission_truck_id']}');
          if (d['vehicle_label'] != null) r['vehicle_label'] = d['vehicle_label'];
          if (d['plate'] != null) r['plate'] = d['plate'];
          return _missionOk(m, 'Enlèvement modifié.');
        }
        final sig = int.tryParse('${d['car_position_id'] ?? ''}');
        (m['removals'] as List<Map<String, dynamic>>).add({
          'id': _idRemoval++, 'car_position_id': sig, 'vehicle_label': d['vehicle_label'], 'plate': d['plate'],
          'mission_truck_id': int.tryParse('${d['mission_truck_id'] ?? ''}'), 'dispatch_id': null, 'pound_name': null,
          'sheet_photo_url': url('sheet'),
          'photos': {for (final a in ['front', 'back', 'left', 'right']) if (url(a) != null) a: url(a)},
          'reception': null,
        });
        if (sig != null) (m['non_removed'] as Map<int, Map<String, dynamic>>).remove(sig);
        return _missionOk(m, 'Enlèvement enregistré.');
      case 'vehicules':
        final vid = int.tryParse(p.length > 3 ? p[3] : '');
        if (vid != null) (m['non_removed'] as Map<int, Map<String, dynamic>>)[vid] = {'reason': '${d['reason'] ?? ''}', 'at': DateTime.now().toIso8601String()};
        return _missionOk(m, 'Véhicule déclaré non enlevé.');
      case 'camions':
        final tid = int.tryParse(p.length > 3 ? p[3] : '');
        for (final t in m['trucks'] as List) {
          if (t['id'] == tid) t['destination_pound_name'] = d['pound_name'];
        }
        return _missionOk(m, 'Fourrière du camion enregistrée.');
      case 'valider-enlevement':
        m['validated_at'] = DateTime.now().toIso8601String();
        m['status'] = 'en_reception';
        return _missionOk(m, 'Enlèvement validé.');
      case 'pointer-reception':
        m['reception_pointee'] = true;
        return _missionOk(m, 'Pointage à la fourrière enregistré.');
      case 'receptions':
        final r = (m['removals'] as List<Map<String, dynamic>>).firstWhere((x) => '${x['id']}' == (p.length > 3 ? p[3] : ''), orElse: () => <String, dynamic>{});
        if (r.isEmpty) return const _Reponse({'message': 'Enlèvement introuvable.'}, 404);
        final avant = Map<String, dynamic>.from(r['reception'] as Map? ?? const {});
        for (final a in ['front', 'back', 'left', 'right', 'sheet']) {
          if (url(a) != null) avant[a] = url(a);
        }
        r['reception'] = avant;
        return _missionOk(m, 'Réception enregistrée.');
      case 'terminer':
        m['completed_at'] = DateTime.now().toIso8601String();
        m['status'] = 'terminee';
        for (final r in m['removals'] as List<Map<String, dynamic>>) {
          final s = r['car_position_id'] != null ? _s(r['car_position_id'] as int) : null;
          if (s != null && s['etat'] != 'REJETE') {
            s['etat'] = 'ENLEVE';
            s['cache'] = false;
          }
        }
        return _missionOk(m, 'Mission terminée.');
    }
    return const _Reponse({'message': 'Action de mission inconnue.'}, 404);
  }
}
