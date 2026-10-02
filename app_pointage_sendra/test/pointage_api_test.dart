import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sendra_pointage/pointage_api.dart';

void main() {
  test('une connexion refusée explique comment récupérer le compte', () async {
    final api = PointageApi(client: MockClient((_) async =>
        http.Response('{"error":"Unauthorized"}', 401)));
    await expectLater(
      api.request('POST', '/login', body: {'telephone': '771234567', 'password': 'incorrect'}),
      throwsA(isA<ApiFailure>().having((failure) => failure.message,
          'message', contains('Mot de passe oublié'))),
    );
    api.dispose();
  });
}
