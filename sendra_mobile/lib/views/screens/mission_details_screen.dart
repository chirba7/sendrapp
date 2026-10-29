import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:walletium/models/mission.dart';
import 'package:walletium/services/mission_service.dart';
import 'package:walletium/utils/ecran.dart';
import 'package:walletium/utils/sendra_theme.dart';
import 'package:walletium/utils/signaler_flow.dart';
import 'package:walletium/widgets/others/photo_reseau.dart';

import 'carto.dart';

/// Fiche d'une mission pour l'agent de terrain ou le réceptionniste.
///
/// Après validation de l'enlèvement (terrain) ou fin de mission (réception),
/// tout passe en lecture seule : on consulte, on ne modifie plus — le serveur
/// refuse aussi toute modification.
class MissionDetailsScreen extends StatefulWidget {
  const MissionDetailsScreen({
    super.key,
    required this.missionId,
    required this.initialMission,
  });
  final int missionId;
  final Mission initialMission;
  @override
  State<MissionDetailsScreen> createState() => _MissionDetailsScreenState();
}

const _violet = Color(0xFF6847B8);
const _bleu = Color(0xFF1769AA);

TextStyle _titreStyle([double taille = 16]) => TextStyle(
      fontFamily: SendraTheme.fontFamily,
      fontSize: taille,
      fontWeight: FontWeight.w800,
      color: SendraTheme.ink,
    );

const _texteDiscret = TextStyle(
  fontFamily: SendraTheme.fontFamily,
  color: SendraTheme.muted,
  fontSize: 13.5,
  height: 1.35,
);

String _date(DateTime? d) {
  if (d == null) return 'Date à préciser';
  final l = d.toLocal();
  String deux(int v) => v.toString().padLeft(2, '0');
  return '${deux(l.day)}/${deux(l.month)}/${l.year} à ${deux(l.hour)}h${deux(l.minute)}';
}

class _MissionDetailsScreenState extends State<MissionDetailsScreen> {
  final _service = MissionService();
  late Mission _mission = widget.initialMission;
  bool _busy = false;

  bool get _pointe =>
      _mission.isReceiver ? _mission.receptionCheckedIn : _mission.checkedIn;
  bool get _lectureSeule => _mission.readOnly;

  @override
  void initState() {
    super.initState();
    _refresh(silent: true);
  }

  Future<void> _refresh({bool silent = false}) async {
    try {
      final mission = await _service.detail(widget.missionId);
      if (mounted) setState(() => _mission = mission);
    } catch (e) {
      if (!silent && mounted) _error(e);
    }
  }

