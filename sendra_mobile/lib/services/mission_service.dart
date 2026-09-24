import 'dart:convert';
import 'dart:io';

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

  Future<Mission> detail(int missionId) async {
    final response = await http
        .get(Uri.parse('${Strings.apiURI}missions/$missionId'),
            headers: await _headers())
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200)
      throw Exception(_message(response, 'Impossible de charger la mission.'));
    final decoded = jsonDecode(response.body) as Map;
    return Mission.fromJson(Map<String, dynamic>.from(decoded['data'] as Map));
  }

  Future<Mission> createRemoval(int missionId,
      {int? carPositionId,
      int? truckId,
      String? vehicleLabel,
      String? plate,
      required Map<String, File> photos,
      File? sheet}) async {
    final request = http.MultipartRequest(
        'POST', Uri.parse('${Strings.apiURI}missions/$missionId/enlevements'));
    request.headers.addAll(await _authHeaders());
    if (carPositionId != null)
      request.fields['car_position_id'] = '$carPositionId';
    if (truckId != null) request.fields['mission_truck_id'] = '$truckId';
    if ((vehicleLabel ?? '').isNotEmpty)
      request.fields['vehicle_label'] = vehicleLabel!;
    if ((plate ?? '').isNotEmpty) request.fields['plate'] = plate!;
    for (final entry in photos.entries) {
      request.files
          .add(await http.MultipartFile.fromPath(entry.key, entry.value.path));
    }
    if (sheet != null) {
      request.files.add(await http.MultipartFile.fromPath('sheet', sheet.path));
    }
    final response = await http.Response.fromStream(await request.send())
        .timeout(const Duration(seconds: 60));
    if (response.statusCode < 200 || response.statusCode >= 300)
      throw Exception(
          _message(response, 'Impossible d’enregistrer l’enlèvement.'));
    final decoded = jsonDecode(response.body) as Map;
    return Mission.fromJson(Map<String, dynamic>.from(decoded['data'] as Map));
  }

  Future<Mission> updateRemoval(int missionId, int removalId,
      {required int truckId,
      String? vehicleLabel,
      String? plate,
      required Map<String, File> photos,
      File? sheet}) async {
    final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            '${Strings.apiURI}missions/$missionId/enlevements/$removalId/modifier'));
    request.headers.addAll(await _authHeaders());
    request.fields['mission_truck_id'] = '$truckId';
    if ((vehicleLabel ?? '').isNotEmpty)
      request.fields['vehicle_label'] = vehicleLabel!;
    if ((plate ?? '').isNotEmpty) request.fields['plate'] = plate!;
    for (final entry in photos.entries) {
      request.files
          .add(await http.MultipartFile.fromPath(entry.key, entry.value.path));
    }
    if (sheet != null) {
      request.files.add(await http.MultipartFile.fromPath('sheet', sheet.path));
    }
    final response = await http.Response.fromStream(await request.send())
        .timeout(const Duration(seconds: 60));
    if (response.statusCode < 200 || response.statusCode >= 300)
      throw Exception(
          _message(response, 'Impossible de modifier l’enlèvement.'));
    final decoded = jsonDecode(response.body) as Map;
    return Mission.fromJson(Map<String, dynamic>.from(decoded['data'] as Map));
  }

  Future<Mission> setTruckDestination(
      int missionId, int truckId, String poundName) async {
    final response = await http
        .post(
          Uri.parse(
              '${Strings.apiURI}missions/$missionId/camions/$truckId/destination'),
          headers: await _headers(),
          body: jsonEncode({'pound_name': poundName}),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(
          response, 'Impossible d’enregistrer la fourrière du camion.'));
    }
    final decoded = jsonDecode(response.body) as Map;
    return Mission.fromJson(Map<String, dynamic>.from(decoded['data'] as Map));
  }

  Future<Map<String, String>> _authHeaders() async {
    final headers = await _headers();
    headers.remove('Content-Type');
    return headers;
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
