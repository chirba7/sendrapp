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
  String _filter = 'all';
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
        appBar: AppBar(title: const Text('Missions'), actions: [
          IconButton(
              onPressed: () => setState(_reload),
              icon: const Icon(Icons.refresh))
        ]),
        body: FutureBuilder<List<Mission>>(
          future: _missions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return _StateMessage(
                  message:
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                  onRetry: () => setState(_reload));
            final missions = snapshot.data ?? const [];
            if (missions.isEmpty)
              return _StateMessage(
                  message: 'Vos prochaines missions apparaîtront ici.',
                  onRetry: () => setState(_reload));
            final visible = missions
                .where((mission) =>
                    _filter == 'all' ||
                    (_filter == 'programmee' && mission.isProgrammed) ||
                    (_filter == 'directe' && !mission.isProgrammed))
                .toList();
            return Column(children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(children: [
                  _filterChip('all', 'Toutes', Icons.view_agenda_outlined,
                      const Color(0xFF52606D)),
                  _filterChip('programmee', 'Programmées',
                      Icons.event_available_outlined, SendraTheme.green),
                  _filterChip('directe', 'Directes', Icons.flash_on_outlined,
                      SendraTheme.amber),
                ]),
              ),
              Expanded(
                  child: visible.isEmpty
                      ? const Center(
                          child: Text('Aucune mission dans ce filtre.'))
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                            itemCount: visible.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final mission = visible[index];
                              final hasPointed = mission.isReceiver
                                  ? mission.receptionCheckedIn
                                  : mission.checkedIn;
                              return Card(
                                  child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () async {
                                        await Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    MissionDetailsScreen(
                                                        missionId: mission.id,
                                                        initialMission:
                                                            mission)));
                                        if (mounted) setState(_reload);
                                      },
                                      child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(children: [
                                                  Expanded(
                                                      child: Text(
                                                          mission.code
                                                                  .isNotEmpty
                                                              ? mission.code
                                                              : mission.title,
                                                          style: const TextStyle(
                                                              fontSize: 17,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700))),
                                                  _Badge(
                                                      label: mission.completed
                                                          ? 'Terminée'
                                                          : mission.isReceiver
                                                              ? 'Réception'
                                                              : mission
                                                                      .isProgrammed
                                                                  ? 'Programmée'
                                                                  : 'Directe',
                                                      color: mission
                                                              .isProgrammed
                                                          ? SendraTheme.green
                                                          : SendraTheme.amber)
                                                ]),
                                                const SizedBox(height: 12),
                                                if (mission.address.isNotEmpty)
                                                  _Info(Icons.place_outlined,
                                                      mission.address),
                                                _Info(
                                                    hasPointed
                                                        ? Icons
                                                            .check_circle_outline
                                                        : Icons.my_location,
                                                    mission.completed
                                                        ? 'Mission terminée'
                                                        : hasPointed
                                                            ? mission.isReceiver
                                                                ? '${mission.removals.where((r) => r.received).length}/${mission.removals.length} réceptionné(s)'
                                                                : '${mission.removals.length} enlèvement(s)'
                                                            : mission.isReceiver &&
                                                                    !mission
                                                                        .removalValidated
                                                                ? 'En attente de l’enlèvement'
                                                                : 'Ouvrir pour pointer'),
                                                const Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Icon(
                                                        Icons.chevron_right)),
                                              ]))));
                            },
                          ))),
            ]);
          },
        ),
      );

  Widget _filterChip(String value, String label, IconData icon, Color color) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        avatar: Icon(icon, size: 18, color: selected ? Colors.white : color),
        label: Text(label),
        labelStyle: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w700),
        selectedColor: color,
        backgroundColor: color.withValues(alpha: .08),
        side: BorderSide(color: color.withValues(alpha: .25)),
        showCheckmark: false,
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
      child: Row(children: [
        Icon(icon, size: 18, color: SendraTheme.muted),
        const SizedBox(width: 8),
        Expanded(child: Text(text))
      ]));
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
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)));
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.assignment_outlined,
                size: 54, color: SendraTheme.muted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'))
          ])));
}
