import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import 'device_identity.dart';
import 'pointage_api.dart';

class PointageController extends ChangeNotifier {
  PointageController({PointageApi? api}) : api = api ?? PointageApi();

  final PointageApi api;
  final DeviceIdentity deviceIdentity = DeviceIdentity();
  bool loadingInitial = true;
  bool busy = false;
  String? error;
  String? notice;
  String status = 'not_registered';
  Map<String, dynamic>? user;
  Map<String, dynamic>? assignment;
  Map<String, dynamic>? openSession;
  List<Map<String, dynamic>> history = [];
  bool deviceRegistered = false;
  bool thisDeviceRegistered = false;
  bool pointageAvailable = false;

  bool get isSignedIn => api.token != null;

  Future<void> initialize() async {
    try {
      await api.restoreToken();
      if (isSignedIn) await refresh();
    } catch (e) {
      error = _message(e);
    } finally {
      loadingInitial = false;
      notifyListeners();
    }
  }

  Future<void> sendCode(String phone) async {
    await _run(() => api.request('POST', '/send-verification-code', body: {'telephone': phone}),
        success: 'Code envoyé par SMS.');
  }

  Future<void> verifyCode(String phone, String code) async {
    await _run(() => api.request('POST', '/verify-code', body: {'telephone': phone, 'code': code}),
        success: 'Numéro vérifié.');
  }

  Future<bool?> phoneExists(String phone) async {
    bool? exists;
    await _run(() async {
      final response = await api.request('POST', '/check-phone', body: {'telephone': phone.trim()});
      exists = response['exists'] == true;
    });
    return exists;
  }

  Future<void> resetPassword(String phone, String password) async {
    await _run(() async {
      await api.request('POST', '/reset-password', body: {
        'telephone': phone.trim(), 'password': password,
        'password_confirmation': password,
      });
      await _login(phone.trim(), password);
    }, success: 'Mot de passe modifié. Vous êtes connecté.');
  }

  Future<void> register({required String firstName, required String lastName,
    required String phone, required String password}) async {
    await _run(() async {
      await api.request('POST', '/pointage/inscription', body: {
        'first_name': firstName.trim(), 'last_name': lastName.trim(),
        'telephone': phone.trim(), 'password': password,
        'password_confirmation': password,
      });
      await _login(phone, password);
    }, success: 'Inscription envoyée. Un administrateur doit la valider.');
  }

  Future<void> login(String phone, String password) async {
    await _run(() => _login(phone.trim(), password));
  }

  Future<void> _login(String phone, String password) async {
    final response = await api.request('POST', '/login', body: {
      'telephone': phone, 'password': password,
    });
    final token = response['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiFailure('Le serveur n’a pas fourni de session.', null);
    }
    await api.saveToken(token);
    await refresh(throwOnError: true);
  }

  Future<void> join() async {
    await _run(() async {
      await api.request('POST', '/pointage/adhesion', authenticated: true);
      await refresh(throwOnError: true);
    }, success: 'Demande envoyée au responsable.');
  }

