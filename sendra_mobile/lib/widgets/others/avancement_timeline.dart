import 'package:flutter/material.dart';

import '../../utils/sendra_theme.dart';

/// Une étape du parcours d'un signalement.
class EtapeAvancement {
  const EtapeAvancement({
    required this.etape,
    required this.libelle,
    required this.statut,
    this.detail,
    this.date,
  });

  /// signale, constate, approbation, enlevement, issue.
  final String etape;
  final String libelle;

  /// fait, actuel, echec (rouge, avec motif), a_venir ou saute.
  final String statut;
  final String? detail;
  final String? date;

  bool get atteinte =>
      statut == 'fait' || statut == 'actuel' || statut == 'echec';

  /// Étapes envoyées par le serveur (`avancement`), ou à défaut déduites de
  /// l'état seul (signalement hors ligne ou ancienne réponse).
  static List<EtapeAvancement> depuis(Map<String, dynamic> data) {
    final brut = data['avancement'];
    if (brut is List &&
        brut.isNotEmpty &&
        brut.first is Map &&
        (brut.first as Map).containsKey('etape')) {
      return [
        for (final e in brut)
          if (e is Map)
            EtapeAvancement(
              etape: e['etape']?.toString() ?? '',
              libelle: e['libelle']?.toString() ?? '',
              statut: e['statut']?.toString() ?? 'a_venir',
              detail: e['detail']?.toString(),
              date: e['date']?.toString(),
            ),
      ];
    }

    final etat = data['etat']?.toString() ?? 'SIGNALE';
    final rejete = etat == 'REJETE';
    final nonResolu = etat == 'NON RESOLU';
    final enleve = etat == 'ENLEVE';
    final approuve = data['is_approve'] == true || enleve || nonResolu;
    final constate = data['dommages_saisis'] == true ||
        etat == 'EN COURS' ||
        approuve ||
        rejete;
    return [
      EtapeAvancement(
        etape: 'signale',
        libelle: 'Signalé',
        statut: 'fait',
        detail: 'Signalement reçu',
        date: data['formatted_date']?.toString(),
      ),
      EtapeAvancement(
        etape: 'constate',
        libelle: 'Constaté par l’agent',
        statut: constate ? 'fait' : 'a_venir',
      ),
      EtapeAvancement(
        etape: 'approbation',
        libelle: rejete
            ? 'Rejeté par l’autorité'
            : approuve
                ? 'Approuvé par l’autorité'
                : constate
                    ? 'En attente d’approbation de l’autorité'
                    : 'Approbation de l’autorité',
        statut: rejete
            ? 'echec'
            : approuve
                ? 'fait'
                : constate
                    ? 'actuel'
                    : 'a_venir',
        detail: rejete
            ? 'Motif : ${data['motif_approbation'] ?? 'non précisé'}'
            : null,
      ),
      EtapeAvancement(
        etape: 'enlevement',
        libelle: enleve
            ? 'Véhicule enlevé'
            : nonResolu
                ? 'Véhicule non enlevé'
                : approuve
                    ? 'En attente d’enlèvement'
                    : 'Enlèvement',
        statut: enleve
            ? 'fait'
            : nonResolu
                ? 'echec'
                : rejete
                    ? 'saute'
                    : approuve
                        ? 'actuel'
                        : 'a_venir',
        detail: nonResolu
            ? 'Motif : ${data['non_removal_reason'] ?? 'non précisé'}'
            : null,
      ),
      EtapeAvancement(
        etape: 'issue',
        libelle: nonResolu ? 'Non résolu' : 'Résolu',
        statut: enleve
            ? 'fait'
            : nonResolu
                ? 'echec'
                : rejete
                    ? 'saute'
                    : 'a_venir',
      ),
    ];
  }
}

const _vert = Color(0xFF188038);
const _orange = Color(0xFFE37400);
const _rouge = Color(0xFFD93025);

Color _couleur(String statut) => switch (statut) {
      'fait' => _vert,
      'actuel' => _orange,
      'echec' => _rouge,
      _ => SendraTheme.border,
    };

IconData _icone(EtapeAvancement e) {
  if (e.statut == 'echec') return Icons.close_rounded;
  if (e.statut == 'saute') return Icons.remove_rounded;
  if (e.statut == 'fait') return Icons.check_rounded;
  return switch (e.etape) {
    'signale' => Icons.flag_rounded,
    'constate' => Icons.fact_check_rounded,
    'approbation' => Icons.gavel_rounded,
    'enlevement' => Icons.local_shipping_rounded,
    _ => Icons.verified_rounded,
  };
}

