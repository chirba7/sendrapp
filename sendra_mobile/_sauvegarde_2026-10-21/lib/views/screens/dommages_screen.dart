import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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
  final TextEditingController _missingPartsController = TextEditingController();
  Map<String, dynamic>? signalementDetails;
  ui.Image? _image;
  late double _imageWidth;
  late double _imageHeight;
  String _vehicleKind = 'Voiture';
  bool _drawingEnabled = false;
  bool _isSaving = false;
  bool _uploadingPhoto = false;
  final List<String> _agentPhotoUrls = [];
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

    _loadVehicleKind()
        .then((_) => fetchSignalementDetails(widget.signalementId));
    // Correction perf : l'écran attendait deux appels réseau séquentiels
    // (voirDommages puis le téléchargement de l'image) avant d'afficher
    // quoi que ce soit — y compris dans le cas le plus fréquent où aucun
    // dommage n'existe encore, où ça finissait par retomber sur le gabarit
    // local de toute façon après avoir attendu pour rien. Le gabarit
    // s'affiche maintenant tout de suite (chargement local, instantané) ;
    // la vérification d'une éventuelle image déjà enregistrée se fait en
    // arrière-plan et ne remplace l'affichage que si l'utilisateur n'a pas
    // déjà commencé à dessiner dessus.
    _loadDefaultImage();
    _loadImageFromApi(widget.signalementId);
  }

  Future<void> _loadVehicleKind() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('vehicleKind_${widget.signalementId}');
    if (mounted && (saved == 'Moto' || saved == 'Voiture')) {
      setState(() => _vehicleKind = saved!);
    }
  }

  @override
  void dispose() {
    _missingPartsController.dispose();
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
            final details = dataList[0] as Map<String, dynamic>;
            final kind = details['vehicle_kind']?.toString();
            if (kind == 'Moto' || kind == 'Voiture') {
              _vehicleKind = kind!;
            } else if (details['type']?.toString().toLowerCase() == 'moto' ||
                details['categorie']?.toString().toUpperCase() == 'CYCL') {
              _vehicleKind = 'Moto';
            }
            _agentPhotoUrls
              ..clear()
              ..addAll(
                  (dataList[0]['photos_agent'] as List<dynamic>? ?? const [])
                      .map((photo) => photo['url'].toString()));
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
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('Réponse d\'image obtenue: ${jsonResponse.toString()}');

        // Vérifiez si la clé "dommages" est présente
        if (jsonResponse.containsKey('dommages') &&
            jsonResponse['dommages'] != null) {
          final imageUrl = jsonResponse['dommages'];
          final imageBytes = await _fetchImageFromUrl(imageUrl);
          final image = await _decodeImage(imageBytes);

          // Le gabarit local s'affiche déjà pendant ce chargement en
          // arrière-plan — ne pas écraser un dessin déjà en cours.
          if (!mounted || _points.isNotEmpty) return;

          setState(() {
            _image = image;
            _imageWidth = image.width.toDouble();
            _imageHeight = image.height.toDouble();
            _isExistingImage = true;
          });
        }
        // Pas de clé "dommages" : rien à faire, le gabarit local déjà
        // affiché reste en place (cas normal, aucun dommage enregistré).
      }
    } catch (e) {
      // Le gabarit local est déjà affiché depuis initState — un échec ici
      // (réseau lent, timeout) n'empêche pas l'utilisateur d'annoter.
      print('Erreur lors du chargement de l\'image existante: $e');
    }
  }

