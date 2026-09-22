import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:walletium/models/mission.dart';
import 'package:walletium/services/mission_service.dart';
import 'package:walletium/utils/sendra_theme.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  final _service = MissionService();
  late Future<List<Mission>> _missions;
  int? _checkingIn;

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

  Future<void> _checkIn(Mission mission) async {
    setState(() => _checkingIn = mission.id);
    try {
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
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _service.checkIn(
        mission.id,
        position.latitude,
        position.longitude,
        position.accuracy,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Présence confirmée. Mission déverrouillée.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _checkingIn = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Missions'),
          actions: [
            IconButton(
              onPressed: () => setState(_reload),
              tooltip: 'Actualiser',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: FutureBuilder<List<Mission>>(
          future: _missions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _MessageState(
                icon: Icons.cloud_off_outlined,
                title: 'Missions indisponibles',
                message:
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                onRetry: () => setState(_reload),
              );
            }
            final missions = snapshot.data ?? const [];
            if (missions.isEmpty) {
              return _MessageState(
                icon: Icons.assignment_outlined,
                title: 'Aucune mission',
                message: 'Vos prochaines missions apparaîtront ici.',
                onRetry: () => setState(_reload),
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                itemCount: missions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) => _MissionCard(
                  mission: missions[index],
                  checkingIn: _checkingIn == missions[index].id,
                  onCheckIn: () => _checkIn(missions[index]),
                ),
              ),
            );
          },
        ),
      );
}

class _MissionCard extends StatelessWidget {
  const _MissionCard(
      {required this.mission,
      required this.checkingIn,
      required this.onCheckIn});
  final Mission mission;
  final bool checkingIn;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    final date = mission.scheduledAt;
    final dateLabel = date == null
        ? 'Date à confirmer'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(mission.title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            _Badge(
              label: mission.isProgrammed ? 'Programmée' : 'Brute',
              color:
                  mission.isProgrammed ? SendraTheme.green : SendraTheme.amber,
            ),
          ]),
          const SizedBox(height: 14),
          _Info(icon: Icons.event_outlined, text: dateLabel),
          if (mission.address.isNotEmpty)
            _Info(icon: Icons.place_outlined, text: mission.address),
          if ((mission.trailerBrand ?? '').isNotEmpty ||
              (mission.trailerPlate ?? '').isNotEmpty)
            _Info(
              icon: Icons.local_shipping_outlined,
              text: [mission.trailerBrand, mission.trailerPlate]
                  .where((value) => value?.isNotEmpty ?? false)
                  .join(' • '),
            ),
          if (mission.pounds.isNotEmpty)
            _Info(
              icon: Icons.local_parking_outlined,
              text: 'Fourrières disponibles : ${mission.pounds.join(', ')}',
            ),
          const SizedBox(height: 12),
          if (!mission.checkedIn) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Pointez sur le lieu de mission (rayon de ${mission.checkInRadiusMeters.round()} m) pour afficher les véhicules.',
                style: const TextStyle(color: Color(0xFF825A08), fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: checkingIn ? null : onCheckIn,
                icon: checkingIn
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location),
                label: Text(checkingIn ? 'Vérification…' : 'Pointer'),
              ),
            ),
          ] else ...[
            const Divider(height: 24),
            const Row(children: [
              Icon(Icons.check_circle, color: SendraTheme.green, size: 19),
              SizedBox(width: 7),
              Text('Présence confirmée',
                  style: TextStyle(
                      color: SendraTheme.green, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            Text(
                mission.vehicles.isEmpty
                    ? 'Aucun véhicule communiqué.'
                    : 'Véhicules à emporter',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            ...mission.vehicles.map((vehicle) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE1F3E8),
                    child: Icon(Icons.directions_car, color: SendraTheme.green),
                  ),
                  title: Text(vehicle.label),
                  subtitle: vehicle.plate == null ? null : Text(vehicle.plate!),
                )),
          ],
        ]),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 19, color: SendraTheme.muted),
          const SizedBox(width: 8),
          Expanded(
              child:
                  Text(text, style: const TextStyle(color: SendraTheme.muted))),
        ]),
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
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

class _MessageState extends StatelessWidget {
  const _MessageState(
      {required this.icon,
      required this.title,
      required this.message,
      required this.onRetry});
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 54, color: SendraTheme.muted),
            const SizedBox(height: 14),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: SendraTheme.muted)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer')),
          ]),
        ),
      );
}
