import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Photo distante mise en cache sur le téléphone (mémoire + disque).
///
/// Avant, chaque photo était retéléchargée à chaque ouverture d'écran et
/// décodée en pleine résolution : listes saccadées et consommation de
/// données. Ici la photo n'est téléchargée qu'une fois, puis décodée à la
/// taille où elle est affichée ([largeur], en dp).
class PhotoReseau extends StatelessWidget {
  const PhotoReseau(
    this.url, {
    super.key,
    this.largeur,
    this.fit = BoxFit.cover,
    this.attente,
    this.erreur,
  });

  final String url;

  /// Largeur affichée en dp, pour décoder l'image à la bonne taille. Nulle
  /// en plein écran (zoom) : l'image garde sa résolution d'origine.
  final double? largeur;
  final BoxFit fit;
  final Widget? attente;
  final Widget? erreur;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      memCacheWidth: largeur == null ? null : (largeur! * dpr).round(),
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: Duration.zero,
      placeholder: (_, __) =>
          attente ?? const ColoredBox(color: Color(0xFFEAF1ED)),
      errorWidget: (_, __, ___) =>
          erreur ??
          const ColoredBox(
            color: Color(0xFFEAF1ED),
            child: Center(child: Icon(Icons.broken_image_outlined)),
          ),
    );
  }
}

/// Même cache, pour les endroits qui attendent un [ImageProvider]
/// (avatar, fond décoré).
ImageProvider photoReseauProvider(String url) =>
    CachedNetworkImageProvider(url);
