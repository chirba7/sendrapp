import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:walletium/utils/strings.dart';

import 'approbation_screen.dart';

class DommagesScreen extends StatefulWidget {
  final int signalementId;

  const DommagesScreen({Key? key, required this.signalementId}) : super(key: key);

  @override
  _DommagesScreenState createState() => _DommagesScreenState();
}

class _DommagesScreenState extends State<DommagesScreen> {
  final List<Offset?> _points = [];
  Map<String, dynamic>? signalementDetails;
  ui.Image? _image;
  late double _imageWidth;
  late double _imageHeight;

  @override
  void initState() {
    super.initState();
    print('DommagesScreen initialized');

    // Lock the orientation to landscape mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    fetchSignalementDetails(widget.signalementId);
    _loadImageFromApi(widget.signalementId);  // Charge l'image depuis l'API
  }

  @override
  void dispose() {
    // Restore the orientation to allow both portrait and landscape when the screen is disposed
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    super.dispose();
  }

  // Fonction pour récupérer les détails du signalement
  Future<void> fetchSignalementDetails(int signalementId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print('Récupération des détails pour le signalement ID: $signalementId');

    final url = '${Strings.apiURI}listerSignalement/$signalementId';
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
          setState(() {
            signalementDetails = dataList[0];
          });
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

  // Fonction pour charger une image par défaut
  Future<void> _loadDefaultImage() async {
    final ByteData data = await rootBundle.load('assets/images/dommages.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final image = await _decodeImage(bytes);

    setState(() {
      _image = image;
      _imageWidth = image.width.toDouble();
      _imageHeight = image.height.toDouble();
    });
  }

// Nouvelle fonction pour charger l'image depuis l'API sans redimensionnement
  Future<void> _loadImageFromApi(int signalementId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print('Chargement de l\'image pour le signalement ID: $signalementId');

    final url = '${Strings.apiURI}voirDommages/$signalementId';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('Réponse d\'image obtenue: ${jsonResponse.toString()}');

        // Vérifiez si la clé "dommages" est présente
        if (jsonResponse.containsKey('dommages') && jsonResponse['dommages'] != null) {
          final imageUrl = jsonResponse['dommages'];
          final imageBytes = await _fetchImageFromUrl(imageUrl);
          final image = await _decodeImage(imageBytes);

          setState(() {
            _image = image;
            _imageWidth = image.width.toDouble();
            _imageHeight = image.height.toDouble();
          });
        } else {
          throw Exception('Aucune image trouvée pour ce signalement');
        }
      } else {
        throw Exception('Impossible de récupérer l\'image depuis le backend');
      }
    } catch (e) {
      print('Erreur: $e');
      // Charger l'image par défaut en cas d'erreur
      print('Chargement de l\'image par défaut');
      await _loadDefaultImage();
    }
  }


// Fonction utilitaire pour récupérer l'image depuis une URL
  Future<Uint8List> _fetchImageFromUrl(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Erreur lors du téléchargement de l\'image depuis $imageUrl');
    }
  }



  // Fonction utilitaire pour décoder les données d'image
  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image image) {
      completer.complete(image);
    });
    return completer.future;
  }

  // Fonction pour enregistrer le dessin
  Future<void> _saveDrawing() async {
    print('Enregistrement du dessin...');

    // Calculer le facteur de mise à l'échelle
    double scaleX = _imageWidth / MediaQuery.of(context).size.width;
    double scaleY = _imageHeight / (MediaQuery.of(context).size.width * (_imageHeight / _imageWidth));

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, _imageWidth, _imageHeight),
    );

    // Dessiner l'image
    final Rect srcRect = Rect.fromLTWH(0, 0, _image!.width.toDouble(), _image!.height.toDouble());
    final Rect dstRect = Rect.fromLTWH(0, 0, _imageWidth, _imageHeight);
    canvas.drawImageRect(_image!, srcRect, dstRect, Paint());

    // Ajuster les points et dessiner la signature
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (int i = 0; i < _points.length - 1; i++) {
      if (_points[i] != null && _points[i + 1] != null) {
        // Ajuster les points en fonction du facteur de mise à l'échelle
        double dx1 = _points[i]!.dx * scaleX;
        double dy1 = _points[i]!.dy * scaleY;
        double dx2 = _points[i + 1]!.dx * scaleX;
        double dy2 = _points[i + 1]!.dy * scaleY;

        canvas.drawLine(Offset(dx1, dy1), Offset(dx2, dy2), paint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(_imageWidth.toInt(), _imageHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List imageBytes = byteData!.buffer.asUint8List();
    final String base64Image = base64Encode(imageBytes);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final signalementId = widget.signalementId;
    final url = '${Strings.apiURI}enregistrerDommages/$signalementId';
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(jsonResponse['message']),
        duration: Duration(seconds: 1),
      ));

      Future.delayed(Duration(seconds: 1), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ApprovalForm(signalementId: widget.signalementId),
          ),
        );
      });

    } else {
      print('Erreur lors de l\'enregistrement du dessin');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec de l\'enregistrement des dommages')));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dommages',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold, // Met le texte en gras
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: Column(
        children: [
          if (signalementDetails != null) ...[
            Text('Détails du signalement :'),
            Text('ID : ${signalementDetails!['signalementId']}'),
          ],
          Expanded(
            child: Stack(
              children: [
                if (_image != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: _imageHeight * (MediaQuery.of(context).size.width / _imageWidth),
                      child: CustomPaint(
                        painter: ImagePainter(_image!, _points),
                      ),
                    ),
                  ),
                GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      double dx = details.localPosition.dx;
                      double dy = details.localPosition.dy;
                      _points.add(Offset(dx, dy));
                    });
                  },
                  onPanEnd: (details) {
                    _points.add(null);
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                  ),
                  onPressed: () async {
                    setState(() {
                      _points.clear(); // Efface les points
                    });
                    await _loadDefaultImage(); // Charge l'image par défaut
                  },
                  icon: Icon(Icons.delete, color: Colors.white),
                  label: Text('Effacer', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                  ),
                  onPressed: _saveDrawing,
                  icon: Icon(Icons.save, color: Colors.white),
                  label: Text('Enregistrer', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final List<Offset?> points;

  ImagePainter(this.image, this.points);

  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner l'image sur l'écran sans mise à l'échelle
    final Rect srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final Rect dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, srcRect, dstRect, Paint());

    // Dessiner les points de la signature
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        // Dessiner directement les lignes sans ajuster les coordonnées
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

