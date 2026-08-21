/*import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DommagesController {
  Future<Map<String, dynamic>?> fetchSignalementDetails(int signalementId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print('Récupération des détails pour le signalement ID: $signalementId');

    final url = 'http://192.168.0.102:8000/api/listerSignalement/$signalementId';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      print('Réponse obtenue: ${jsonResponse.toString()}');

      if (jsonResponse.containsKey('data')) {
        final dataList = jsonResponse['data'];
        if (dataList.isNotEmpty) {
          return dataList[0];
        } else {
          throw Exception('Aucune donnée n\'a été trouvée pour ce signalement');
        }
      } else {
        throw Exception('Clé "data" manquante dans la réponse JSON');
      }
    } else {
      throw Exception('Impossible d\'afficher les détails du signalement');
    }
  }

  Future<ui.Image> loadDefaultImage() async {
    final ByteData data = await rootBundle.load('assets/images/dommages.png');
    final Uint8List bytes = data.buffer.asUint8List();
    return await _decodeImage(bytes);
  }

  Future<ui.Image> loadImageFromApi(int signalementId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print('Chargement de l\'image pour le signalement ID: $signalementId');

    final url = 'http://192.168.0.102:8000/api/voirDommages/$signalementId';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('Réponse d\'image obtenue: ${jsonResponse.toString()}');

        if (jsonResponse.containsKey('dommages') && jsonResponse['dommages'] != null) {
          final imageUrl = jsonResponse['dommages'];
          final imageBytes = await _fetchImageFromUrl(imageUrl);
          return await _decodeImage(imageBytes);
        } else {
          throw Exception('Aucune image trouvée pour ce signalement');
        }
      } else {
        throw Exception('Impossible de récupérer l\'image depuis le backend');
      }
    } catch (e) {
      print('Erreur: $e');
      return await loadDefaultImage();
    }
  }

  Future<Uint8List> _fetchImageFromUrl(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Erreur lors du téléchargement de l\'image depuis $imageUrl');
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image image) {
      completer.complete(image);
    });
    return completer.future;
  }

  Future<void> saveDrawing(int signalementId, Uint8List imageBytes) async {
    final String base64Image = base64Encode(imageBytes);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = 'http://192.168.0.102:8000/api/enregistrerDommages/$signalementId';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'signature': 'data:image/png;base64,' + base64Image,
    });

    final response = await http.put(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      print('Réponse après enregistrement: ${jsonResponse.toString()}');
      return jsonResponse['message'];
    } else {
      throw Exception('Échec de l\'enregistrement des dommages');
    }
  }
}
*/