// Fonction utilitaire pour récupérer l'image depuis une URL
  Future<Uint8List> _fetchImageFromUrl(String imageUrl) async {
    final response = await http
        .get(Uri.parse(imageUrl))
        .timeout(const Duration(seconds: 15));
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
      'pieces_manquantes': _missingPartsController.text.trim(),
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
      if (!mounted) return;
      setState(() => _isSaving = false);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('Signalement transmis'),
              content: const Text(
                'La constatation a été envoyée pour approbation. Elle est maintenant consultable en récapitulatif et ne peut plus être modifiée par l’agent.',
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      Routes.depositMoneyDetailsScreen,
                      ModalRoute.withName(Routes.bottomNavigationScreen),
                      arguments: widget.signalementId,
                    );
                  },
                  child: const Text('Quitter'),
                ),
              ],
            )),
      );
    } else {
      print('Erreur lors de l\'enregistrement du dessin');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'enregistrement des dommages')));
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _addAgentPhoto(ImageSource source) async {
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 65,
        maxWidth: 1280,
        maxHeight: 1280,
        requestFullMetadata: false,
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Impossible d’ouvrir l’appareil photo ou les images.')),
        );
      return;
    }
    if (picked == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final request = http.MultipartRequest(
          'POST',
          Uri.parse(
            '${Strings.apiURI}constatation/${widget.signalementId}/photos',
          ));
      request.headers['Authorization'] = 'Bearer $token';
      request.files
          .add(await http.MultipartFile.fromPath('photo', picked.path));
      final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 30)),
      );
      if (response.statusCode == 404) {
        throw Exception(
            'L’envoi de photos n’est pas encore disponible sur le serveur.');
      }
      if (response.statusCode != 201) {
        throw Exception(
            'Échec de l’envoi de la photo (${response.statusCode}).');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (mounted) setState(() => _agentPhotoUrls.add(data['url'] as String));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
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
          physics:
              _drawingEnabled ? const NeverScrollableScrollPhysics() : null,
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
                    Chip(
                      avatar: Icon(_vehicleKind == 'Moto'
                          ? Icons.two_wheeler_rounded
                          : Icons.directions_car_rounded),
                      label: Text('Véhicule à annoter : $_vehicleKind'),
                    ),
                    const SizedBox(height: 12),
                    const Text('Photos de l’agent',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ajouter une photo de constatation'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _uploadingPhoto
                                      ? null
                                      : () =>
                                          _addAgentPhoto(ImageSource.camera),
                                  icon: const Icon(Icons.photo_camera_outlined),
                                  label: const Text('Prendre une photo'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _uploadingPhoto
                                      ? null
                                      : () =>
                                          _addAgentPhoto(ImageSource.gallery),
                                  icon:
                                      const Icon(Icons.photo_library_outlined),
                                  label: const Text('Importer une photo'),
                                ),
                              ],
                            ),
                            if (_uploadingPhoto)
                              const LinearProgressIndicator(),
                          ],
                        ),
                      ),
                    ),
                    if (_agentPhotoUrls.isNotEmpty)
                      Wrap(
                          spacing: 8,
                          children: _agentPhotoUrls
                              .map(
                                (url) => Image.network(url,
                                    width: 72, height: 72, fit: BoxFit.cover),
                              )
                              .toList()),
                    const SizedBox(height: 12),
                    const Text(
                        'Légende : X = bris  ·  O = enfoncement  ·  V = rayure',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _missingPartsController,
                      maxLines: 2,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        labelText: 'Pièces manquantes',
                        hintText:
                            'Décrivez les pièces absentes du véhicule ou de la moto',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _drawingEnabled
                                ? 'Dessin actif : tracez sur le véhicule. Désactivez pour faire défiler la page.'
                                : 'Touchez « Annoter », puis tracez sur le véhicule.',
                            style: const TextStyle(
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
                              onPanStart: _drawingEnabled
                                  ? (details) => setState(
                                      () => _points.add(details.localPosition))
                                  : null,
                              onPanUpdate: _drawingEnabled
                                  ? (details) => setState(
                                      () => _points.add(details.localPosition))
                                  : null,
                              onPanEnd: _drawingEnabled
                                  ? (_) => setState(() => _points.add(null))
                                  : null,
                              onPanCancel: _drawingEnabled
                                  ? () => setState(() => _points.add(null))
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
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
                  label:
                      Text(_isSaving ? 'Envoi…' : 'Envoyer pour approbation'),
                ),
              ),
            ],
          ),
        ),
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
