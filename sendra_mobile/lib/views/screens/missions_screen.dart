import 'package:flutter/material.dart';
import 'package:walletium/models/mission.dart';
import 'package:walletium/services/mission_service.dart';
import 'package:walletium/utils/sendra_theme.dart';
import 'package:walletium/views/screens/mission_details_screen.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});
  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  final _service = MissionService();
  late Future<List<Mission>> _missions;
  String _typeFilter = 'all';
  String _statusFilter = 'all';
  bool _showHistory = false;

  String _missionStage(Mission mission, DateTime now) {
    if (mission.completed || mission.status == 'terminee') return 'terminee';
    if (mission.checkedIn ||
        mission.receptionCheckedIn ||
        mission.status == 'en_cours' ||
        mission.status == 'en_reception' ||
        (mission.scheduledAt != null && mission.scheduledAt!.isBefore(now))) {
      return 'en_cours';
    }
    return 'a_venir';
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Date à préciser';
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} à ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _missions = _service.list();
  Future<void> _refresh() async {
    setState(_reload);
    await _missions;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_showHistory ? 'Historique des missions' : 'Missions'),
      actions: [
        IconButton(
          onPressed: () => setState(_reload),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<Mission>>(
      future: _missions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return _StateMessage(
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
            onRetry: () => setState(_reload),
          );
        final missions = snapshot.data ?? const [];
        if (missions.isEmpty)
          return _StateMessage(
            message: 'Vos prochaines missions apparaîtront ici.',
            onRetry: () => setState(_reload),
          );
        final now = DateTime.now();
        final visible =
            missions
                .where(
                  (mission) =>
                      // L'historique montre toutes les missions, ouvertes
                      // comprises, avec leur état.
                      (_showHistory ||
                          _missionStage(mission, now) != 'terminee') &&
                      (_typeFilter == 'all' ||
                          (_typeFilter == 'programmee' &&
                              mission.isProgrammed) ||
                          (_typeFilter == 'ponctuelle' &&
                              !mission.isProgrammed)) &&
                      (_showHistory ||
                          _statusFilter == 'all' ||
                          _missionStage(mission, now) == _statusFilter),
                )
                .toList()
              ..sort((a, b) {
                if (_showHistory) {
                  if (a.scheduledAt == null)
                    return b.scheduledAt == null ? 0 : 1;
                  if (b.scheduledAt == null) return -1;
                  return b.scheduledAt!.compareTo(a.scheduledAt!);
                }
                if (a.scheduledAt == null) return b.scheduledAt == null ? 0 : 1;
                if (b.scheduledAt == null) return -1;
                final aDistance = a.scheduledAt!
                    .difference(now)
                    .inSeconds
                    .abs();
                final bDistance = b.scheduledAt!
                    .difference(now)
                    .inSeconds
                    .abs();
                return aDistance.compareTo(bDistance);
              });
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                children: [
                  _filterChip(
                      'all',
                      'Toutes',
                      Icons.view_agenda_outlined,
                      const Color(0xFF52606D),
                    ),
                  _filterChip(
                      'programmee',
                      'Programmées',
                      Icons.event_available_outlined,
                      SendraTheme.green,
                    ),
                  _filterChip(
                      'ponctuelle',
                      'Ponctuelles',
                      Icons.flash_on_outlined,
                      SendraTheme.amber,
                    ),
                ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_showHistory)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _statusChip('all', 'Toutes les actives'),
                          _statusChip('a_venir', 'À venir'),
                          _statusChip('en_cours', 'En cours'),
                        ],
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text(
                        'Toutes les missions, ouvertes et terminées',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  // Bascule compacte (l'ancien grand bouton prenait une
                  // ligne entière au-dessus de la liste).
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        _showHistory = !_showHistory;
                        _statusFilter = 'all';
                      }),
                      icon: Icon(_showHistory
                          ? Icons.arrow_back_rounded
                          : Icons.history_rounded),
                      label: Text(_showHistory
                          ? 'Missions actives'
                          : 'Voir l’historique'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Text(
                        _showHistory
                            ? 'Aucune mission dans cet historique.'
                            : 'Aucune mission en cours ou à venir dans ce filtre.',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final mission = visible[index];
                          final hasPointed = mission.isReceiver
                              ? mission.receptionCheckedIn
                              : mission.checkedIn;
                          final etat = _etat(mission, now);
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(SendraTheme.radius),
                              side: const BorderSide(color: SendraTheme.border),
                            ),
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(SendraTheme.radius),
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MissionDetailsScreen(
                                      missionId: mission.id,
                                      initialMission: mission,
                                    ),
                                  ),
                                );
                                if (mounted) setState(_reload);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            mission.code.isNotEmpty
                                                ? mission.code
                                                : mission.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: SendraTheme.ink,
                                            ),
                                          ),
                                        ),
                                        _Badge(
                                          label: etat.$1,
                                          color: etat.$2,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _Badge(
                                          label: mission.isReceiver
                                              ? 'Réception en fourrière'
                                              : 'Équipe terrain',
                                          color: mission.isReceiver
                                              ? const Color(0xFF6847B8)
                                              : const Color(0xFF1769AA),
                                        ),
                                        _Badge(
                                          label: mission.isProgrammed
                                              ? 'Programmée'
                                              : 'Ponctuelle',
                                          color: mission.isProgrammed
                                              ? SendraTheme.green
                                              : SendraTheme.amber,
                                        ),
                                        if (mission.readOnly)
                                          const _Badge(
                                            label: 'Lecture seule',
                                            color: SendraTheme.muted,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _Info(
                                      Icons.event_outlined,
                                      _dateLabel(mission.scheduledAt),
                                    ),
                                    if (mission.address.isNotEmpty)
                                      _Info(
                                        Icons.place_outlined,
                                        mission.address,
                                      ),
                                    if (mission.isReceiver &&
                                        mission.removalValidated &&
                                        mission.vehicles.any((v) =>
                                            (v.nonRemovalReason ?? '')
                                                .trim()
                                                .isNotEmpty))
                                      _Info(
                                        Icons.report_problem_outlined,
                                        '${mission.vehicles.where((v) => (v.nonRemovalReason ?? '').trim().isNotEmpty).length} véhicule(s) non enlevé(s) — voir les motifs',
                                      ),
                                    _Info(
                                      hasPointed
                                          ? Icons.check_circle_outline
                                          : Icons.my_location,
                                      mission.completed
                                          ? 'Mission terminée'
                                          : hasPointed
                                          ? mission.isReceiver
                                                ? '${mission.removals.where((r) => r.received).length}/${mission.removals.length} réceptionné(s)'
                                                : '${mission.removals.length} enlèvement(s)'
                                          : mission.isReceiver &&
                                                !mission.removalValidated
                                          ? 'En attente de l’enlèvement'
                                          : 'Ouvrir pour pointer',
                                    ),
                                    const Align(
                                      alignment: Alignment.centerRight,
                                      child: Icon(Icons.chevron_right),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    ),
  );

  /// État affiché d'une mission (historique compris).
  (String, Color) _etat(Mission mission, DateTime now) {
    if (mission.completed || mission.status == 'terminee') {
      return ('Terminée', SendraTheme.green);
    }
    if (mission.status == 'annulee') return ('Annulée', SendraTheme.statusSignale);
    if (mission.removalValidated || mission.status == 'en_reception') {
      return ('En réception', const Color(0xFF6847B8));
    }
    if (_missionStage(mission, now) == 'en_cours') {
      return ('En cours', SendraTheme.statusEnCours);
    }
    return ('À venir', const Color(0xFF1769AA));
  }

  Widget _filterChip(String value, String label, IconData icon, Color color) {
    final selected = _typeFilter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => _typeFilter = value),
        label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
        labelStyle: TextStyle(
          color: selected ? Colors.white : color,
          fontWeight: FontWeight.w700,
        ),
        selectedColor: color,
        backgroundColor: color.withValues(alpha: .08),
        side: BorderSide(color: color.withValues(alpha: .25)),
        showCheckmark: false,
      ),
    );
  }

  Widget _statusChip(String value, String label) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        onSelected: (_) => setState(() => _statusFilter = value),
        label: Text(label),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        Icon(icon, size: 18, color: SendraTheme.muted),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 54,
            color: SendraTheme.muted,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );
}
