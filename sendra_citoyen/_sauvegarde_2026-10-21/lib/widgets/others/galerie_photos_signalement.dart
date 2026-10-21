import 'package:flutter/material.dart';
import 'package:walletium/services/offline_signalement_service.dart';

/// Une photo affichable d'un signalement.
class PhotoAffichee {
  final String url;
  final String? libelle;

  const PhotoAffichee(this.url, this.libelle);
}

/// Photos d'un signalement tel que renvoyé par l'API (SignalementRessource) :
/// `images` (toutes les photos, avec leur angle) si présent, sinon repli sur
/// `image_url` (anciens signalements / ancienne API).
List<PhotoAffichee> photosDuSignalement(Map<String, dynamic> data) {
  final images = data['images'];
  if (images is List && images.isNotEmpty) {
    return images
        .whereType<Map>()
        .map((e) => PhotoAffichee(
              e['url']?.toString() ?? '',
              anglesSignalement[e['position']?.toString()],
            ))
        .where((p) => p.url.isNotEmpty)
        .toList();
  }

  final url = data['image_url']?.toString() ?? '';
  return url.isEmpty || url == 'null' ? [] : [PhotoAffichee(url, null)];
}

/// Photo unique ou carrousel défilant (avec indicateur) ; un appui ouvre la
/// photo en plein écran, zoomable, en gardant le défilement entre photos.
class GaleriePhotosSignalement extends StatefulWidget {
  final Map<String, dynamic> signalementData;
  final double hauteur;

  const GaleriePhotosSignalement({
    super.key,
    required this.signalementData,
    this.hauteur = 250,
  });

  @override
  State<GaleriePhotosSignalement> createState() =>
      _GaleriePhotosSignalementState();
}

class _GaleriePhotosSignalementState extends State<GaleriePhotosSignalement> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final photos = photosDuSignalement(widget.signalementData);

    if (photos.isEmpty) {
      return Container(
        height: widget.hauteur,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF1ED),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Icon(Icons.image_not_supported_outlined)),
      );
    }

    return Column(
      children: [
        Text(
          photos.length > 1
              ? 'Faites défiler les ${photos.length} photos · appuyez pour agrandir'
              : 'Appuyez pour agrandir l\'image',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          height: widget.hauteur,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  itemCount: photos.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => _pleinEcran(context, photos, i),
                    child: _image(photos[i].url, BoxFit.cover, cacheWidth: 1000),
                  ),
                ),
                if (photos[_index].libelle != null)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: _pastille(photos[_index].libelle!),
                  ),
                if (photos.length > 1)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: _pastille('${_index + 1}/${photos.length}'),
                  ),
              ],
            ),
          ),
        ),
        if (photos.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              photos.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _index ? Colors.green[700] : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _pastille(String texte) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texte,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  void _pleinEcran(BuildContext context, List<PhotoAffichee> photos, int depart) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotosPleinEcran(photos: photos, depart: depart),
      ),
    );
  }
}

class _PhotosPleinEcran extends StatefulWidget {
  final List<PhotoAffichee> photos;
  final int depart;

  const _PhotosPleinEcran({required this.photos, required this.depart});

  @override
  State<_PhotosPleinEcran> createState() => _PhotosPleinEcranState();
}

class _PhotosPleinEcranState extends State<_PhotosPleinEcran> {
  late final PageController _controller =
      PageController(initialPage: widget.depart);
  late int _index = widget.depart;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          [
            if (photo.libelle != null) photo.libelle!,
            if (widget.photos.length > 1) '${_index + 1}/${widget.photos.length}',
          ].join(' · '),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => InteractiveViewer(
          maxScale: 4,
          child: Center(child: _image(widget.photos[i].url, BoxFit.contain)),
        ),
      ),
    );
  }
}

Widget _image(String url, BoxFit fit, {int? cacheWidth}) {
  return Image.network(
    url,
    fit: fit,
    // Décode à la taille d'affichage plutôt qu'en pleine résolution.
    cacheWidth: cacheWidth,
    loadingBuilder: (context, child, progression) => progression == null
        ? child
        : const Center(child: CircularProgressIndicator()),
    errorBuilder: (context, error, stack) => const ColoredBox(
      color: Color(0xFFEAF1ED),
      child: Center(child: Icon(Icons.broken_image_outlined)),
    ),
  );
}