  Future<Position> _position() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Activez la localisation du téléphone pour pointer.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
          'L’autorisation de localisation est nécessaire pour pointer.');
    }
    return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _action(Future<Mission> Function() appel) async {
    setState(() => _busy = true);
    try {
      final mission = await appel();
      if (mounted) setState(() => _mission = mission);
    } catch (e) {
      if (mounted) _error(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkIn() => _action(() async {
        final p = await _position();
        return _service.checkIn(
            _mission.id, p.latitude, p.longitude, p.accuracy);
      });

  Future<void> _checkInReception() => _action(() async {
        final p = await _position();
        return _service.checkInReception(_mission.id, p.latitude, p.longitude);
      });

  Future<bool> _confirmer(String titre, String texte, String bouton) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.lock_outline_rounded, color: SendraTheme.green),
        title: Text(titre),
        content: Text(texte),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(bouton)),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _validateRemoval() async {
    if (!await _confirmer(
      'Valider l’enlèvement ?',
      'Après validation, les enlèvements, les camions et les motifs ne seront '
          'plus modifiables : vous pourrez seulement les consulter.',
      'Valider',
    )) {
      return;
    }
    await _action(() => _service.validateRemoval(_mission.id));
  }

  Future<void> _completeMission() async {
    if (!await _confirmer(
      'Terminer la mission ?',
      'Après validation, les réceptions ne seront plus modifiables : vous '
          'pourrez seulement les consulter.',
      'Terminer',
    )) {
      return;
    }
    await _action(() => _service.completeMission(_mission.id));
  }

  Future<void> _markNotRemoved(MissionVehicle vehicle) async {
    var reasonText = vehicle.nonRemovalReason ?? '';
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, updateDialog) => AlertDialog(
          title: const Text('Véhicule non enlevé'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicle.label, style: _titreStyle(15)),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: reasonText,
                  onChanged: (value) => updateDialog(() => reasonText = value),
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Motif obligatoire',
                    hintText: 'Ex. : le véhicule n’est plus sur les lieux',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: reasonText.trim().isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, reasonText.trim()),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;
    await _action(
        () => _service.markNotRemoved(_mission.id, vehicle.id, reason));
  }

  void _error(Object error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );

  // ───────────────────────────── Écran ──────────────────────────────────

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: SendraTheme.surface,
        appBar: AppBar(
          title: Text(_mission.code.isEmpty ? 'Mission' : _mission.code),
          actions: [
            IconButton(
              tooltip: 'Actualiser',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: DefaultTextStyle.merge(
          style: const TextStyle(fontFamily: SendraTheme.fontFamily),
          child: RefreshIndicator(
            color: SendraTheme.green,
            onRefresh: _refresh,
            child: ListView(
              padding:
                  EdgeInsets.fromLTRB(16, 12, 16, 32 + context.margeBasSysteme),
              children: [
                _entete(),
                const SizedBox(height: 12),
                if (_lectureSeule)
                  _bandeauLectureSeule()
                else
                  _nextActionCard(),
                ..._contenu(),
              ],
            ),
          ),
        ),
      );

  List<Widget> _contenu() {
    if (_mission.isReceiver && !_mission.removalValidated) {
      return [
        const _Carte(
          titre: 'Réception en attente',
          icone: Icons.hourglass_top_rounded,
          couleur: SendraTheme.amber,
          children: [
            Text(
              'L’équipe terrain doit d’abord valider la phase d’enlèvement.',
              style: _texteDiscret,
            ),
          ],
        ),
      ];
    }
    if (!_pointe) {
      return [
        _Carte(
          titre: 'Pointage obligatoire',
          icone: Icons.my_location_rounded,
          couleur: _bleu,
          children: [
            Text(
              _mission.isReceiver
                  ? 'Pointez au poste ${_mission.receptionPoundName ?? 'de fourrière'} pour commencer la réception.'
                  : 'Votre position est comparée à la zone de la commune avant de déverrouiller la mission.',
              style: _texteDiscret,
            ),
            const SizedBox(height: 14),
            _GrosBouton(
              onPressed: _busy
                  ? null
                  : (_mission.isReceiver ? _checkInReception : _checkIn),
              icone: Icons.my_location_rounded,
              libelle: _busy ? 'Vérification…' : 'Pointer maintenant',
              chargement: _busy,
            ),
          ],
        ),
      ];
    }

    final nonEnleves = _mission.vehicles
        .where((v) => (v.nonRemovalReason ?? '').trim().isNotEmpty)
        .toList();

    return [
      if (_mission.isReceiver)
        _Carte(
          titre: 'Véhicules non enlevés',
          icone: Icons.report_problem_outlined,
          couleur: SendraTheme.amber,
          compteur: nonEnleves.length,
          children: [
            if (nonEnleves.isEmpty)
              const Text('Aucun véhicule déclaré non enlevé.',
                  style: _texteDiscret),
            for (final v in nonEnleves)
              _TuileVehicule(
                icone: Icons.cancel_outlined,
                couleur: SendraTheme.amber,
                titre: v.label,
                sousTitre: [
                  if ((v.plate ?? '').isNotEmpty) v.plate!,
                  'Motif : ${v.nonRemovalReason}',
                ].join('\n'),
              ),
          ],
        ),
      _Carte(
        titre: 'Camions',
        icone: Icons.local_shipping_outlined,
        couleur: _bleu,
        compteur: _mission.trucks.length,
        children: [
          if (_mission.trucks.isEmpty)
            const Text('Aucun camion renseigné.', style: _texteDiscret),
          for (final t in _mission.trucks)
            _TuileVehicule(
              icone: Icons.local_shipping_rounded,
              couleur: _bleu,
              titre: [t.brand, t.registration]
                  .where((v) => (v ?? '').isNotEmpty)
                  .join(' · '),
              sousTitre: [
                if ((t.driverName ?? '').isNotEmpty) t.driverName!,
                t.destinationPoundName ?? 'Fourrière à préciser',
              ].join(' · '),
              statut: t.destinationPoundName == null
                  ? ('À préciser', SendraTheme.amber)
                  : ('Destination OK', SendraTheme.green),
              onTap: _mission.isReceiver ||
                      _lectureSeule ||
                      _mission.pounds.isEmpty
                  ? null
                  : () => _openTruckDestination(t),
              trailing: _mission.isReceiver || _lectureSeule
                  ? null
                  : const Icon(Icons.edit_outlined, color: SendraTheme.muted),
            ),
        ],
      ),
      _Carte(
        titre: 'Fourrières prêtes',
        icone: Icons.warehouse_outlined,
        couleur: _violet,
        compteur: _mission.pounds.length,
        children: [
          if (_mission.pounds.isEmpty)
            const Text('Aucune fourrière renseignée.', style: _texteDiscret),
          for (final p in _mission.pounds)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                const Icon(Icons.local_parking_rounded,
                    size: 18, color: _violet),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(p,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
              ]),
            ),
        ],
      ),
      if (_mission.vehicles.isNotEmpty && !_mission.isReceiver)
        _Carte(
          titre: _mission.isProgrammed
              ? 'Véhicules programmés'
              : 'Véhicules ciblés',
          icone: Icons.directions_car_outlined,
          couleur: SendraTheme.green,
          compteur: _mission.vehicles.length,
          children: [
            for (final v in _mission.vehicles) _tuileVehiculeCible(v),
          ],
        ),
      _Carte(
        titre: _mission.isReceiver
            ? 'Véhicules à réceptionner'
            : _modeImprevus
                ? 'Enlèvements imprévus'
                : 'Enlèvements',
        icone: _mission.isReceiver
            ? Icons.inventory_2_outlined
            : Icons.photo_camera_outlined,
        couleur: _mission.isReceiver ? _violet : const Color(0xFF00897B),
        compteur: _enlevementsAffiches.length,
        children: [
          if (_modeImprevus)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Véhicules qui n’étaient pas prévus dans la mission mais trouvés '
                'en infraction sur place : ils ne peuvent pas être ignorés et '
                'doivent être enlevés eux aussi.',
                style: _texteDiscret,
              ),
            ),
          if (_enlevementsAffiches.isEmpty)
            Text(
              _mission.isReceiver
                  ? 'Aucun véhicule à réceptionner pour cette mission.'
                  : _modeImprevus
                      ? 'Aucun enlèvement imprévu pour le moment.'
                      : 'Aucun véhicule photographié pour le moment.',
              style: _texteDiscret,
            ),
          for (final r in _enlevementsAffiches)
            _TuileVehicule(
              icone: Icons.directions_car_rounded,
              photoUrl: r.photos['front'] ?? r.thumbnailUrl,
              couleur: _mission.isReceiver ? _violet : const Color(0xFF00897B),
              titre: r.label,
              sousTitre: _removalSubtitle(r),
              statut: _mission.isReceiver
                  ? (r.received
                      ? ('Réceptionné', SendraTheme.green)
                      : ('À réceptionner', SendraTheme.amber))
                  : (r.sheetPhotoUrl == null
                      ? ('Fiche manquante', SendraTheme.amber)
                      : ('Fiche ajoutée', SendraTheme.green)),
              onTap: () => _mission.isReceiver
                  ? _openReception(r)
                  : _openRemoval(existingRemoval: r),
              trailing: Icon(
                _lectureSeule
                    ? Icons.visibility_outlined
                    : Icons.chevron_right_rounded,
                color: SendraTheme.muted,
              ),
            ),
          if (!_mission.isReceiver && !_lectureSeule) ...[
            if (_mission.trucks.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6, bottom: 8),
                child: Text(
                  'Un camion doit être ajouté par l’administration avant de commencer un enlèvement.',
                  style: TextStyle(color: SendraTheme.statusSignale),
                ),
              ),
            const SizedBox(height: 6),
            _GrosBouton(
              onPressed: _mission.trucks.isEmpty || _busy
                  ? null
                  : () => _openRemoval(extraVehicle: true),
              icone: Icons.add_a_photo_outlined,
              libelle: _modeImprevus
                  ? 'Ajouter un véhicule imprévu'
                  : 'Nouvel enlèvement',
              secondaire: true,
            ),
          ],
        ],
      ),
      _carteFin(),
    ];
  }

  /// Mission avec une liste de véhicules : la carte « Enlèvements » ne
  /// montre que les véhicules imprévus (non ciblés mais en infraction sur
  /// place) ; les véhicules ciblés enlevés restent dans leur propre carte.
  bool get _modeImprevus =>
      !_mission.isReceiver && _mission.vehicles.isNotEmpty;

  List<MissionRemoval> get _enlevementsAffiches {
    if (!_modeImprevus) return _mission.removals;
    final cibles = {for (final v in _mission.vehicles) v.id};
    return _mission.removals
        .where((r) => !cibles.contains(r.carPositionId))
        .toList(growable: false);
  }

  /// Photos et position d'un véhicule ciblé, consultables même quand
  /// l'enlèvement n'est pas (ou plus) possible.
  void _voirSignalement(MissionVehicle v) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: SendraTheme.surface,
      builder: (ctx) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + ctx.margeBasSysteme),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(v.label,
                style: const TextStyle(
                    fontFamily: SendraTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: SendraTheme.ink)),
            if ((v.plate ?? '').isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(v.plate!, style: _texteDiscret),
            ],
            const SizedBox(height: 12),
            _FicheSignalement(
              photos: v.photos,
              latitude: v.latitude,
              longitude: v.longitude,
              lieu: v.lieu,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tuileVehiculeCible(MissionVehicle v) {
    final matches =
        _mission.removals.where((r) => r.carPositionId == v.id).toList();
    final removal = matches.isEmpty ? null : matches.first;
    final done = removal != null;
    final notRemoved = (v.nonRemovalReason ?? '').isNotEmpty;
    final modifiable = !_lectureSeule && !_busy;
    return _TuileVehicule(
      icone: notRemoved
          ? Icons.cancel_outlined
          : done
              ? Icons.check_circle_rounded
              : Icons.directions_car_rounded,
      couleur: notRemoved
          ? SendraTheme.amber
          : done
              ? SendraTheme.green
              : SendraTheme.muted,
      photoUrl: v.thumbnailUrl,
      titre: v.label,
      sousTitre: [
        if ((v.plate ?? '').isNotEmpty) v.plate!,
        if (v.lieu.isNotEmpty) v.lieu,
        if (notRemoved) 'Motif : ${v.nonRemovalReason}',
      ].join('\n'),
      statut: notRemoved
          ? ('Non enlevé', SendraTheme.amber)
          : done
              ? (removal?.sheetPhotoUrl == null
                  ? ('Enlevé · fiche manquante', SendraTheme.amber)
                  : ('Enlevé', SendraTheme.green))
              : ('À enlever', _bleu),
      onTap: done
          ? () => _openRemoval(existingRemoval: removal)
          : (!modifiable || _mission.trucks.isEmpty)
              ? () => _voirSignalement(v)
              : () => _openRemoval(vehicle: v),
      trailing: !done && modifiable
          ? IconButton(
              tooltip: notRemoved ? 'Modifier le motif' : 'Déclarer non enlevé',
              icon: const Icon(Icons.report_problem_outlined,
                  color: SendraTheme.amber),
              onPressed: () => _markNotRemoved(v),
            )
          : null,
    );
  }

  Widget _carteFin() {
    final recus = _mission.removals.where((r) => r.received).length;
    if (_lectureSeule) {
      return _Carte(
        titre: _mission.completed ? 'Mission terminée' : 'Enlèvement validé',
        icone: Icons.verified_rounded,
        couleur: SendraTheme.green,
        children: [
          if (_mission.removalValidatedAt != null)
            _ligneInfo(Icons.outbox_rounded,
                'Enlèvement validé le ${_date(_mission.removalValidatedAt)}'),
          if (_mission.completedAt != null)
            _ligneInfo(Icons.flag_rounded,
                'Mission terminée le ${_date(_mission.completedAt)}'),
          if (_mission.isReceiver)
            _ligneInfo(Icons.inventory_2_outlined,
                '$recus/${_mission.removals.length} véhicule(s) réceptionné(s)'),
        ],
      );
    }
    return _Carte(
      titre: _mission.isReceiver
          ? 'Finaliser la réception'
          : 'Fin de l’enlèvement',
      icone: Icons.task_alt_rounded,
      couleur: SendraTheme.green,
      children: [
        Text(
          _mission.isReceiver
              ? '$recus/${_mission.removals.length} véhicule(s) réceptionné(s).'
              : 'Pour chaque véhicule programmé, enregistrez un enlèvement ou indiquez pourquoi il n’a pas été enlevé.',
          style: _texteDiscret,
        ),
        const SizedBox(height: 12),
        _GrosBouton(
          onPressed: _busy
              ? null
              : (_mission.isReceiver ? _completeMission : _validateRemoval),
          icone: Icons.task_alt_rounded,
          libelle: _mission.isReceiver
              ? 'Valider et terminer la mission'
              : 'Valider l’enlèvement',
          chargement: _busy,
        ),
      ],
    );
  }

  Widget _ligneInfo(IconData icone, String texte) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icone, size: 18, color: SendraTheme.green),
            const SizedBox(width: 8),
            Expanded(
                child: Text(texte,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );

  /// En-tête : code, rôle, état et progression de la mission.
  Widget _entete() {
    final etapes = _mission.isReceiver
        ? const ['Terrain', 'Pointage', 'Réception', 'Terminée']
        : const ['Pointage', 'Enlèvements', 'Validation', 'Réception'];
    final int atteinte;
    if (_mission.isReceiver) {
      atteinte = _mission.completed
          ? 4
          : _mission.receptionCheckedIn
              ? 2
              : _mission.removalValidated
                  ? 1
                  : 0;
    } else {
      atteinte = _mission.completed
          ? 4
          : _mission.removalValidated
              ? 3
              : _mission.checkedIn
                  ? 1
                  : 0;
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SendraTheme.forest, SendraTheme.green],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Pastille(_mission.isReceiver
                  ? 'Réception en fourrière'
                  : 'Équipe terrain'),
              _Pastille(_mission.isProgrammed ? 'Programmée' : 'Ponctuelle'),
              if (_lectureSeule)
                const _Pastille('Lecture seule', icone: Icons.lock_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _mission.title,
            style: const TextStyle(
              fontFamily: SendraTheme.fontFamily,
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          _ligneBlanche(Icons.event_rounded, _date(_mission.scheduledAt)),
          if (_mission.address.isNotEmpty)
            _ligneBlanche(Icons.place_rounded, _mission.address),
          if ((_mission.providerName ?? '').isNotEmpty)
            _ligneBlanche(Icons.business_rounded, _mission.providerName!),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < etapes.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < atteinte
                              ? Colors.white
                              : Colors.white.withValues(alpha: .18),
                          border: Border.all(
                            color: Colors.white,
                            width: i == atteinte ? 2 : 0,
                          ),
                        ),
                        child: i < atteinte
                            ? const Icon(Icons.check_rounded,
                                size: 16, color: SendraTheme.green)
                            : null,
                      ),
                      const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          etapes[i],
                          style: TextStyle(
                            fontFamily: SendraTheme.fontFamily,
                            color: Colors.white
                                .withValues(alpha: i <= atteinte ? 1 : .7),
                            fontSize: 11.5,
                            fontWeight: i == atteinte
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _ligneBlanche(IconData icone, String texte) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Icon(icone, size: 16, color: Colors.white70),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                texte,
                style: const TextStyle(
                    fontFamily: SendraTheme.fontFamily,
                    color: Colors.white,
                    fontSize: 13.5),
              ),
            ),
          ],
        ),
      );

  Widget _bandeauLectureSeule() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF1ED),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFB7DEC4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_rounded, color: SendraTheme.forest),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _mission.isReceiver
                    ? 'Mission terminée : la réception est en lecture seule.'
                    : 'Enlèvement validé : vous pouvez consulter, mais plus modifier.',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: SendraTheme.forest),
              ),
            ),
          ],
        ),
      );

  Widget _nextActionCard() {
    late final String title;
    late final String message;
    late final IconData icon;
    late final Color color;
    if (_mission.isReceiver && !_mission.removalValidated) {
      title = 'En attente de l’équipe terrain';
      message =
          'La réception sera disponible après validation de l’enlèvement.';
      icon = Icons.hourglass_top_rounded;
      color = _violet;
    } else if (!_pointe) {
      title = 'Prochaine action : pointer';
      message = _mission.isReceiver
          ? 'Rendez-vous à ${_mission.receptionPoundName ?? 'la fourrière'}.'
          : 'Rendez-vous dans la zone de la mission.';
      icon = Icons.my_location_rounded;
      color = _bleu;
    } else if (_mission.isReceiver) {
      final left = _mission.removals.where((r) => !r.received).length;
      title =
          left == 0 ? 'Prête à être terminée' : 'Réceptionner les véhicules';
      message = left == 0
          ? (_mission.removals.isEmpty
              ? 'Aucun véhicule à réceptionner. Consultez les motifs puis terminez la mission.'
              : 'Terminez la mission.')
          : '$left véhicule(s) restent à photographier.';
      icon = Icons.warehouse_outlined;
      color = _violet;
    } else {
      title = 'Photographier et affecter';
      message =
          'Complétez les véhicules, les camions et leurs destinations, puis validez.';
      icon = Icons.add_a_photo_outlined;
      color = SendraTheme.amber;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _titreStyle(16)),
                const SizedBox(height: 2),
                Text(message, style: _texteDiscret),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _removalSubtitle(MissionRemoval removal) {
    final trucks = _mission.trucks.where((t) => t.id == removal.truckId);
    final truck = trucks.isEmpty ? null : trucks.first;
    return [
      if ((removal.plate ?? '').isNotEmpty) removal.plate!,
      if (truck != null)
        'Camion ${truck.registration ?? truck.brand ?? truck.id}',
      truck?.destinationPoundName ?? 'Fourrière à préciser sur le camion',
    ].join(' · ');
  }

  Future<void> _openRemoval({
    MissionVehicle? vehicle,
    MissionRemoval? existingRemoval,
    bool extraVehicle = false,
  }) async {
    final result = await Navigator.push<Mission>(
      context,
      MaterialPageRoute(
        builder: (_) => _RemovalScreen(
          mission: _mission,
          service: _service,
          selectedVehicle: vehicle,
          existingRemoval: existingRemoval,
          extraVehicle: extraVehicle,
          readOnly: _lectureSeule,
        ),
      ),
    );
    if (result != null && mounted) setState(() => _mission = result);
  }

  Future<void> _openTruckDestination(MissionTruck truck) async {
    final result = await showModalBottomSheet<Mission>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _TruckDestinationSheet(
        mission: _mission,
        truck: truck,
        service: _service,
      ),
    );
    if (result != null && mounted) setState(() => _mission = result);
  }

  Future<void> _openReception(MissionRemoval removal) async {
    final result = await Navigator.push<Mission>(
      context,
      MaterialPageRoute(
        builder: (_) => _ReceptionPhotoScreen(
          mission: _mission,
          removal: removal,
          service: _service,
          readOnly: _lectureSeule,
        ),
      ),
    );
    if (result != null && mounted) setState(() => _mission = result);
  }
}

