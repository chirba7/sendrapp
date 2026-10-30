import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/strings.dart';

/// Client HTTP de toute l'app, installé par main.dart avec
/// `http.runWithClient` : chaque `http.get/post/…`, et aussi chaque
/// `MultipartRequest.send()`, passe par ici sans toucher aux écrans.
///
/// Sécurité (30/10/2026) — les jetons expirent maintenant (30 jours) et
/// sont refusés après un changement de mot de passe ou l'archivage du
/// compte. Avant, un 401 laissait l'utilisateur bloqué sur « Connexion
/// momentanément impossible ». Désormais :
///  - 401 sur une requête authentifiée : on vérifie d'abord avec /api/me
///    (un 401 isolé ne doit pas effacer la session d'un agent sur le
///    terrain) ; si /me refuse aussi, la session est terminée et l'app
///    revient à l'écran de connexion ;
///  - 403 avec `code = compte_desactive` : compte archivé, même chose.
///
/// Ajoute aussi `Accept: application/json` quand il manque : Laravel
/// renvoie alors ses erreurs de validation en JSON (422 + message) au lieu
/// d'une redirection que l'app ne savait pas lire.
class SessionClient extends http.BaseClient {
  SessionClient(this._interne);

  final http.Client _interne;
  static bool _verificationEnCours = false;
  static bool _expirationEnCours = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!request.finalized && !request.headers.containsKey('Accept')) {
      request.headers['Accept'] = 'application/json';
    }

    final jeton = _jeton(request);
    final reponse = await _interne.send(request);
    if (jeton == null || _exclue(request.url)) return reponse;

    if (reponse.statusCode == 401) {
      unawaited(_verifier(jeton));
      return reponse;
    }

    if (reponse.statusCode == 403) {
      // Le corps n'est lisible qu'une fois : on le garde pour l'écran.
      final octets = await reponse.stream.toBytes();
      final corps = _lire(octets);
      if (corps?['code'] == 'compte_desactive') {
        unawaited(_expirer(jeton, corps?['message']?.toString()));
      }
      return http.StreamedResponse(
        Stream.value(octets),
        reponse.statusCode,
        contentLength: octets.length,
        request: reponse.request,
        headers: reponse.headers,
        isRedirect: reponse.isRedirect,
        persistentConnection: reponse.persistentConnection,
        reasonPhrase: reponse.reasonPhrase,
      );
    }

    return reponse;
  }

  @override
  void close() => _interne.close();

  static String? _jeton(http.BaseRequest request) {
    final valeur = request.headers['Authorization'] ?? '';
    if (!valeur.startsWith('Bearer ')) return null;
    final jeton = valeur.substring(7).trim();
    return jeton.isEmpty ? null : jeton;
  }

  /// La connexion elle-même et la vérification /me ne déclenchent rien.
  static bool _exclue(Uri url) {
    final chemin = url.path;
    return chemin.endsWith('/api/login') || chemin.endsWith('/api/me');
  }

  static Map<String, dynamic>? _lire(List<int> octets) {
    try {
      final decode = jsonDecode(utf8.decode(octets));
      return decode is Map<String, dynamic> ? decode : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _verifier(String jeton) async {
    if (_verificationEnCours || _expirationEnCours) return;
    _verificationEnCours = true;
    try {
      final reponse = await _interne.post(
        Uri.parse('${Strings.apiURI}me'),
        headers: {'Authorization': 'Bearer $jeton', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      if (reponse.statusCode == 401 || reponse.statusCode == 403) {
        await _expirer(jeton, _lire(reponse.bodyBytes)?['message']?.toString());
      }
    } catch (e) {
      // Pas de réseau ou serveur injoignable : on ne déconnecte personne.
      if (kDebugMode) debugPrint('Vérification de session impossible : $e');
    } finally {
      _verificationEnCours = false;
    }
  }

  static Future<void> _expirer(String jeton, String? message) async {
    if (_expirationEnCours) return;
    _expirationEnCours = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Entre-temps, l'utilisateur s'est peut-être reconnecté.
      if (prefs.getString('token') != jeton) return;
      // Mêmes clés que la déconnexion du menu (drawer_screen.dart).
      for (final cle in ['token', 'userId', 'fullName', 'phone', 'lastRoute', 'role_id']) {
        await prefs.remove(cle);
      }
      if (Get.currentRoute != Routes.signInScreen) {
        Get.offAllNamed(Routes.signInScreen);
      }
      Get.showSnackbar(GetSnackBar(
        title: 'Session terminée',
        message: (message == null || message.isEmpty)
            ? 'Votre session a expiré, veuillez vous reconnecter.'
            : message,
        icon: const Icon(Icons.lock_clock_outlined, color: Colors.white),
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
        borderRadius: 8,
      ));
    } finally {
      _expirationEnCours = false;
    }
  }
}
