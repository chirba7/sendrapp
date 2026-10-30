import 'dart:async';
import 'dart:convert';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/sendra_theme.dart';
import 'package:walletium/utils/signaler_flow.dart';
import 'package:walletium/utils/strings.dart';

import 'pv_screen.dart';
import 'package:walletium/widgets/others/photo_reseau.dart';
import 'package:walletium/utils/photo_locale.dart';

/// Élément de la légende des dommages, posé sur le véhicule.
enum TypeDommage {
  bris('X', 'Bris', Color(0xFFD93025)),
  enfoncement('O', 'Enfoncement', Color(0xFFE37400)),
  rayure('V', 'Rayure', Color(0xFF1A73E8));

  const TypeDommage(this.symbole, this.libelle, this.couleur);
  final String symbole;
  final String libelle;
  final Color couleur;
}

/// Un repère posé sur le gabarit, en coordonnées relatives (0 à 1) : il reste
/// au bon endroit quelle que soit la taille de l'écran.
class RepereDommage {
  const RepereDommage(this.type, this.position);
  final TypeDommage type;
  final Offset position;
}

class _PhotoAgent {
  const _PhotoAgent({required this.id, required this.url});
  final int? id;
  final String url;
}

/// Constatation / dommages.
///
/// - Photos de l'agent : 4 au plus (aucune obligatoire), consultables en
///   plein écran et supprimables ;
/// - annotation : on choisit un élément de la légende (X bris, O enfoncement,
///   V rayure) puis on touche le véhicule pour le placer — plus de dessin à
///   main levée ;
/// - l'envoi pour approbation demande confirmation, puis ouvre le PV à signer.
class DommagesScreen extends StatefulWidget {
  final int signalementId;

  const DommagesScreen({Key? key, required this.signalementId})
      : super(key: key);

  @override
  State<DommagesScreen> createState() => _DommagesScreenState();
}

class _DommagesScreenState extends State<DommagesScreen> {
  static const photosMax = 4;

  final TextEditingController _missingPartsController = TextEditingController();
  final List<RepereDommage> _reperes = [];
  final List<_PhotoAgent> _photos = [];

  Map<String, dynamic>? signalementDetails;
  ui.Image? _image;
  String _vehicleKind = 'Voiture';
  TypeDommage? _typeChoisi = TypeDommage.bris;
  bool _isSaving = false;
  bool _uploadingPhoto = false;
  // Une image déjà enregistrée (composite chargé depuis l'API) est affichée
  // en entier, sans recadrage voiture/moto du gabarit.
  bool _isExistingImage = false;

  @override
  void initState() {
    super.initState();
    _loadVehicleKind().then((_) => _chargerDetails());
    _loadDefaultImage();
    _loadImageFromApi();
  }