// ───────────────────────────── Composants ───────────────────────────────

/// Bande de photos défilante ; un appui ouvre la photo en plein écran.
class _BlocPhotos extends StatelessWidget {
  const _BlocPhotos({required this.titre, required this.photos});
  final String titre;
  final List<({String url, String libelle, bool agent})> photos;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SendraTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(titre,
                style: const TextStyle(
                    fontFamily: SendraTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: SendraTheme.ink)),
            const SizedBox(height: 10),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => _vignette(context, photos[i]),
              ),
            ),
          ],
        ),
      );

  Widget _vignette(
      BuildContext context, ({String url, String libelle, bool agent}) p) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _PhotoPleinEcran(
            image: photoReseauProvider(p.url), titre: p.libelle),
      )),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 112,
          height: 112,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PhotoReseau(p.url, largeur: 112),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  color: p.agent ? const Color(0xCC1769AA) : Colors.black54,
                  child: Text(p.libelle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Signalement d'origine d'un véhicule ciblé : photos du citoyen puis de
/// l'agent qui l'a constaté, position et itinéraire.
class _FicheSignalement extends StatelessWidget {
  const _FicheSignalement({
    required this.photos,
    this.latitude,
    this.longitude,
    this.lieu,
  });
  final List<SignalementPhoto> photos;
  final double? latitude;
  final double? longitude;
  final String? lieu;

  bool get _aPosition =>
      latitude != null &&
      longitude != null &&
      !(latitude == 0 && longitude == 0);

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty && !_aPosition) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (photos.isNotEmpty)
          _BlocPhotos(
            titre: 'Photos du signalement',
            photos: [
              for (final p in photos)
                (
                  url: p.url,
                  libelle: p.parAgent ? 'Agent (constat)' : 'Citoyen',
                  agent: p.parAgent,
                ),
            ],
          ),
        if (_aPosition)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SendraTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 20, color: SendraTheme.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (lieu ?? '').trim().isNotEmpty
                            ? lieu!
                            : '${latitude!.toStringAsFixed(5)}, '
                                '${longitude!.toStringAsFixed(5)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: SendraTheme.ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NavigationScreen(
                          latitude: latitude!, longitude: longitude!),
                    ),
                  ),
                  icon: const Icon(Icons.directions_rounded),
                  label: const Text('Position et itinéraire'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Carte extends StatelessWidget {
  const _Carte({
    required this.titre,
    required this.icone,
    required this.couleur,
    required this.children,
    this.compteur,
  });

  final String titre;
  final IconData icone;
  final Color couleur;
  final List<Widget> children;
  final int? compteur;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(SendraTheme.radius),
          border: Border.all(color: SendraTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icone, color: couleur, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(titre, style: _titreStyle(16))),
                if (compteur != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: couleur.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$compteur',
                        style: TextStyle(
                            fontFamily: SendraTheme.fontFamily,
                            color: couleur,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );
}

class _TuileVehicule extends StatelessWidget {
  const _TuileVehicule({
    required this.icone,
    required this.couleur,
    required this.titre,
    this.photoUrl,
    this.sousTitre,
    this.statut,
    this.onTap,
    this.trailing,
  });

  final IconData icone;
  final Color couleur;
  final String titre;

  /// Photo du signalement : remplace l'icône, qui passe en pastille.
  final String? photoUrl;
  final String? sousTitre;
  final (String, Color)? statut;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: SendraTheme.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
              child: Row(
                children: [
                  if ((photoUrl ?? '').isNotEmpty)
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: PhotoReseau(photoUrl!, largeur: 56),
                            ),
                          ),
                          Positioned(
                            right: -5,
                            bottom: -5,
                            child: Container(
                              padding: const EdgeInsets.all(1.5),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icone, color: couleur, size: 18),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Icon(icone, color: couleur, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titre.isEmpty ? 'Véhicule' : titre,
                            style: const TextStyle(
                                fontFamily: SendraTheme.fontFamily,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: SendraTheme.ink)),
                        if ((sousTitre ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(sousTitre!, style: _texteDiscret),
                        ],
                        if (statut != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statut!.$2.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(statut!.$1,
                                style: TextStyle(
                                    fontFamily: SendraTheme.fontFamily,
                                    color: statut!.$2,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
        ),
      );
}

class _Pastille extends StatelessWidget {
  const _Pastille(this.texte, {this.icone});
  final String texte;
  final IconData? icone;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null) ...[
              Icon(icone, size: 13, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(texte,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: SendraTheme.fontFamily,
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

class _GrosBouton extends StatelessWidget {
  const _GrosBouton({
    required this.onPressed,
    required this.icone,
    required this.libelle,
    this.chargement = false,
    this.secondaire = false,
  });

  final VoidCallback? onPressed;
  final IconData icone;
  final String libelle;
  final bool chargement;
  final bool secondaire;

  @override
  Widget build(BuildContext context) {
    final icon = chargement
        ? const SizedBox.square(
            dimension: 18,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Icon(icone);
    final label = Text(libelle,
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700));
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: secondaire
          ? OutlinedButton.icon(onPressed: onPressed, icon: icon, label: label)
          : FilledButton.icon(onPressed: onPressed, icon: icon, label: label),
    );
  }
}

/// Photo en plein écran, zoomable (consultation en lecture seule), avec un
/// bouton pour la pivoter si elle a été enregistrée couchée.
void _voirPhoto(BuildContext context, ImageProvider image, String titre) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => _PhotoPleinEcran(image: image, titre: titre),
  ));
}

class _PhotoPleinEcran extends StatefulWidget {
  const _PhotoPleinEcran({required this.image, required this.titre});
  final ImageProvider image;
  final String titre;

  @override
  State<_PhotoPleinEcran> createState() => _PhotoPleinEcranState();
}

class _PhotoPleinEcranState extends State<_PhotoPleinEcran> {
  int _quarts = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(widget.titre),
          actions: [
            IconButton(
              tooltip: 'Pivoter la photo',
              icon: const Icon(Icons.rotate_right_rounded),
              onPressed: () => setState(() => _quarts = (_quarts + 1) % 4),
            ),
          ],
        ),
        body: InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: RotatedBox(
              quarterTurns: _quarts,
              child: Image(image: widget.image, fit: BoxFit.contain),
            ),
          ),
        ),
      );
}

