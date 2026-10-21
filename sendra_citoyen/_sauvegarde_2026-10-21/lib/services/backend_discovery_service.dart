import 'dart:async';
import 'dart:io';

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
  static const _probeTimeout = Duration(milliseconds: 350);
  static const _batchSize = 40;

  /// Tente de retrouver le backend, met à jour [onFound] avec l'IP trouvée.
  /// Retourne l'IP trouvée (ou null si rien n'a répondu).
  static Future<String?> discoverHost() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefsKey);

    if (cached != null && await _probe(cached)) {
      return cached;
    }

    final prefixes = await _localSubnetPrefixes();
    if (prefixes.isEmpty) {
      // Pas de Wi-Fi détecté : on retente l'IP en cache par défaut, sinon rien.
      return cached;
    }

    // Un téléphone peut exposer simultanément Wi-Fi, données mobiles et
    // interfaces VPN. Scanner seulement la première interface privée pouvait
    // donc chercher le backend sur le mauvais réseau. Les sous-réseaux sont
    // testés en parallèle, avec priorité aux réseaux Wi-Fi 192.168.x.x.
    final results = await Future.wait(prefixes.map(_scanSubnet));
    final found = results.firstWhere(
      (host) => host != null,
      orElse: () => null,
    );
    if (found != null) {
      await prefs.setString(_prefsKey, found);
      return found;
    }

    return cached;
  }

  /// Déduit le préfixe /24 du réseau Wi-Fi actuel du téléphone
  /// (ex: "192.168.1.") à partir de ses propres interfaces réseau.
  static Future<List<String>> _localSubnetPrefixes() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      final prefixes = <String>{};
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ip = addr.address;
          if (ip.startsWith('192.168.') ||
              ip.startsWith('10.') ||
              _isPrivate172(ip)) {
            final parts = ip.split('.');
            if (parts.length == 4) {
              prefixes.add('${parts[0]}.${parts[1]}.${parts[2]}.');
            }
          }
        }
      }
      final ordered = prefixes.toList()
        ..sort((a, b) {
          final aWifi = a.startsWith('192.168.') ? 0 : 1;
          final bWifi = b.startsWith('192.168.') ? 0 : 1;
          return aWifi.compareTo(bWifi);
        });
      return ordered;
    } catch (_) {
      // Pas de permission réseau ou pas de Wi-Fi actif.
    }
    return const [];
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
    Socket? socket;
    try {
      // Tester l'ouverture du port est instantané, même lorsque Laravel met
      // plusieurs secondes à traiter sa première requête sous Docker/Windows.
      // L'ancienne sonde HTTP de 400 ms rejetait donc systématiquement le bon
      // serveur avant qu'il ait eu le temps de répondre.
      socket = await Socket.connect(ip, _port, timeout: _probeTimeout);
      return true;
    } catch (_) {
      return false;
    } finally {
      socket?.destroy();
    }
  }
}
