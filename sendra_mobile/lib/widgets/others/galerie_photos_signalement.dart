import 'package:flutter/material.dart';
import 'package:walletium/services/offline_signalement_service.dart';
import 'package:walletium/widgets/others/photo_reseau.dart';

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

    // Décodage à la taille réellement affichée (au lieu d'une valeur fixe) :
    // moins de mémoire et un défilement fluide sur les petits téléphones.
    final largeur = MediaQuery.sizeOf(context).width;

    return Column(
      children: [
        Text(
          photos.length > 1
              ? 'Faites défiler les ${photos.length} photos · appuyez pour agrandir'
              : 'Appuyez pour agrandir l\'image',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          height: widget.hauteur,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
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
                    child:
                        _image(photos[i].url, BoxFit.cover, largeur: largeur),
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
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texte,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  void _pleinEcran(
      BuildContext context, List<PhotoAffichee> photos, int depart) {
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
  // Quarts de tour appliqués à l'affichage, photo par photo : permet de
  // redresser une ancienne photo enregistrée couchée.
  final Map<int, int> _quarts = {};

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
            if (widget.photos.length > 1)
              '${_index + 1}/${widget.photos.length}',
          ].join(' · '),
        ),
        actions: [
          IconButton(
            tooltip: 'Pivoter la photo',
            icon: const Icon(Icons.rotate_right_rounded),
            onPressed: () => setState(
                () => _quarts[_index] = ((_quarts[_index] ?? 0) + 1) % 4),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => InteractiveViewer(
          maxScale: 4,
          child: Center(
            child: RotatedBox(
              quarterTurns: _quarts[i] ?? 0,
              child: _image(widget.photos[i].url, BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

/// Photo mise en cache sur le téléphone : elle n'est téléchargée qu'une
/// fois, puis s'affiche instantanément (liste, fiche, plein écran).
Widget _image(String url, BoxFit fit, {double? largeur}) {
  return PhotoReseau(
    url,
    fit: fit,
    largeur: largeur,
    attente: const Center(child: CircularProgressIndicator()),
  );
}
