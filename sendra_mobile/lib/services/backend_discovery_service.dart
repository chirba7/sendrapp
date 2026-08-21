import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Découvre automatiquement l'IP LAN du backend local (Docker) en scannant
/// le sous-réseau du téléphone, au lieu de dépendre d'une IP codée en dur
/// dans strings.dart qui casse à chaque changement de réseau/bail DHCP.
///
/// Stratégie : réutiliser la dernière IP qui a marché (cache SharedPreferences)
/// avant de rescanner ; ne rescanner que si nécessaire (démarrage à froid ou
/// IP en cache injoignable).
class BackendDiscoveryService {
  static const _prefsKey = 'backend_host_ip';
  static const _port = 8000;
  static const _pingPath = '/api/ping';
  static const _expectedSignature = 'sendra-backend';
  static const _probeTimeout = Duration(milliseconds: 400);
  static const _batchSize = 40;

  /// Tente de retrouver le backend, met à jour [onFound] avec l'IP trouvée.
  /// Retourne l'IP trouvée (ou null si rien n'a répondu).
  static Future<String?> discoverHost() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefsKey);

    if (cached != null && await _probe(cached)) {
      return cached;
    }

    final prefix = await _localSubnetPrefix();
    if (prefix == null) {
      // Pas de Wi-Fi détecté : on retente l'IP en cache par défaut, sinon rien.
      return cached;
    }

    final found = await _scanSubnet(prefix);
    if (found != null) {
      await prefs.setString(_prefsKey, found);
      return found;
    }

    return cached;
  }

  /// Déduit le préfixe /24 du réseau Wi-Fi actuel du téléphone
  /// (ex: "192.168.1.") à partir de ses propres interfaces réseau.
  static Future<String?> _localSubnetPrefix() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ip = addr.address;
          if (ip.startsWith('192.168.') ||
              ip.startsWith('10.') ||
              _isPrivate172(ip)) {
            final parts = ip.split('.');
            if (parts.length == 4) {
              return '${parts[0]}.${parts[1]}.${parts[2]}.';
            }
          }
        }
      }
    } catch (_) {
      // Pas de permission réseau ou pas de Wi-Fi actif.
    }
    return null;
  }

  static bool _isPrivate172(String ip) {
    if (!ip.startsWith('172.')) return false;
    final second = int.tryParse(ip.split('.').elementAtOrNull(1) ?? '');
    return second != null && second >= 16 && second <= 31;
  }

  static Future<String?> _scanSubnet(String prefix) async {
    // Scan par lots pour ne pas ouvrir 254 connexions simultanément.
    for (int start = 1; start <= 254; start += _batchSize) {
      final end = (start + _batchSize - 1).clamp(1, 254);
      final candidates = [for (int i = start; i <= end; i++) '$prefix$i'];

      final results = await Future.wait(
        candidates.map((ip) => _probe(ip).then((ok) => ok ? ip : null)),
      );

      final match = results.firstWhere((r) => r != null, orElse: () => null);
      if (match != null) return match;
    }
    return null;
  }

  static Future<bool> _probe(String ip) async {
    try {
      final uri = Uri.parse('http://$ip:$_port$_pingPath');
      final response = await http.get(uri).timeout(_probeTimeout);
      return response.statusCode == 200 &&
          response.body.contains(_expectedSignature);
    } catch (_) {
      return false;
    }
  }
}