class _RemovalScreen extends StatefulWidget {
  const _RemovalScreen({
    required this.mission,
    required this.service,
    required this.extraVehicle,
    this.selectedVehicle,
    this.existingRemoval,
    this.readOnly = false,
  });
  final Mission mission;
  final MissionService service;
  final MissionVehicle? selectedVehicle;
  final MissionRemoval? existingRemoval;
  final bool extraVehicle;

  /// Enlèvement validé : consultation seulement.
  final bool readOnly;
  @override
  State<_RemovalScreen> createState() => _RemovalScreenState();
}

class _RemovalScreenState extends State<_RemovalScreen> {
  final _picker = ImagePicker();
  final _label = TextEditingController();
  final _plate = TextEditingController();
  final Map<String, File> _photos = {};
  File? _sheet;
  int? _vehicleId;
  int? _truckId;
  bool _saving = false;
  static const _angles = {
    'front': 'Devant',
    'back': 'Derrière',
    'left': 'Côté gauche',
    'right': 'Côté droit',
  };
  @override
  void initState() {
    super.initState();
    _vehicleId =
        widget.selectedVehicle?.id ?? widget.existingRemoval?.carPositionId;
    _truckId = widget.existingRemoval?.truckId;
    _label.text = widget.existingRemoval?.label ?? '';
    _plate.text = widget.existingRemoval?.plate ?? '';
    if (_truckId == null && widget.mission.trucks.length == 1) {
      _truckId = widget.mission.trucks.first.id;
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _plate.dispose();
    super.dispose();
  }

  Future<void> _take(String angle) async {
    if (widget.readOnly) {
      final image = _photoProvider(angle);
      if (image != null) _voirPhoto(context, image, _angles[angle] ?? angle);
      return;
    }
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (file == null) return;
    // Photo redressée (orientation appliquée aux pixels) et allégée avant
    // l'envoi : plus de photo couchée, envoi 3 à 5 fois plus rapide.
    final photo = await SignalerFlow.optimiser(File(file.path));
    if (mounted) setState(() => _photos[angle] = photo);
  }

  Future<void> _save() async {
    if (widget.readOnly) return;
    if (_truckId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez le camion qui emporte le véhicule.'),
        ),
      );
      return;
    }
    final existingPhotos = widget.existingRemoval?.photos ?? const {};
    if ({...existingPhotos, ..._photos}.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les 4 vues du véhicule sont obligatoires.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final result = widget.existingRemoval == null
          ? await widget.service.createRemoval(
              widget.mission.id,
              carPositionId: _vehicleId,
              truckId: _truckId,
              vehicleLabel: _label.text.trim(),
              plate: _plate.text.trim(),
              photos: _photos,
              sheet: _sheet,
            )
          : await widget.service.updateRemoval(
              widget.mission.id,
              widget.existingRemoval!.id,
              truckId: _truckId!,
              vehicleLabel: _label.text.trim(),
              plate: _plate.text.trim(),
              photos: _photos,
              sheet: _sheet,
            );
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.mission.vehicles
        .where(
          (v) => !widget.mission.removals.any((r) => r.carPositionId == v.id),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingRemoval != null
              ? 'Détail de l’enlèvement'
              : widget.extraVehicle && widget.mission.vehicles.isNotEmpty
                  ? 'Véhicule imprévu'
                  : 'Nouvel enlèvement',
        ),
      ),
      backgroundColor: SendraTheme.surface,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + context.margeBasSysteme),
        children: [
          if (widget.readOnly)
            const _BandeauConsultation(
              'Enlèvement validé : consultation seule. Touchez une photo pour l’agrandir.',
            ),
          _ficheDuVehicule(),
          if (widget.selectedVehicle != null ||
              widget.existingRemoval?.carPositionId != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.directions_car)),
              title: Text(
                widget.selectedVehicle?.label ?? widget.existingRemoval!.label,
              ),
              subtitle: (widget.selectedVehicle?.plate ??
                          widget.existingRemoval?.plate) ==
                      null
                  ? null
                  : Text(
                      widget.selectedVehicle?.plate ??
                          widget.existingRemoval!.plate!,
                    ),
            )
          else if (widget.mission.isProgrammed && !widget.extraVehicle)
            DropdownButtonFormField<int?>(
              initialValue: _vehicleId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Véhicule'),
              items: [
                ...available.map(
                  (v) => DropdownMenuItem(
                      value: v.id,
                      child: Text(v.label, overflow: TextOverflow.ellipsis)),
                ),
              ],
              onChanged: (v) => setState(() => _vehicleId = v),
            ),
          if (widget.selectedVehicle == null &&
              widget.existingRemoval?.carPositionId == null &&
              (widget.extraVehicle ||
                  !widget.mission.isProgrammed ||
                  _vehicleId == null)) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _label,
              readOnly: widget.readOnly,
              decoration: const InputDecoration(
                labelText: 'Description du véhicule',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _plate,
              readOnly: widget.readOnly,
              decoration: const InputDecoration(
                labelText: 'Immatriculation (facultative)',
              ),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _truckId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Camion qui emporte le véhicule',
            ),
            items: widget.mission.trucks
                .map(
                  (t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(
                      [
                        t.brand,
                        t.registration,
                      ].where((v) => (v ?? '').isNotEmpty).join(' • '),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged:
                widget.readOnly ? null : (v) => setState(() => _truckId = v),
          ),
          const SizedBox(height: 20),
          Text(
            widget.readOnly
                ? 'Photos de l’enlèvement'
                : '4 photos obligatoires',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: _angles.entries
                .map(
                  (entry) => InkWell(
                    onTap: () => _take(entry.key),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _photos.containsKey(entry.key)
                              ? SendraTheme.green
                              : Colors.grey.shade400,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        image: _photoProvider(entry.key) == null
                            ? null
                            : DecorationImage(
                                // Tuile : photo décodée à sa taille
                                // d'affichage, pas en 1 800 px.
                                image: vignette(
                                    context, _photoProvider(entry.key)!, 240),
                                fit: BoxFit.cover,
                              ),
                      ),
                      child: _photoProvider(entry.key) == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo_outlined),
                                const SizedBox(height: 6),
                                Text(entry.value),
                              ],
                            )
                          : Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: double.infinity,
                                color: Colors.black54,
                                padding: const EdgeInsets.all(5),
                                child: Text(
                                  entry.value,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          if (widget.readOnly)
            OutlinedButton.icon(
              onPressed: widget.existingRemoval?.sheetPhotoUrl == null
                  ? null
                  : () => _voirPhoto(
                      context,
                      photoReseauProvider(
                          widget.existingRemoval!.sheetPhotoUrl!),
                      'Fiche'),
              icon: const Icon(Icons.assignment_outlined),
              label: Text(widget.existingRemoval?.sheetPhotoUrl == null
                  ? 'Aucune fiche ajoutée'
                  : 'Voir la fiche'),
            )
          else ...[
            OutlinedButton.icon(
              onPressed: () async {
                final image = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                  maxWidth: 1800,
                );
                if (image == null) return;
                final fiche = await SignalerFlow.optimiser(File(image.path));
                if (mounted) setState(() => _sheet = fiche);
              },
              icon: Icon(
                _sheet != null || widget.existingRemoval?.sheetPhotoUrl != null
                    ? Icons.assignment_turned_in
                    : Icons.assignment_add,
              ),
              label: Text(
                _sheet != null || widget.existingRemoval?.sheetPhotoUrl != null
                    ? 'Fiche disponible — remplacer'
                    : 'Ajouter la fiche plus tard (facultatif)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(
                _saving
                    ? 'Enregistrement…'
                    : widget.existingRemoval == null
                        ? 'Valider l’enlèvement'
                        : 'Enregistrer les modifications',
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Photos et position du signalement d'origine (véhicule ciblé).
  Widget _ficheDuVehicule() {
    final v = widget.selectedVehicle;
    if (v != null) {
      return _FicheSignalement(
          photos: v.photos,
          latitude: v.latitude,
          longitude: v.longitude,
          lieu: v.lieu);
    }
    final r = widget.existingRemoval;
    if (r != null && r.carPositionId != null) {
      return _FicheSignalement(
          photos: r.signalementPhotos,
          latitude: r.latitude,
          longitude: r.longitude,
          lieu: r.lieu);
    }
    return const SizedBox.shrink();
  }

  ImageProvider? _photoProvider(String angle) {
    final local = _photos[angle];
    if (local != null) return FileImage(local);
    final remote = widget.existingRemoval?.photos[angle];
    return remote == null ? null : photoReseauProvider(remote);
  }
}

class _ReceptionPhotoScreen extends StatefulWidget {
  const _ReceptionPhotoScreen({
    required this.mission,
    required this.removal,
    required this.service,
    this.readOnly = false,
  });
  final Mission mission;
  final MissionRemoval removal;
  final MissionService service;

  /// Mission terminée : consultation seulement.
  final bool readOnly;
  @override
  State<_ReceptionPhotoScreen> createState() => _ReceptionPhotoScreenState();
}

class _ReceptionPhotoScreenState extends State<_ReceptionPhotoScreen> {
  final _picker = ImagePicker();
  final Map<String, File> _photos = {};
  bool _saving = false;
  static const _labels = {
    'front': 'Devant',
    'back': 'Derrière',
    'left': 'Côté gauche',
    'right': 'Côté droit',
    'sheet': 'Fiche du véhicule',
  };

  ImageProvider? _provider(String angle) {
    if (_photos[angle] != null) return FileImage(_photos[angle]!);
    final remote = widget.removal.receptionPhotos[angle];
    return remote == null ? null : photoReseauProvider(remote);
  }

  Future<void> _take(String angle) async {
    if (widget.readOnly) {
      final image = _provider(angle);
      if (image != null) _voirPhoto(context, image, _labels[angle] ?? angle);
      return;
    }
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (image == null) return;
    final photo = await SignalerFlow.optimiser(File(image.path));
    if (mounted) setState(() => _photos[angle] = photo);
  }

  Future<void> _save() async {
    if (widget.readOnly) return;
    if ({...widget.removal.receptionPhotos, ..._photos}.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les 4 angles et la fiche sont obligatoires.'),
        ),
      );
      return;
    }
    if (_photos.isEmpty && widget.removal.received) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    try {
      final mission = await widget.service.storeReception(
        widget.mission.id,
        widget.removal.id,
        _photos,
      );
      if (mounted) Navigator.pop(context, mission);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Réception · ${widget.removal.label}')),
        backgroundColor: SendraTheme.surface,
        body: ListView(
          padding:
              EdgeInsets.fromLTRB(16, 16, 16, 16 + context.margeBasSysteme),
          children: [
            if (widget.readOnly)
              const _BandeauConsultation(
                'Mission terminée : consultation seule. Touchez une photo pour l’agrandir.',
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF087F42), Color(0xFF12A85C)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Photographiez l’état du véhicule à son arrivée.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.removal.carPositionId != null)
              _FicheSignalement(
                photos: widget.removal.signalementPhotos,
                latitude: widget.removal.latitude,
                longitude: widget.removal.longitude,
                lieu: widget.removal.lieu,
              ),
            if (widget.removal.photos.isNotEmpty ||
                widget.removal.sheetPhotoUrl != null)
              _BlocPhotos(
                titre: 'Photos de l’enlèvement (équipe terrain)',
                photos: [
                  for (final e in widget.removal.photos.entries)
                    (
                      url: e.value,
                      libelle: const {
                            'front': 'Devant',
                            'back': 'Derrière',
                            'left': 'Côté gauche',
                            'right': 'Côté droit',
                          }[e.key] ??
                          e.key,
                      agent: false,
                    ),
                  if (widget.removal.sheetPhotoUrl != null)
                    (
                      url: widget.removal.sheetPhotoUrl!,
                      libelle: 'Fiche',
                      agent: false,
                    ),
                ],
              ),
            const Text('Vos photos de réception',
                style: TextStyle(
                    fontFamily: SendraTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: SendraTheme.ink)),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: _labels.entries.map((entry) {
                final image = _provider(entry.key);
                return InkWell(
                  onTap: () => _take(entry.key),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: image == null
                            ? const Color(0xFFD6E3DB)
                            : SendraTheme.green,
                        width: 1.5,
                      ),
                      image: image == null
                          ? null
                          : DecorationImage(
                              image: vignette(context, image, 240),
                              fit: BoxFit.cover),
                    ),
                    child: image == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_a_photo_outlined,
                                color: SendraTheme.green,
                              ),
                              const SizedBox(height: 7),
                              Text(entry.value, textAlign: TextAlign.center),
                            ],
                          )
                        : Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(14),
                                ),
                              ),
                              child: Text(
                                entry.value,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            if (!widget.readOnly)
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  _saving
                      ? 'Enregistrement…'
                      : widget.removal.received
                          ? 'Enregistrer les modifications'
                          : 'Valider la réception',
                ),
              ),
          ],
        ),
      );
}

