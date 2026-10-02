import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Le secret ne quitte le stockage protégé que pendant l'enregistrement et
/// immédiatement après une authentification biométrique pour signer un défi.
class DeviceIdentity {
  static const _metadata = FlutterSecureStorage();
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

  Future<String?> deviceId(int userId) => _metadata.read(key: _idKey(userId));

  Future<({String deviceId, String secret})> prepare(int userId) async {
    var id = await deviceId(userId);
    if (id != null) {
      final existing = await _biometric.read(key: _secretKey(userId));
      if (existing == null) {
        throw StateError('La clé biométrique de ce téléphone est indisponible. Contactez votre responsable.');
      }
      return (deviceId: id, secret: existing);
    }
    id = const Uuid().v4();
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final secret = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    await _biometric.write(key: _secretKey(userId), value: secret);
    final verified = await _biometric.read(key: _secretKey(userId));
    if (verified != secret) throw StateError('Vérification biométrique impossible.');
    await _metadata.write(key: _idKey(userId), value: id);
    return (deviceId: id, secret: secret);
  }

  Future<String> sign(int userId, String challengeId, String requestId, String purpose) async {
    final secret = await _biometric.read(key: _secretKey(userId));
    if (secret == null) throw StateError('Clé biométrique introuvable. Contactez votre responsable.');
    final message = '$challengeId|$requestId|$purpose';
    return Hmac(sha256, _hexBytes(secret)).convert(utf8.encode(message)).toString();
  }

  List<int> _hexBytes(String value) => List<int>.generate(value.length ~/ 2,
      (index) => int.parse(value.substring(index * 2, index * 2 + 2), radix: 16));
}
