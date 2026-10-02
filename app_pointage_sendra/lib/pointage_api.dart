import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiFailure implements Exception {
  const ApiFailure(this.message, this.statusCode);
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class PointageApi {
  PointageApi({http.Client? client, FlutterSecureStorage? storage})
      : _client = client ?? http.Client(),
        storage = storage ?? const FlutterSecureStorage();

  static const String baseUrl = String.fromEnvironment(
    'SENDRA_API_BASE_URL',
    defaultValue: 'https://backpreprod.sendra.sn/api',
  );

  final http.Client _client;
  final FlutterSecureStorage storage;
  String? token;

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    if (authenticated && (token == null || token!.isEmpty)) {
      throw const ApiFailure('Veuillez vous reconnecter.', 401);
    }
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (authenticated) 'Authorization': 'Bearer $token',
    };
    late http.Response response;
    try {
      final payload = jsonEncode(body ?? <String, dynamic>{});
      response = await switch (method) {
        'GET' => _client.get(uri, headers: headers),
        'POST' => _client.post(uri, headers: headers, body: payload),
        _ => throw ArgumentError.value(method),
      }.timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const ApiFailure('Connexion impossible. Vérifiez le réseau et réessayez.', null);
    }
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiFailure('Réponse inattendue du serveur.', response.statusCode);
    }
    if (response.statusCode >= 400) {
      var message = (data['message'] ?? data['error'] ?? 'La demande a échoué.').toString();
      if (path == '/login' && response.statusCode == 401) {
        message = 'Numéro ou mot de passe incorrect. Si ce numéro vous appartient, utilisez « Mot de passe oublié ? » pour créer un nouveau mot de passe par SMS.';
      }
      final errors = data['errors'] ?? data['errorList'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) message = first.first.toString();
      }
      throw ApiFailure(message, response.statusCode);
    }
    return data;
  }

  Future<void> restoreToken() async => token = await storage.read(key: 'pointage_token');

  Future<void> saveToken(String value) async {
    token = value;
    await storage.write(key: 'pointage_token', value: value);
  }

  Future<void> clearToken() async {
    token = null;
    await storage.delete(key: 'pointage_token');
    await storage.delete(key: 'pointage_pending_request');
  }

  void dispose() => _client.close();
}