  @override
  void dispose() {
    _missingPartsController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _entetes({bool json = true}) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${prefs.getString('token') ?? ''}',
    };
  }

  Future<void> _loadVehicleKind() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('vehicleKind_${widget.signalementId}');
    if (mounted && saved != null && saved.isNotEmpty) {
      setState(() => _vehicleKind = saved);
    }
  }

  Future<void> _chargerDetails() async {
    try {
      final response = await http.get(
        Uri.parse('${Strings.apiURI}listerSignalement/${widget.signalementId}'),
        headers: await _entetes(),
      );
      if (response.statusCode != 200) return;
      final dataList = jsonDecode(response.body)['data'] as List<dynamic>;
      if (dataList.isEmpty || !mounted) return;
      final details = Map<String, dynamic>.from(dataList.first as Map);
      setState(() {
        signalementDetails = details;
        final kind = details['vehicle_kind']?.toString();
        if (kind == 'Moto' || kind == 'Voiture' || kind == 'Camion') {
          _vehicleKind = kind!;
        } else if (details['type']?.toString().toLowerCase() == 'moto' ||
            details['categorie']?.toString().toUpperCase() == 'CYCL') {
          _vehicleKind = 'Moto';
        }
        if ((details['pieces_manquantes']?.toString() ?? '').isNotEmpty &&
            _missingPartsController.text.isEmpty) {
          _missingPartsController.text =
              details['pieces_manquantes'].toString();
        }
        _photos
          ..clear()
          ..addAll((details['photos_agent'] as List<dynamic>? ?? const [])
              .whereType<Map>()
              .map((p) => _PhotoAgent(
                    id: int.tryParse(p['id']?.toString() ?? ''),
                    url: p['url'].toString(),
                  )));
      });
    } catch (_) {
      // Le gabarit reste utilisable hors ligne.
    }
  }

  Future<void> _loadDefaultImage() async {
    final data = await rootBundle.load('assets/images/dommages.png');
    final image = await _decodeImage(data.buffer.asUint8List());
    if (!mounted) return;
    setState(() {
      _image = image;
      _isExistingImage = false;
    });
  }

  Future<void> _loadImageFromApi() async {
    try {
      final response = await http
          .get(
            Uri.parse('${Strings.apiURI}voirDommages/${widget.signalementId}'),
            headers: await _entetes(),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return;
      final json = jsonDecode(response.body);
      final url = json['dommages']?.toString() ?? '';
      // Sans image enregistrée, l'API renvoie le dossier seul.
      if (url.isEmpty || url.endsWith('/')) return;
      final bytes =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (bytes.statusCode != 200) return;
      final image = await _decodeImage(bytes.bodyBytes);
      if (!mounted || _reperes.isNotEmpty) return;
      setState(() {
        _image = image;
        _isExistingImage = true;
      });
    } catch (_) {
      // Le gabarit local est déjà affiché.
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  /// Le gabarit contient la voiture (62 % gauche) et la moto (38 % droite).
  /// Pas de gabarit camion : on annote sur la voiture.
  Rect _sourceRectFor(ui.Image image) {
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    if (_isExistingImage) return Rect.fromLTWH(0, 0, width, height);
    if (_vehicleKind == 'Moto') {
      return Rect.fromLTWH(width * .62, 0, width * .38, height);
    }
    return Rect.fromLTWH(0, 0, width * .62, height);
  }

  // ─────────────────────────── Photos de l'agent ─────────────────────────

  Future<void> _choisirSource() async {
    if (_photos.length >= photosMax || _uploadingPhoto) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Importer une photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source != null) await _ajouterPhoto(source);
  }

  Future<void> _ajouterPhoto(ImageSource source) async {
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
        requestFullMetadata: false,
      );
    } catch (_) {
      _snack('Impossible d’ouvrir l’appareil photo ou les images.');
      return;
    }
    if (picked == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final fichier = await SignalerFlow.optimiser(picked);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            '${Strings.apiURI}constatation/${widget.signalementId}/photos'),
      );
      request.headers.addAll(await _entetes(json: false));
      request.files
          .add(await multipartPhoto('photo', fichier));
      final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 40)),
      );
      final corps = jsonDecode(response.body);
      if (response.statusCode != 201) {
        throw Exception(corps is Map && corps['message'] != null
            ? corps['message']
            : 'Échec de l’envoi de la photo (${response.statusCode}).');
      }
      if (mounted) {
        setState(() => _photos.add(_PhotoAgent(
              id: int.tryParse(corps['id']?.toString() ?? ''),
              url: corps['url'].toString(),
            )));
      }
    } catch (error) {
      _snack(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _supprimerPhoto(_PhotoAgent photo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette photo ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: SendraTheme.statusSignale),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return;
    if (photo.id == null) {
      _snack(
          'Photo enregistrée par une ancienne version : actualisez la page.');
      return;
    }
    try {
      final response = await http.delete(
        Uri.parse(
            '${Strings.apiURI}constatation/${widget.signalementId}/photos/${photo.id}'),
        headers: await _entetes(),
      );
      if (response.statusCode != 200) {
        throw Exception('Suppression impossible (${response.statusCode}).');
      }
      if (mounted) setState(() => _photos.remove(photo));
    } catch (error) {
      _snack(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _voirPhoto(int index) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _VisionneusePhotos(
        urls: _photos.map((p) => p.url).toList(),
        depart: index,
      ),
    ));
  }

  // ─────────────────────────── Annotation ────────────────────────────────

  void _toucherGabarit(Offset local, Size taille) {
    // Un repère existant sous le doigt : on le retire.
    for (var i = _reperes.length - 1; i >= 0; i--) {
      final p = _reperes[i].position;
      final ecran = Offset(p.dx * taille.width, p.dy * taille.height);
      if ((ecran - local).distance < 22) {
        HapticFeedback.selectionClick();
        setState(() => _reperes.removeAt(i));
        return;
      }
    }
    final type = _typeChoisi;
    if (type == null) {
      _snack('Choisissez d’abord un élément de la légende.');
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _reperes.add(RepereDommage(
          type,
          Offset(local.dx / taille.width, local.dy / taille.height),
        )));
  }

  // ─────────────────────────── Envoi ─────────────────────────────────────

  Future<void> _confirmerEnvoi() async {
    if (_image == null || _isSaving) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.send_rounded, color: SendraTheme.green),
        title: const Text('Envoyer pour approbation ?'),
        content: Text(
          'Photos de l’agent : ${_photos.length}/$photosMax\n'
          'Repères de dommages : ${_reperes.length}\n\n'
          'Après l’envoi, la constatation ne pourra plus être modifiée et '
          'vous signerez le procès-verbal.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Valider l’envoi')),
        ],
      ),
    );
    if (ok == true) await _envoyer();
  }

  /// Image finale : gabarit recadré, agrandi, avec les repères et la légende.
  Future<Uint8List> _composer() async {
    final image = _image!;
    final source = _sourceRectFor(image);
    final facteur = (1200 / source.width).clamp(1.0, 4.0);
    final largeur = (source.width * facteur).roundToDouble();
    final hauteurImage = (source.height * facteur).roundToDouble();
    final bandeau = (largeur * .07).clamp(28.0, 70.0);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Rect.fromLTWH(0, 0, largeur, hauteurImage + bandeau),
        Paint()..color = Colors.white);
    canvas.drawImageRect(
        image,
        source,
        Rect.fromLTWH(0, 0, largeur, hauteurImage),
        Paint()..filterQuality = FilterQuality.high);
    final taille = Size(largeur, hauteurImage);
    for (final r in _reperes) {
      _RepereDessin.dessiner(canvas, r, taille, largeur * .05);
    }
    // Légende en bas de l'image, pour qu'elle se lise seule.
    final legende = TextPainter(
      text: TextSpan(children: [
        for (final t in TypeDommage.values)
          TextSpan(
            text: '${t.symbole} = ${t.libelle.toLowerCase()}   ',
            style: TextStyle(
                color: t.couleur,
                fontSize: bandeau * .45,
                fontWeight: FontWeight.w700),
          ),
      ]),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: largeur - 20);
    legende.paint(
        canvas, Offset(10, hauteurImage + (bandeau - legende.height) / 2));
    final rendu = await recorder
        .endRecording()
        .toImage(largeur.round(), (hauteurImage + bandeau).round());
    final octets = await rendu.toByteData(format: ui.ImageByteFormat.png);
    return octets!.buffer.asUint8List();
  }

  Future<void> _envoyer() async {
    setState(() => _isSaving = true);
    http.Response response;
    try {
      final png = await _composer();
      response = await http
          .put(
            Uri.parse(
                '${Strings.apiURI}enregistrerDommages/${widget.signalementId}'),
            headers: await _entetes(),
            body: jsonEncode({
              'signature': 'data:image/png;base64,${base64Encode(png)}',
              'pieces_manquantes': _missingPartsController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 40));
    } on TimeoutException {
      if (mounted) setState(() => _isSaving = false);
      _snack('Le serveur met du temps à répondre. Vérifiez votre connexion ; '
          'la constatation a peut-être déjà été enregistrée.');
      return;
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
      _snack('Impossible de joindre le serveur.');
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (response.statusCode == 200) {
      _snack('Constatation envoyée pour approbation.');
      // Fiche du signalement rechargée (récapitulatif verrouillé), puis le
      // PV à signer par-dessus : le retour ramène à la fiche, pas au
      // formulaire déjà transmis.
      final navigator = Navigator.of(context);
      navigator.pushNamedAndRemoveUntil(
        Routes.depositMoneyDetailsScreen,
        ModalRoute.withName(Routes.bottomNavigationScreen),
        arguments: widget.signalementId,
      );
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => PvScreen(signalementId: widget.signalementId),
      ));
    } else {
      String message =
          'Échec de l’envoi des dommages (${response.statusCode}).';
      try {
        final corps = jsonDecode(response.body);
        if (corps is Map && corps['message'] != null) {
          message = corps['message'].toString();
        }
      } catch (_) {}
      _snack(message);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ─────────────────────────── Interface ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Constatation / Dommages'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        backgroundColor: SendraTheme.surface,
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              if (signalementDetails != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Étape finale · Signalement n° ${signalementDetails!['signalementId']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: SendraTheme.muted),
                  ),
                ),
              _carte(
                titre: 'Photos de l’agent',
                complement: '${_photos.length}/$photosMax · facultatif',
                child: _grillePhotos(),
              ),
              const SizedBox(height: 14),
              _carte(
                titre: 'Annotation des dommages',
                complement: _vehicleKind == 'Camion'
                    ? 'Camion · gabarit voiture'
                    : _vehicleKind,
                child: _annotation(),
              ),
              const SizedBox(height: 14),
              _carte(
                titre: 'Pièces manquantes',
                child: TextField(
                  controller: _missingPartsController,
                  maxLines: 3,
                  minLines: 2,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    hintText: 'Pièces absentes du véhicule ou de la moto',
                  ),
                ),
              ),
            ],
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
            child: SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _isSaving || _image == null ? null : _confirmerEnvoi,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 19),
                label: Text(_isSaving ? 'Envoi…' : 'Envoyer pour approbation'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _carte(
      {required String titre, String? complement, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SendraTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(titre,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15.5)),
              if (complement != null)
                Text(complement,
                    style: const TextStyle(
                        color: SendraTheme.muted, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// Grille responsive : 2 colonnes sur petit écran (Fold fermé), 4 sinon.
  Widget _grillePhotos() {
    return LayoutBuilder(builder: (context, c) {
      final colonnes = c.maxWidth < 340 ? 2 : 4;
      final tuiles = <Widget>[
        for (var i = 0; i < _photos.length; i++)
          _TuilePhoto(
            url: _photos[i].url,
            onVoir: () => _voirPhoto(i),
            onSupprimer: () => _supprimerPhoto(_photos[i]),
          ),
        if (_photos.length < photosMax)
          _TuileAjout(chargement: _uploadingPhoto, onTap: _choisirSource),
      ];
      return GridView.count(
        crossAxisCount: colonnes,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: tuiles,
      );
    });
  }

  Widget _annotation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_isExistingImage && _vehicleKind != 'Camion')
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                  value: 'Voiture',
                  icon: Icon(Icons.directions_car_rounded, size: 18),
                  label: Text('Voiture')),
              ButtonSegment(
                  value: 'Moto',
                  icon: Icon(Icons.two_wheeler_rounded, size: 18),
                  label: Text('Moto')),
            ],
            selected: {_vehicleKind},
            onSelectionChanged: _reperes.isNotEmpty
                ? null
                : (v) => setState(() => _vehicleKind = v.first),
          ),
        const SizedBox(height: 12),
        const Text(
          'Touchez un élément de la légende, puis touchez le véhicule pour le placer. '
          'Touchez un repère pour le retirer.',
          style:
              TextStyle(color: SendraTheme.muted, fontSize: 13, height: 1.35),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in TypeDommage.values)
              ChoiceChip(
                showCheckmark: false,
                selected: _typeChoisi == t,
                onSelected: (_) => setState(() => _typeChoisi = t),
                selectedColor: t.couleur.withValues(alpha: .14),
                side: BorderSide(
                    color: _typeChoisi == t ? t.couleur : SendraTheme.border,
                    width: _typeChoisi == t ? 1.8 : 1),
                avatar: CircleAvatar(
                  radius: 12,
                  backgroundColor: t.couleur,
                  child: Text(t.symbole,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12)),
                ),
                label: Text(t.libelle,
                    style: TextStyle(
                        fontWeight: _typeChoisi == t
                            ? FontWeight.w800
                            : FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_image == null)
          const SizedBox(
              height: 200, child: Center(child: CircularProgressIndicator()))
        else
          LayoutBuilder(builder: (context, constraints) {
            final source = _sourceRectFor(_image!);
            final hauteur =
                (constraints.maxWidth / (source.width / source.height))
                    .clamp(150.0, 420.0);
            final taille = Size(constraints.maxWidth, hauteur);
            return Container(
              height: hauteur,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _typeChoisi?.couleur ?? SendraTheme.border,
                    width: 1.6),
              ),
              clipBehavior: Clip.antiAlias,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _toucherGabarit(d.localPosition, taille),
                child: CustomPaint(
                  size: taille,
                  painter: _GabaritPainter(_image!, source, _reperes),
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        // Sur un écran étroit, les deux actions passent en icônes seules
        // pour ne jamais déborder de la carte.
        LayoutBuilder(builder: (context, c) {
          final compact = c.maxWidth < 300;
          void annuler() => setState(() => _reperes.removeLast());
          void effacer() => setState(() => _reperes.clear());
          final vide = _reperes.isEmpty;
          return Row(
            children: [
              Expanded(
                child: Text(
                  vide
                      ? 'Aucun repère'
                      : '${_reperes.length} repère${_reperes.length > 1 ? 's' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: SendraTheme.muted),
                ),
              ),
              if (compact) ...[
                IconButton(
                  tooltip: 'Annuler',
                  onPressed: vide ? null : annuler,
                  icon: const Icon(Icons.undo_rounded),
                ),
                IconButton(
                  tooltip: 'Effacer',
                  color: SendraTheme.statusSignale,
                  onPressed: vide ? null : effacer,
                  icon: const Icon(Icons.delete_outline),
                ),
              ] else ...[
                TextButton.icon(
                  onPressed: vide ? null : annuler,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text('Annuler'),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                      foregroundColor: SendraTheme.statusSignale),
                  onPressed: vide ? null : effacer,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Effacer'),
                ),
              ],
            ],
          );
        }),
      ],
    );
  }
}