/// Frise verticale de tout le parcours : chaque étape est visible, reliée à
/// la suivante par un rail qui se remplit (glisse) jusqu'à l'étape où en est
/// le dossier. Vert = fait, orange = étape actuelle, rouge = refus ou non
/// enlèvement (avec motif), gris = à venir.
class AvancementTimeline extends StatelessWidget {
  const AvancementTimeline({
    super.key,
    required this.data,
    this.titre = 'Avancement du signalement',
  });

  final Map<String, dynamic> data;
  final String titre;

  @override
  Widget build(BuildContext context) {
    final etapes = EtapeAvancement.depuis(data);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SendraTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: SendraTheme.ink)),
          const SizedBox(height: 14),
          for (var i = 0; i < etapes.length; i++)
            _LigneEtape(
              etape: etapes[i],
              index: i,
              derniere: i == etapes.length - 1,
              // Le rail se remplit vers l'étape suivante si elle est atteinte,
              // de la couleur de cette étape.
              railRempli: i < etapes.length - 1 && etapes[i + 1].atteinte,
              couleurRail: i < etapes.length - 1
                  ? _couleur(etapes[i + 1].statut)
                  : SendraTheme.border,
            ),
        ],
      ),
    );
  }
}

class _LigneEtape extends StatelessWidget {
  const _LigneEtape({
    required this.etape,
    required this.index,
    required this.derniere,
    required this.railRempli,
    required this.couleurRail,
  });

  final EtapeAvancement etape;
  final int index;
  final bool derniere;
  final bool railRempli;
  final Color couleurRail;

  @override
  Widget build(BuildContext context) {
    final couleur = _couleur(etape.statut);
    final saute = etape.statut == 'saute';
    final atteinte = etape.atteinte;
    final actuelle = etape.statut == 'actuel';
    final echec = etape.statut == 'echec';

    // Pas d'IntrinsicHeight (passe de mesure supplémentaire, fragile selon
    // la police et la largeur du téléphone) : la ligne prend la hauteur de
    // son texte, et le rail est posé par-dessus en position absolue.
    return Stack(
      children: [
        if (!derniere)
          Positioned(
            left: 15,
            top: 34,
            bottom: 4,
            width: 4,
            child: _Rail(rempli: railRempli, couleur: couleurRail, delai: index),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 34,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: atteinte ? couleur : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: couleur, width: 2),
                    boxShadow: actuelle
                        ? [
                            BoxShadow(
                                color: couleur.withValues(alpha: .28),
                                spreadRadius: 5)
                          ]
                        : null,
                  ),
                  child: Icon(_icone(etape),
                      size: 17,
                      color: atteinte ? Colors.white : SendraTheme.muted),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 4, bottom: derniere ? 8 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          etape.libelle,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: actuelle || echec
                                ? FontWeight.w800
                                : FontWeight.w700,
                            color: echec
                                ? _rouge
                                : atteinte
                                    ? SendraTheme.ink
                                    : SendraTheme.muted,
                            decoration: saute ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (actuelle)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: couleur.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Étape actuelle',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: couleur)),
                          ),
                      ],
                    ),
                    if ((etape.detail ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(etape.detail!,
                          style: TextStyle(
                              color: echec ? _rouge : SendraTheme.muted,
                              fontWeight:
                                  echec ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 13.5,
                              height: 1.35)),
                    ],
                    if (atteinte && (etape.date ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              size: 14, color: SendraTheme.muted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(etape.date!,
                                style: const TextStyle(
                                    color: SendraTheme.muted, fontSize: 12.5)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Rail vertical entre deux étapes : se remplit de haut en bas à l'affichage.
class _Rail extends StatelessWidget {
  const _Rail(
      {required this.rempli, required this.couleur, required this.delai});
  final bool rempli;
  final Color couleur;
  final int delai;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      decoration: BoxDecoration(
        color: SendraTheme.border,
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.topCenter,
      child: rempli
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 400 + 200 * delai),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => FractionallySizedBox(
                heightFactor: t,
                alignment: Alignment.topCenter,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: couleur,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
