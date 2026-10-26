import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/sendra_theme.dart';
import '../../utils/strings.dart';

/// Procès-verbal de constatation : signature par l'agent, puis consultation
/// et téléchargement du PDF généré par le serveur.
///
/// Ouvert automatiquement après l'envoi pour approbation, et depuis la fiche
/// du signalement (« Signer le PV » / « Consulter / télécharger le PV »).
class PvScreen extends StatefulWidget {
  const PvScreen({super.key, required this.signalementId});

  final int signalementId;

  @override
  State<PvScreen> createState() => _PvScreenState();
}

class _PvScreenState extends State<PvScreen> {
  Map<String, dynamic>? _signalement;
  Map<String, dynamic>? _pv;
  bool _chargement = true;
  bool _envoi = false;
  String? _erreur;

  final List<List<Offset>> _traits = [];
  Size _taillePad = Size.zero;

  bool get _signe => _pv?['pv_signe'] == true || _signalement?['pv_signe'] == true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<Map<String, String>> _entetes() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'Authorization': 'Bearer ${prefs.getString('token') ?? ''}',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final entetes = await _entetes();
      final reponse = await http
          .get(
            Uri.parse('${Strings.apiURI}listerSignalement/${widget.signalementId}'),
            headers: entetes,
          )
          .timeout(const Duration(seconds: 20));
      if (reponse.statusCode != 200) throw Exception();
      final data = (jsonDecode(reponse.body)['data'] as List).first;
      _signalement = Map<String, dynamic>.from(data as Map);
      if (_signalement!['pv_signe'] == true) {
        final lien = await http.get(
          Uri.parse('${Strings.apiURI}signalements/${widget.signalementId}/pv'),
          headers: entetes,
        );
        if (lien.statusCode == 200) {
          _pv = Map<String, dynamic>.from(jsonDecode(lien.body) as Map);
        }
      }
    } catch (_) {
      _erreur = 'Impossible de charger le procès-verbal. Vérifiez la connexion.';
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<String?> _signatureEnPng() async {
    if (_traits.every((t) => t.length < 2) || _taillePad == Size.zero) {
      return null;
    }
    const echelle = 2.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(echelle);
    _SignaturePainter(_traits).paint(canvas, _taillePad);
    final image = await recorder.endRecording().toImage(
          (_taillePad.width * echelle).round(),
          (_taillePad.height * echelle).round(),
        );
    final octets = await image.toByteData(format: ui.ImageByteFormat.png);
    if (octets == null) return null;
    return 'data:image/png;base64,${base64Encode(octets.buffer.asUint8List())}';
  }

  Future<void> _signer() async {
    final signature = await _signatureEnPng();
    if (signature == null) {
      _message('Signez dans le cadre avant de valider.');
      return;
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Signer le procès-verbal ?'),
        content: const Text(
            'Votre signature sera apposée sur le PV de constatation. Elle ne pourra plus être modifiée.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Signer')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _envoi = true);
    try {
      final reponse = await http
          .post(
            Uri.parse(
                '${Strings.apiURI}signalements/${widget.signalementId}/pv/signer'),
            headers: await _entetes(),
            body: jsonEncode({'signature': signature}),
          )
          .timeout(const Duration(seconds: 45));
      final corps = jsonDecode(reponse.body);
      if (reponse.statusCode == 200 || reponse.statusCode == 409) {
        setState(() => _pv = Map<String, dynamic>.from(corps as Map));
        _message(reponse.statusCode == 200
            ? 'Procès-verbal signé.'
            : 'Le procès-verbal était déjà signé.');
        await _charger();
      } else {
        _message(corps is Map && corps['message'] != null
            ? corps['message'].toString()
            : 'Signature impossible (${reponse.statusCode}).');
      }
    } catch (_) {
      _message('Impossible de joindre le serveur. Réessayez.');
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _ouvrir({required bool telecharger}) async {
    // Les liens sont signés et valables 30 minutes : on en redemande un frais.
    try {
      final reponse = await http.get(
        Uri.parse('${Strings.apiURI}signalements/${widget.signalementId}/pv'),
        headers: await _entetes(),
      );
      if (reponse.statusCode == 200) {
        _pv = Map<String, dynamic>.from(jsonDecode(reponse.body) as Map);
      }
    } catch (_) {}
    final url = _pv?[telecharger ? 'pv_url_telechargement' : 'pv_url']?.toString();
    if (url == null || url.isEmpty) {
      _message('Lien du PV indisponible.');
      return;
    }
    final ouvert = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ouvert) _message('Aucune application pour ouvrir le PDF.');
  }

  void _message(String texte) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SendraTheme.surface,
      appBar: AppBar(title: const Text('Procès-verbal')),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_erreur!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(
                            onPressed: _charger, child: const Text('Réessayer')),
                      ],
                    ),
                  ),
                )
              : _signe
                  ? _vueSigne()
                  : _vueSignature(),
    );
  }

  Widget _recapitulatif() {
    final d = _signalement ?? const {};
    final lignes = <String, String>{
      'Signalement': 'n° ${d['signalementId'] ?? widget.signalementId}',
      'Véhicule': [
        d['vehicle_kind'],
        d['marque'],
        d['model'],
      ].where((v) => v != null && v.toString().isNotEmpty).join(' · '),
      'Immatriculation': d['numero_vehicule']?.toString() ?? '',
      'Adresse': d['adresse_precise']?.toString() ?? d['commune']?.toString() ?? '',
      'Infraction': d['motif_infraction']?.toString() ?? '',
      'Pièces manquantes': d['pieces_manquantes']?.toString() ?? '',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SendraTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PROCÈS-VERBAL DE CONSTATATION',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: SendraTheme.forest,
                  letterSpacing: .3)),
          const SizedBox(height: 10),
          for (final e in lignes.entries)
            if (e.value.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(e.key,
                          style: const TextStyle(
                              color: SendraTheme.muted, fontSize: 13.5)),
                    ),
                    Expanded(
                      child: Text(e.value,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13.5)),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _vueSignature() {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          // Le récapitulatif défile ; le cadre de signature reste fixe en bas
          // pour que le tracé ne fasse pas défiler la page.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              children: [
                const Text(
                  'La constatation a été envoyée pour approbation. Signez le procès-verbal pour le générer.',
                  style: TextStyle(color: SendraTheme.muted, height: 1.4),
                ),
                const SizedBox(height: 12),
                _recapitulatif(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: SendraTheme.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Signature de l’agent',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    TextButton.icon(
                      onPressed: _traits.isEmpty
                          ? null
                          : () => setState(() => _traits.clear()),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Effacer'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 170,
                  child: LayoutBuilder(builder: (context, c) {
                    _taillePad = Size(c.maxWidth, c.maxHeight);
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFCFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: SendraTheme.border, width: 1.4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (d) => setState(
                              () => _traits.add([d.localPosition])),
                          onPanUpdate: (d) => setState(
                              () => _traits.last.add(d.localPosition)),
                          child: CustomPaint(
                            painter: _SignaturePainter(_traits),
                            child: _traits.isEmpty
                                ? const Center(
                                    child: Text('Signez ici',
                                        style: TextStyle(
                                            color: SendraTheme.muted)),
                                  )
                                : const SizedBox.expand(),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _envoi ? null : _signer,
                    icon: _envoi
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4, color: Colors.white))
                        : const Icon(Icons.draw_rounded),
                    label: Text(_envoi ? 'Génération du PV…' : 'Signer le procès-verbal'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Signature de l'agent qui a fait la constatation, telle qu'apposée sur
  /// le PV.
  Widget _signatureAgent() {
    final octets = _decoderDataUri(_pv?['pv_signature']?.toString());
    final agent = _pv?['pv_agent']?.toString() ??
        _signalement?['pris_en_charge_par']?.toString();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SendraTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Signature de l’agent',
              style: TextStyle(fontWeight: FontWeight.w800, color: SendraTheme.forest)),
          if (agent != null && agent.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(agent, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 10),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFAFCFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SendraTheme.border),
            ),
            padding: const EdgeInsets.all(8),
            child: octets == null
                ? const Center(
                    child: Text('Signature indisponible',
                        style: TextStyle(color: SendraTheme.muted)))
                : Image.memory(octets, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }

  Widget _vueSigne() {
    final numero = _pv?['pv_numero'] ?? _signalement?['pv_numero'];
    final date = _pv?['pv_signe_at'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5ED),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFB7DEC4)),
          ),
          child: Column(
            children: [
              const Icon(Icons.verified_rounded,
                  size: 52, color: SendraTheme.green),
              const SizedBox(height: 10),
              const Text('Procès-verbal signé',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              if (numero != null) ...[
                const SizedBox(height: 4),
                Text('$numero',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: SendraTheme.forest)),
              ],
              if (date != null) ...[
                const SizedBox(height: 2),
                Text('Signé le $date',
                    style: const TextStyle(color: SendraTheme.muted)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _recapitulatif(),
        const SizedBox(height: 16),
        _signatureAgent(),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: () => _ouvrir(telecharger: false),
            icon: const Icon(Icons.visibility_rounded),
            label: const Text('Consulter le PV'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => _ouvrir(telecharger: true),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Télécharger le PDF'),
          ),
        ),
      ],
    );
  }
}

Uint8List? _decoderDataUri(String? dataUri) {
  if (dataUri == null || !dataUri.contains(',')) return null;
  try {
    return base64Decode(dataUri.substring(dataUri.indexOf(',') + 1));
  } catch (_) {
    return null;
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.traits);
  final List<List<Offset>> traits;

  @override
  void paint(Canvas canvas, Size size) {
    final pinceau = Paint()
      ..color = const Color(0xFF0B1F44)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final trait in traits) {
      if (trait.length == 1) {
        canvas.drawCircle(trait.first, 1.4, pinceau..style = PaintingStyle.fill);
        pinceau.style = PaintingStyle.stroke;
        continue;
      }
      final chemin = Path()..moveTo(trait.first.dx, trait.first.dy);
      for (final p in trait.skip(1)) {
        chemin.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(chemin, pinceau);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
