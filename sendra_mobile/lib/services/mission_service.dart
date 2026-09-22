import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletium/models/mission.dart';
import 'package:walletium/utils/strings.dart';

class MissionService {
  Future<Map<String, String>> _headers() async {
    final token = (await SharedPreferences.getInstance()).getString('token');
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Mission>> list() async {
    final response = await http
        .get(Uri.parse('${Strings.apiURI}missions'), headers: await _headers())
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception(
          _message(response, 'Impossible de charger les missions.'));
    }
    final decoded = jsonDecode(response.body);
    final raw = decoded is List
        ? decoded
        : (decoded is Map ? decoded['data'] ?? decoded['missions'] : null);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Mission.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Mission> checkIn(
      int missionId, double latitude, double longitude, double accuracy) async {
    final response = await http
        .post(
          Uri.parse('${Strings.apiURI}missions/$missionId/pointer'),
          headers: await _headers(),
          body: jsonEncode({
            'latitude': latitude,
            'longitude': longitude,
            'accuracy': accuracy,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(response, 'Le pointage a échoué.'));
    }
    final decoded = jsonDecode(response.body);
    final data = decoded is Map
        ? decoded['data'] ?? decoded['mission'] ?? decoded
        : decoded;
    return Mission.fromJson(Map<String, dynamic>.from(data as Map));
  }

  String _message(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        return '${decoded['message']}';
      }
    } catch (_) {}
    return fallback;
  }
}