/// Dessin d'un repère : symbole de la légende dans une pastille colorée.
class _RepereDessin {
  static void dessiner(
      Canvas canvas, RepereDommage r, Size taille, double rayon) {
    final centre =
        Offset(r.position.dx * taille.width, r.position.dy * taille.height);
    canvas.drawCircle(centre, rayon + 2, Paint()..color = Colors.white);
    canvas.drawCircle(centre, rayon, Paint()..color = r.type.couleur);
    final texte = TextPainter(
      text: TextSpan(
        text: r.type.symbole,
        style: TextStyle(
          color: Colors.white,
          fontSize: rayon * 1.25,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    texte.paint(canvas, centre - Offset(texte.width / 2, texte.height / 2));
  }
}

class _GabaritPainter extends CustomPainter {
  _GabaritPainter(this.image, this.source, this.reperes)
      : _nombre = reperes.length;
  final ui.Image image;
  final Rect source;
  final List<RepereDommage> reperes;
  // La liste des repères est modifiée en place : on compare leur nombre
  // pour ne redessiner que si quelque chose a changé.
  final int _nombre;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(image, source, Offset.zero & size,
        Paint()..filterQuality = FilterQuality.medium);
    final rayon = (size.width * .04).clamp(11.0, 18.0);
    for (final r in reperes) {
      _RepereDessin.dessiner(canvas, r, size, rayon);
    }
  }

  @override
  bool shouldRepaint(covariant _GabaritPainter old) =>
      old.image != image || old.source != source || old._nombre != _nombre;
}

class _TuilePhoto extends StatelessWidget {
  const _TuilePhoto({
    required this.url,
    required this.onVoir,
    required this.onSupprimer,
  });

  final String url;
  final VoidCallback onVoir;
  final VoidCallback onSupprimer;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Material(
            color: const Color(0xFFEAF1ED),
            child: InkWell(
              onTap: onVoir,
              child: PhotoReseau(
                url,
                largeur: 120,
                erreur: const Icon(Icons.broken_image_outlined,
                    color: SendraTheme.muted),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onSupprimer,
                child: const Padding(
                  padding: EdgeInsets.all(5),
                  child:
                      Icon(Icons.close_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 6,
            bottom: 6,
            child: Icon(Icons.zoom_in_rounded,
                color: Colors.white,
                size: 18,
                shadows: [Shadow(blurRadius: 4)]),
          ),
        ],
      ),
    );
  }
}

class _TuileAjout extends StatelessWidget {
  const _TuileAjout({required this.chargement, required this.onTap});
  final bool chargement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SendraTheme.greenSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: SendraTheme.green, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: chargement ? null : onTap,
        child: Center(
          child: chargement
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.4))
              : const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo_rounded,
                            color: SendraTheme.green, size: 26),
                        SizedBox(height: 4),
                        Text('Ajouter',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: SendraTheme.forest)),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Photos de l'agent en plein écran, zoomables, avec défilement.
class _VisionneusePhotos extends StatefulWidget {
  const _VisionneusePhotos({required this.urls, required this.depart});
  final List<String> urls;
  final int depart;

  @override
  State<_VisionneusePhotos> createState() => _VisionneusePhotosState();
}

class _VisionneusePhotosState extends State<_VisionneusePhotos> {
  late final PageController _page = PageController(initialPage: widget.depart);
  late int _index = widget.depart;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Photo ${_index + 1}/${widget.urls.length}'),
      ),
      body: PageView.builder(
        controller: _page,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: PhotoReseau(
              widget.urls[i],
              fit: BoxFit.contain,
              attente: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ),
    );
  }
}
