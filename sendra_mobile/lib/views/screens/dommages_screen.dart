import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/utils/sendra_theme.dart';

class DommagesScreen extends StatefulWidget {
  final int signalementId;

  const DommagesScreen({Key? key, required this.signalementId})
      : super(key: key);

  @override
  _DommagesScreenState createState() => _DommagesScreenState();
}

class _DommagesScreenState extends State<DommagesScreen> {
  final List<Offset?> _points = [];
  Map<String, dynamic>? signalementDetails;
  ui.Image? _image;
  late double _imageWidth;
  late double _imageHeight;
  String _vehicleKind = 'Voiture';
  bool _drawingEnabled = false;
  bool _isSaving = false;
  Size _canvasSize = Size.zero;
  // Correction : quand un signalement a déjà des dommages enregistrés,
  // _loadImageFromApi() charge cette image existante (déjà un composite
  // recadré, plus le gabarit à deux panneaux voiture+moto). Le sélecteur
  // de type continuait pourtant à recadrer cette image comme si c'était le
  // gabarit d'origine, produisant des morceaux de voiture absurdes en mode
  // "Moto". _isExistingImage désactive ce recadrage sur une image existante.
  bool _isExistingImage = false;

  @override
  void initState() {
    super.initState();
    print('DommagesScreen initialized');

    fetchSignalementDetails(widget.signalementId);
    _loadImageFromApi(widget.signalementId); // Charge l'image depuis l'API
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
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
      _isExistingImage = false;
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
        if (jsonResponse.containsKey('dommages') &&
            jsonResponse['dommages'] != null) {
          final imageUrl = jsonResponse['dommages'];
          final imageBytes = await _fetchImageFromUrl(imageUrl);
          final image = await _decodeImage(imageBytes);

          setState(() {
            _image = image;
            _imageWidth = image.width.toDouble();
            _imageHeight = image.height.toDouble();
            _isExistingImage = true;
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
      throw Exception(
          'Erreur lors du téléchargement de l\'image depuis $imageUrl');
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
    if (_image == null || _canvasSize == Size.zero || _isSaving) return;
    setState(() => _isSaving = true);
    print('Enregistrement du dessin...');

    final sourceRect = _sourceRectFor(_image!);
    final outputWidth = sourceRect.width.round();
    final outputHeight = sourceRect.height.round();
    final scaleX = outputWidth / _canvasSize.width;
    final scaleY = outputHeight / _canvasSize.height;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
    );

    // Dessiner l'image
    final dstRect = Rect.fromLTWH(
      0,
      0,
      outputWidth.toDouble(),
      outputHeight.toDouble(),
    );
    canvas.drawImageRect(_image!, sourceRect, dstRect, Paint());

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
    final img = await picture.toImage(outputWidth, outputHeight);
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

    http.Response response;
    try {
      response = await http
          .put(Uri.parse(url), headers: headers, body: body)
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Le serveur met du temps à répondre. Vérifiez votre connexion puis réessayez ; les dommages ont peut-être déjà été enregistrés.',
            ),
          ),
        );
      }
      return;
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de joindre le serveur.')),
        );
      }
      return;
    }

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      print('Réponse après enregistrement: ${jsonResponse.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(jsonResponse['message']),
        duration: Duration(seconds: 1),
      ));

      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          // Dommages peut être ouvert depuis la page Infraction. Un simple
          // pop ramenait donc l'agent vers le formulaire précédent. La
          // constatation est recréée ici afin de recharger immédiatement le
          // statut de la demande d'approbation.
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.depositMoneyDetailsScreen,
            ModalRoute.withName(Routes.bottomNavigationScreen),
            arguments: widget.signalementId,
          );
        }
      });
    } else {
      print('Erreur lors de l\'enregistrement du dessin');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'enregistrement des dommages')));
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Rect _sourceRectFor(ui.Image image) {
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    // Une image déjà enregistrée (composite chargé depuis l'API) est un
    // panneau unique déjà finalisé, pas le gabarit à deux panneaux — pas de
    // recadrage voiture/moto dessus, on l'affiche en entier.
    if (_isExistingImage) {
      return Rect.fromLTWH(0, 0, width, height);
    }
    if (_vehicleKind == 'Moto') {
      return Rect.fromLTWH(width * .62, 0, width * .38, height);
    }
    return Rect.fromLTWH(0, 0, width * .62, height);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Constatation / Dommages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: SendraTheme.surface,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              if (signalementDetails != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SendraTheme.border),
                  ),
                  child: Text(
                    'Étape finale · Signalement n° ${signalementDetails!['signalementId']}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Type de véhicule',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _vehicleChoice('Voiture', Icons.directions_car_rounded),
                        const SizedBox(width: 10),
                        _vehicleChoice('Moto', Icons.two_wheeler_rounded),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Touchez « Annoter », puis dessinez sur les zones endommagées.',
                            style: TextStyle(
                                color: SendraTheme.muted, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected: _drawingEnabled,
                          onSelected: (value) =>
                              setState(() => _drawingEnabled = value),
                          avatar: Icon(
                              _drawingEnabled
                                  ? Icons.edit
                                  : Icons.pan_tool_outlined,
                              size: 17),
                          label: Text(
                              _drawingEnabled ? 'Dessin actif' : 'Annoter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_image == null)
                      const SizedBox(
                          height: 220,
                          child: Center(child: CircularProgressIndicator()))
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final source = _sourceRectFor(_image!);
                          final height = (constraints.maxWidth /
                                  (source.width / source.height))
                              .clamp(190.0, 360.0);
                          _canvasSize = Size(constraints.maxWidth, height);
                          return Container(
                            width: constraints.maxWidth,
                            height: height,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _drawingEnabled
                                    ? SendraTheme.green
                                    : SendraTheme.border,
                                width: _drawingEnabled ? 2 : 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: _drawingEnabled
                                  ? (details) => setState(
                                      () => _points.add(details.localPosition))
                                  : null,
                              onPanEnd: _drawingEnabled
                                  ? (_) => _points.add(null)
                                  : null,
                              child: CustomPaint(
                                painter: ImagePainter(_image!, _points, source),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: SendraTheme.border)),
                ),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: () async {
                        setState(() {
                          _points.clear(); // Efface les points
                        });
                        await _loadDefaultImage();
                      },
                      icon: const Icon(Icons.delete_outline, size: 19),
                      label: const Text('Effacer'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SendraTheme.green,
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: _isSaving ? null : _saveDrawing,
                        icon: _isSaving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded, size: 19),
                        label: Text(
                            _isSaving ? 'Envoi…' : 'Envoyer pour approbation'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vehicleChoice(String label, IconData icon) {
    final selected = _vehicleKind == label;
    return Expanded(
      child: ChoiceChip(
        showCheckmark: false,
        avatar: Icon(icon,
            color: selected ? SendraTheme.forest : SendraTheme.muted),
        label: SizedBox(
            width: double.infinity,
            child: Text(label, textAlign: TextAlign.center)),
        selected: selected,
        onSelected: (_) async {
          // Changer de type sur une image déjà enregistrée n'a pas de sens
          // (ce n'est plus le gabarit à deux panneaux) — on repart du
          // gabarit vierge pour une nouvelle annotation.
          if (_isExistingImage) {
            await _loadDefaultImage();
          }
          setState(() {
            _vehicleKind = label;
            _points.clear();
          });
        },
        selectedColor: const Color(0xFFE1F3E8),
        side: BorderSide(
            color: selected ? SendraTheme.green : SendraTheme.border),
      ),
    );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final List<Offset?> points;
  final Rect sourceRect;

  ImagePainter(this.image, this.points, this.sourceRect);

  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner l'image sur l'écran sans mise à l'échelle
    final Rect dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, sourceRect, dstRect, Paint());

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
