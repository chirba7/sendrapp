import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sendra_pointage/pointage_api.dart';
import 'package:sendra_pointage/pointage_controller.dart';

class _MemoryStorage extends FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];
}

void main() {
  test('une connexion refusée explique comment récupérer le compte', () async {
    final api = PointageApi(
      client: MockClient(
        (_) async => http.Response('{"error":"Unauthorized"}', 401),
      ),
    );
    await expectLater(
      api.request(
        'POST',
        '/login',
        body: {'telephone': '771234567', 'password': 'incorrect'},
      ),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.message,
          'message',
          contains('Mot de passe oublié'),
        ),
      ),
    );
    api.dispose();
  });

  test('mot de passe oublié réinitialise puis connecte le compte', () async {
    final paths = <String>[];
    Map<String, dynamic>? resetBody;
    final api = PointageApi(
      storage: _MemoryStorage(),
      client: MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path.endsWith('/reset-password')) {
          resetBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{"success":true}', 200);
        }
        if (request.url.path.endsWith('/login')) {
          return http.Response('{"token":"test-token"}', 200);
        }
        if (request.url.path.endsWith('/pointage/statut')) {
          return http.Response(
            '{"user":{"id":1},"status":"pending","device_registered":false}',
            200,
          );
        }
        return http.Response('{}', 404);
      }),
    );
    final controller = PointageController(api: api);
    await controller.resetPassword('771234567', 'nouveau123');
    expect(controller.error, isNull);
    expect(controller.isSignedIn, isTrue);
    expect(paths, [
      '/api/reset-password',
      '/api/login',
      '/api/pointage/statut',
    ]);
    expect(resetBody, containsPair('password_confirmation', 'nouveau123'));
    controller.dispose();
  });
}
