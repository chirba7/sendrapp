import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:uuid/uuid.dart';

/// Le secret ne quitte le stockage protégé que pendant l'enregistrement et
/// immédiatement après une authentification biométrique pour signer un défi.
class DeviceIdentity {
  static const _metadata = FlutterSecureStorage();
  // Android ne permet pas de lier une clé Keystore à une reconnaissance
  // faciale de classe 2. La lecture de cette clé reste donc protégée par
  // l'authentification biométrique explicite dans unlock().
  static const _faceStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: false,
      storageNamespace: 'sendra_pointage_face_device',
    ),
  );
  static const _biometric = FlutterSecureStorage(
    aOptions: AndroidOptions.biometric(
      enforceBiometrics: true,
      requireBiometricsPerOperation: true,
      biometricType: AndroidBiometricType.strongBiometricOnly,
      resetOnError: false,
      biometricPromptTitle: 'Confirmer le pointage',
      biometricPromptNegativeButton: 'Annuler',
      storageNamespace: 'sendra_pointage_device',
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
      accessControlFlags: [AccessControlFlag.biometryCurrentSet],
      accountName: 'sendra_pointage_device',
      synchronizable: false,
    ),
  );

  String _idKey(int userId) => 'pointage_device_id_$userId';
  String _secretKey(int userId) => 'pointage_device_secret_$userId';
  String _modeKey(int userId) => 'pointage_device_mode_$userId';

  Future<String?> deviceId(int userId) => _metadata.read(key: _idKey(userId));

  Future<({String deviceId, String secret})> prepare(int userId) async {
    var id = await deviceId(userId);
    if (id != null) {
      final mode = await _metadata.read(key: _modeKey(userId));
      if (mode == 'face') await _authenticate();
      final existing = mode == 'face'
          ? await _faceStorage.read(key: _secretKey(userId))
          : await _biometric.read(key: _secretKey(userId));
      if (existing == null) {
        throw StateError(
          'La clé biométrique de ce téléphone est indisponible. Contactez votre responsable.',
        );
      }
      return (deviceId: id, secret: existing);
    }
    id = const Uuid().v4();
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final secret = bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    final biometrics = await LocalAuthentication().getAvailableBiometrics();
    if (biometrics.isEmpty) {
      throw StateError(
        'Aucune biométrie enregistrée sur ce téléphone. Configurez l’empreinte ou la reconnaissance faciale dans ses réglages.',
      );
    }
    final faceMode =
        Platform.isAndroid && !biometrics.contains(BiometricType.strong);
    if (faceMode) {
      await _authenticate();
      await _faceStorage.write(key: _secretKey(userId), value: secret);
    } else {
      await _biometric.write(key: _secretKey(userId), value: secret);
    }
    final verified = faceMode
        ? await _faceStorage.read(key: _secretKey(userId))
        : await _biometric.read(key: _secretKey(userId));
    if (verified != secret) {
      throw StateError('Vérification biométrique impossible.');
    }
    await _metadata.write(
      key: _modeKey(userId),
      value: faceMode ? 'face' : 'strong',
    );
    await _metadata.write(key: _idKey(userId), value: id);
    return (deviceId: id, secret: secret);
  }

  Future<String> sign(
    int userId,
    String challengeId,
    String requestId,
    String purpose,
  ) async {
    final secret = await unlock(userId);
    return signUnlocked(secret, challengeId, requestId, purpose);
  }

  Future<String> unlock(int userId) async {
    await _authenticate();
    final mode = await _metadata.read(key: _modeKey(userId));
    final secret = mode == 'face'
        ? await _faceStorage.read(key: _secretKey(userId))
        : await _biometric.read(key: _secretKey(userId));
    if (secret == null) {
      throw StateError(
        'Clé biométrique introuvable. Contactez votre responsable.',
      );
    }
    return secret;
  }

  Future<void> _authenticate() async {
    final authenticated = await LocalAuthentication().authenticate(
      localizedReason: 'Confirmez votre identité pour choisir un pointage.',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );
    if (!authenticated) {
      throw StateError('Authentification biométrique annulée.');
    }
  }

  String signUnlocked(
    String secret,
    String challengeId,
    String requestId,
    String purpose,
  ) {
    final message = '$challengeId|$requestId|$purpose';
    return Hmac(
      sha256,
      _hexBytes(secret),
    ).convert(utf8.encode(message)).toString();
  }

  List<int> _hexBytes(String value) => List<int>.generate(
    value.length ~/ 2,
    (index) => int.parse(value.substring(index * 2, index * 2 + 2), radix: 16),
  );
}