  Future<void> refresh({bool throwOnError = false}) async {
    try {
      final profile = await api.request('GET', '/pointage/statut', authenticated: true);
      user = (profile['user'] as Map).cast<String, dynamic>();
      status = profile['status'] as String? ?? 'not_registered';
      deviceRegistered = profile['device_registered'] == true;
      final userId = (user?['id'] as num).toInt();
      thisDeviceRegistered = deviceRegistered
          && await deviceIdentity.deviceId(userId) == profile['registered_device_id'];
      pointageAvailable = profile['pointage_available'] == true;
      if (status == 'approved') {
        final config = await api.request('GET', '/pointage/configuration', authenticated: true);
        assignment = config['assignment'] is Map ? (config['assignment'] as Map).cast<String, dynamic>() : null;
        openSession = config['open_session'] is Map ? (config['open_session'] as Map).cast<String, dynamic>() : null;
        final records = await api.request('GET', '/pointage/historique', authenticated: true);
        history = ((records['data'] as List?) ?? []).whereType<Map>()
            .map((item) => item.cast<String, dynamic>()).toList();
        final lastPage = (records['last_page'] as num?)?.toInt() ?? 1;
        for (var page = 2; page <= lastPage; page++) {
          final more = await api.request('GET', '/pointage/historique?page=$page', authenticated: true);
          history.addAll(((more['data'] as List?) ?? []).whereType<Map>()
              .map((item) => item.cast<String, dynamic>()));
        }
        final pendingRaw = await api.storage.read(key: 'pointage_pending_request');
        if (pendingRaw != null) {
          final pending = jsonDecode(pendingRaw) as Map<String, dynamic>;
          if ((pending['type'] == 'arrival' && openSession != null) ||
              (pending['type'] == 'departure' && openSession == null)) {
            await api.storage.delete(key: 'pointage_pending_request');
          }
        }
      } else {
        assignment = null;
        openSession = null;
        history = [];
      }
      error = null;
    } on ApiFailure catch (e) {
      if (e.statusCode == 401) {
        await api.clearToken();
        status = 'not_registered';
      }
      error = e.message;
      if (throwOnError) rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> punch() async {
    final arrival = openSession == null;
    await _run(() async {
      if (!pointageAvailable || !thisDeviceRegistered) {
        throw const ApiFailure('Ce téléphone n’est pas autorisé pour ce compte.', null);
      }
      final operation = openSession == null ? 'arrival' : 'departure';
      final site = assignment?['site'] is Map
          ? (assignment!['site'] as Map).cast<String, dynamic>()
          : openSession?['site'] is Map
              ? (openSession!['site'] as Map).cast<String, dynamic>() : null;
      if (site == null) throw const ApiFailure('Aucun site de pointage disponible.', null);
      final requestId = const Uuid().v4();
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const ApiFailure('Activez la localisation du téléphone.', null);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw const ApiFailure('Autorisez la position précise dans les réglages du téléphone.', null);
      }
      if (await Geolocator.getLocationAccuracy() == LocationAccuracyStatus.reduced) {
        throw const ApiFailure('Activez la position précise pour pointer.', null);
      }
      final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 25)));
      if (position.accuracy <= 0 || position.accuracy > (site['max_accuracy_meters'] as num).toDouble()) {
        throw ApiFailure('Position trop imprécise (${position.accuracy.round()} m). Réessayez dehors.', null);
      }
      final distance = Geolocator.distanceBetween(position.latitude, position.longitude,
        (site['latitude'] as num).toDouble(), (site['longitude'] as num).toDouble());
      if (distance > (site['radius_meters'] as num).toDouble()) {
        throw ApiFailure('Vous êtes à ${distance.round()} m du site, hors du rayon autorisé.', null);
      }
      final userId = (user!['id'] as num).toInt();
      final deviceId = await deviceIdentity.deviceId(userId);
      if (deviceId == null) throw const ApiFailure('Ce téléphone n’est pas autorisé.', null);
      final challenge = await api.request('POST', '/pointage/appareil/defi', authenticated: true,
        body: {'device_id': deviceId, 'request_id': requestId, 'purpose': operation});
      final challengeId = challenge['challenge_id'];
      if (challengeId is! String) {
        throw const ApiFailure('Vérification du téléphone indisponible. Réessayez.', null);
      }
      final signature = await deviceIdentity.sign(userId, challengeId, requestId, operation);
      await api.request('POST', '/pointage/pointer', authenticated: true, body: {
        'request_id': requestId, 'device_id': deviceId,
        'challenge_id': challengeId, 'device_signature': signature,
        'type': operation, 'site_id': site['id'],
        'latitude': position.latitude, 'longitude': position.longitude,
        'accuracy_meters': position.accuracy,
        'measured_at': position.timestamp.toUtc().toIso8601String(),
      });
      await refresh(throwOnError: true);
    }, success: arrival ? 'Début de travail enregistré.' : 'Fin de travail enregistrée.');
  }

  Future<void> registerDevice() async {
    await _run(() async {
      final userId = (user!['id'] as num).toInt();
      final identity = await deviceIdentity.prepare(userId);
      await api.request('POST', '/pointage/appareil/enregistrer', authenticated: true,
        body: {'device_id': identity.deviceId, 'secret': identity.secret});
      await refresh(throwOnError: true);
    }, success: 'Téléphone lié. Votre responsable doit valider votre accès.');
  }

  Future<void> logout() async {
    try {
      if (isSignedIn) await api.request('POST', '/logout', authenticated: true);
    } catch (_) {
      // Le jeton local est supprimé même si le réseau est indisponible.
    }
    await api.clearToken();
    status = 'not_registered';
    user = null;
    assignment = null;
    openSession = null;
    history = [];
    deviceRegistered = false;
    thisDeviceRegistered = false;
    pointageAvailable = false;
    error = null;
    notice = null;
    notifyListeners();
  }

  Future<void> _run(Future<dynamic> Function() operation, {String? success}) async {
    if (busy) return;
    busy = true;
    error = null;
    notice = null;
    notifyListeners();
    try {
      await operation();
      notice = success;
    } catch (e) {
      error = _message(e);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  String _message(Object error) => error is ApiFailure ? error.message :
      error is StateError ? error.message :
      'Biométrie indisponible ou annulée. Vérifiez votre empreinte ou Face ID et réessayez.';

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }
}