class _TruckDestinationSheet extends StatefulWidget {
  const _TruckDestinationSheet({
    required this.mission,
    required this.truck,
    required this.service,
  });
  final Mission mission;
  final MissionTruck truck;
  final MissionService service;
  @override
  State<_TruckDestinationSheet> createState() => _TruckDestinationSheetState();
}

class _TruckDestinationSheetState extends State<_TruckDestinationSheet> {
  String? _pound;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _pound = widget.truck.destinationPoundName;
  }

  Future<void> _save() async {
    if (_pound == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez la fourrière du camion.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await widget.service.setTruckDestination(
        widget.mission.id,
        widget.truck.id,
        _pound!,
      );
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        // Au-dessus du clavier quand il est ouvert, sinon au-dessus de la barre
        // de navigation du téléphone.
        padding: EdgeInsets.fromLTRB(
          22,
          12,
          22,
          20 +
              (MediaQuery.viewInsetsOf(context).bottom >
                      MediaQuery.viewPaddingOf(context).bottom
                  ? MediaQuery.viewInsetsOf(context).bottom
                  : MediaQuery.viewPaddingOf(context).bottom),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4DDD7),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF087F42), Color(0xFF12A85C)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.local_shipping_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [
                              widget.truck.brand,
                              widget.truck.registration,
                            ].where((v) => (v ?? '').isNotEmpty).join(' • '),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'Destination du camion',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Choisir la fourrière',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cette destination s’appliquera à toutes les voitures associées à ce camion.',
                style: TextStyle(color: SendraTheme.muted),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _pound,
                isExpanded: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.local_parking,
                    color: SendraTheme.green,
                  ),
                  labelText: 'Fourrière de destination',
                  filled: true,
                  fillColor: const Color(0xFFF3F8F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: widget.mission.pounds
                    .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setState(() => _pound = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    _saving ? 'Enregistrement…' : 'Enregistrer la destination',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _BandeauConsultation extends StatelessWidget {
  const _BandeauConsultation(this.texte);
  final String texte;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF1ED),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFB7DEC4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_rounded, color: SendraTheme.forest, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(texte,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: SendraTheme.forest)),
            ),
          ],
        ),
      );
}
