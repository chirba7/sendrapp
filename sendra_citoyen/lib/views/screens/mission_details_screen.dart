import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:walletium/models/mission.dart';
import 'package:walletium/services/mission_service.dart';
import 'package:walletium/utils/sendra_theme.dart';

class MissionDetailsScreen extends StatefulWidget {
  const MissionDetailsScreen(
      {super.key, required this.missionId, required this.initialMission});
  final int missionId;
  final Mission initialMission;
  @override
  State<MissionDetailsScreen> createState() => _MissionDetailsScreenState();
}

class _MissionDetailsScreenState extends State<MissionDetailsScreen> {
  final _service = MissionService();
  late Mission _mission = widget.initialMission;
  bool _busy = false;

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

  Future<void> _checkIn() async {
    setState(() => _busy = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled())
        throw Exception('Activez la localisation du téléphone pour pointer.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        throw Exception(
            'L’autorisation de localisation est nécessaire pour pointer.');
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final mission = await _service.checkIn(_mission.id, position.latitude,
          position.longitude, position.accuracy);
      if (mounted) setState(() => _mission = mission);
    } catch (e) {
      if (mounted) _error(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkInReception() async {
    setState(() => _busy = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Activez la localisation pour pointer.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('L’autorisation de localisation est nécessaire.');
      }
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final mission = await _service.checkInReception(
          _mission.id, position.latitude, position.longitude);
      if (mounted) setState(() => _mission = mission);
    } catch (e) {
      if (mounted) _error(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _validateRemoval() async {
    setState(() => _busy = true);
    try {
      final mission = await _service.validateRemoval(_mission.id);
      if (mounted) setState(() => _mission = mission);
    } catch (e) {
      if (mounted) _error(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeMission() async {
    setState(() => _busy = true);
    try {
      final mission = await _service.completeMission(_mission.id);
      if (mounted) setState(() => _mission = mission);
    } catch (e) {
      if (mounted) _error(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _error(Object error) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', ''))));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(_mission.code.isEmpty ? 'Mission' : _mission.code),
            actions: [
              IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))
            ]),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              _nextActionCard(),
              _section('Informations', [
                _line(
                    Icons.assignment_outlined,
                    _mission.isProgrammed
                        ? 'Mission programmée'
                        : 'Mission directe'),
                if (_mission.address.isNotEmpty)
                  _line(Icons.place_outlined, _mission.address),
                if ((_mission.providerName ?? '').isNotEmpty)
                  _line(Icons.business_outlined, _mission.providerName!),
              ]),
              if (_mission.isReceiver && !_mission.removalValidated) ...[
                _section('Réception en attente', [
                  const Icon(Icons.hourglass_top_rounded,
                      color: SendraTheme.amber, size: 38),
                  const SizedBox(height: 10),
                  const Text(
                      'L’équipe terrain doit d’abord valider la phase d’enlèvement.'),
                ]),
              ] else if (!(_mission.isReceiver
                  ? _mission.receptionCheckedIn
                  : _mission.checkedIn)) ...[
                _section('Pointage obligatoire', [
                  Text(_mission.isReceiver
                      ? 'Pointez au poste ${_mission.receptionPoundName ?? 'de fourrière'} pour commencer la réception.'
                      : 'Votre position sera comparée à la zone de la commune avant de déverrouiller la mission.'),
                  const SizedBox(height: 14),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                          onPressed: _busy
                              ? null
                              : (_mission.isReceiver
                                  ? _checkInReception
                                  : _checkIn),
                          icon: _busy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location),
                          label: Text(_busy ? 'Vérification…' : 'Pointer')))
                ]),
              ] else ...[
                _section(
                    'Camions',
                    _mission.trucks.isEmpty
                        ? [const Text('Aucun camion renseigné.')]
                        : _mission.trucks
                            .map((t) => ListTile(
                                onTap: _mission.isReceiver ||
                                        _mission.pounds.isEmpty
                                    ? null
                                    : () => _openTruckDestination(t),
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                    child: Icon(Icons.local_shipping_outlined)),
                                title: Text([t.brand, t.registration]
                                    .where((v) => (v ?? '').isNotEmpty)
                                    .join(' • ')),
                                subtitle: Text([
                                  if ((t.driverName ?? '').isNotEmpty)
                                    t.driverName!,
                                  t.destinationPoundName ??
                                      'Fourrière à préciser'
                                ].join(' • ')),
                                trailing: const Icon(Icons.edit_outlined)))
                            .toList()),
                _section(
                    'Fourrières prêtes',
                    _mission.pounds.isEmpty
                        ? [const Text('Aucune fourrière renseignée.')]
                        : _mission.pounds
                            .map((p) => _line(Icons.local_parking_outlined, p))
                            .toList()),
                if (_mission.vehicles.isNotEmpty && !_mission.isReceiver)
                  _section(
                      _mission.isProgrammed
                          ? 'Véhicules programmés'
                          : 'Véhicules ciblés',
                      _mission.vehicles.map((v) {
                        final matches = _mission.removals
                            .where((r) => r.carPositionId == v.id)
                            .toList();
                        final removal = matches.isEmpty ? null : matches.first;
                        final done = removal != null;
                        return ListTile(
                            onTap: done
                                ? () => _openRemoval(existingRemoval: removal)
                                : (_mission.trucks.isEmpty
                                    ? null
                                    : () => _openRemoval(vehicle: v)),
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                                done
                                    ? Icons.check_circle
                                    : Icons.directions_car,
                                color: done ? SendraTheme.green : null),
                            title: Text(v.label),
                            subtitle: v.plate == null ? null : Text(v.plate!),
                            trailing: done
                                ? Icon(removal.sheetPhotoUrl == null
                                    ? Icons.assignment_add
                                    : Icons.assignment_turned_in)
                                : const Icon(Icons.add_a_photo_outlined));
                      }).toList()),
                _section('Enlèvements (${_mission.removals.length})', [
                  if (_mission.removals.isEmpty)
                    const Text('Aucun véhicule photographié pour le moment.'),
                  ..._mission.removals.map((r) => ListTile(
                      onTap: () => _mission.isReceiver
                          ? _openReception(r)
                          : _openRemoval(existingRemoval: r),
                      contentPadding: EdgeInsets.zero,
                      leading:
                          const CircleAvatar(child: Icon(Icons.directions_car)),
                      title: Text(r.label),
                      subtitle: Text(_removalSubtitle(r)),
                      trailing: _mission.isReceiver
                          ? Icon(
                              r.received
                                  ? Icons.check_circle
                                  : Icons.add_a_photo_outlined,
                              color: r.received ? SendraTheme.green : null)
                          : const Icon(Icons.chevron_right))),
                  const SizedBox(height: 10),
                  if (_mission.trucks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        'Un camion doit être ajouté par l’administration avant de commencer un enlèvement.',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  if (!_mission.isReceiver)
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                            onPressed: _mission.trucks.isEmpty
                                ? null
                                : () => _openRemoval(extraVehicle: true),
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: Text(_mission.isProgrammed
                                ? 'Ajouter un autre véhicule'
                                : 'Nouvel enlèvement'))),
                ]),
                _section(
                    _mission.isReceiver
                        ? 'Finaliser la réception'
                        : 'Fin de l’enlèvement',
                    [
                      Text(_mission.isReceiver
                          ? '${_mission.removals.where((r) => r.received).length}/${_mission.removals.length} véhicule(s) réceptionné(s).'
                          : 'Validez lorsque toutes les voitures ont été photographiées et associées à leur camion.'),
                      const SizedBox(height: 12),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                              onPressed: _busy ||
                                      _mission.completed ||
                                      (!_mission.isReceiver &&
                                          _mission.removalValidated)
                                  ? null
                                  : (_mission.isReceiver
                                      ? _completeMission
                                      : _validateRemoval),
                              icon: Icon(_mission.completed
                                  ? Icons.verified
                                  : Icons.task_alt),
                              label: Text(_mission.completed
                                  ? 'Mission terminée'
                                  : _mission.isReceiver
                                      ? 'Valider et terminer la mission'
                                      : _mission.removalValidated
                                          ? 'Enlèvement validé'
                                          : 'Valider l’enlèvement')))
                    ]),
              ],
            ]),
      );

  Widget _nextActionCard() {
    late final String title;
    late final String message;
    late final IconData icon;
    late final Color color;
    if (_mission.completed) {
      title = 'Mission terminée';
      message = 'Toutes les étapes ont été validées.';
      icon = Icons.verified_rounded;
      color = SendraTheme.green;
    } else if (_mission.isReceiver && !_mission.removalValidated) {
      title = 'En attente de l’équipe terrain';
      message =
          'La réception sera disponible après validation de l’enlèvement.';
      icon = Icons.hourglass_top_rounded;
      color = const Color(0xFF7C4DFF);
    } else if (!(_mission.isReceiver
        ? _mission.receptionCheckedIn
        : _mission.checkedIn)) {
      title = 'Prochaine action : pointer';
      message = _mission.isReceiver
          ? 'Rendez-vous à ${_mission.receptionPoundName ?? 'la fourrière'}.'
          : 'Rendez-vous dans la zone de la mission.';
      icon = Icons.my_location_rounded;
      color = const Color(0xFF1976D2);
    } else if (_mission.isReceiver) {
      final left = _mission.removals.where((r) => !r.received).length;
      title =
          left == 0 ? 'Prête à être terminée' : 'Réceptionner les véhicules';
      message = left == 0
          ? 'Validez la fin de mission.'
          : '$left véhicule(s) restent à photographier.';
      icon = Icons.warehouse_outlined;
      color = const Color(0xFF7C4DFF);
    } else if (_mission.removalValidated) {
      title = 'Enlèvement transmis';
      message = 'Le réceptionniste peut poursuivre la mission.';
      icon = Icons.outbox_rounded;
      color = SendraTheme.green;
    } else {
      title = 'Photographier et affecter';
      message = 'Complétez les véhicules, les camions et leurs destinations.';
      icon = Icons.add_a_photo_outlined;
      color = SendraTheme.amber;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: .76)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: .22),
              blurRadius: 18,
              offset: const Offset(0, 7))
        ],
      ),
      child: Row(children: [
        Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(17)),
            child: Icon(icon, color: Colors.white, size: 29)),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(message,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .88), height: 1.3)),
        ])),
      ]),
    );
  }

  ({Color color, IconData icon, Color background}) _sectionTone(String title) {
    if (title.startsWith('Camions'))
      return (
        color: const Color(0xFF1976D2),
        icon: Icons.local_shipping_outlined,
        background: const Color(0xFFF7FAFF)
      );
    if (title.startsWith('Fourrières'))
      return (
        color: const Color(0xFF7C4DFF),
        icon: Icons.warehouse_outlined,
        background: const Color(0xFFFBF9FF)
      );
    if (title.startsWith('Véhicules'))
      return (
        color: SendraTheme.amber,
        icon: Icons.directions_car_outlined,
        background: const Color(0xFFFFFCF5)
      );
    if (title.startsWith('Enlèvements'))
      return (
        color: const Color(0xFF00897B),
        icon: Icons.photo_camera_outlined,
        background: const Color(0xFFF5FCFB)
      );
    if (title.contains('réception') || title.contains('Réception'))
      return (
        color: const Color(0xFF7C4DFF),
        icon: Icons.inventory_2_outlined,
        background: const Color(0xFFFBF9FF)
      );
    if (title.contains('Pointage'))
      return (
        color: const Color(0xFF1976D2),
        icon: Icons.my_location,
        background: const Color(0xFFF7FAFF)
      );
    if (title.contains('Fin'))
      return (
        color: SendraTheme.green,
        icon: Icons.task_alt,
        background: const Color(0xFFF6FCF8)
      );
    return (
      color: SendraTheme.green,
      icon: Icons.info_outline,
      background: const Color(0xFFFCFEFD)
    );
  }

  Widget _section(String title, List<Widget> children) {
    final tone = _sectionTone(title);
    return Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: tone.background,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: tone.color.withValues(alpha: .18))),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: tone.color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(13)),
                    child: Icon(tone.icon, color: tone.color, size: 22)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)))
              ]),
              const SizedBox(height: 12),
              ...children
            ])));
  }

  Widget _line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 19, color: SendraTheme.muted),
        const SizedBox(width: 9),
        Expanded(child: Text(text))
      ]));

  String _removalSubtitle(MissionRemoval removal) {
    final trucks = _mission.trucks.where((t) => t.id == removal.truckId);
    final truck = trucks.isEmpty ? null : trucks.first;
    return [
      if ((removal.plate ?? '').isNotEmpty) removal.plate!,
      if (truck != null)
        'Camion ${truck.registration ?? truck.brand ?? truck.id}',
      if (truck?.destinationPoundName != null)
        truck!.destinationPoundName!
      else
        'Fourrière à préciser sur le camion',
      removal.sheetPhotoUrl == null
          ? 'Fiche facultative à ajouter'
          : 'Fiche ajoutée',
    ].join(' • ');
  }

  Future<void> _openRemoval(
      {MissionVehicle? vehicle,
      MissionRemoval? existingRemoval,
      bool extraVehicle = false}) async {
    final result = await Navigator.push<Mission>(
        context,
        MaterialPageRoute(
            builder: (_) => _RemovalScreen(
                mission: _mission,
                service: _service,
                selectedVehicle: vehicle,
                existingRemoval: existingRemoval,
                extraVehicle: extraVehicle)));
    if (result != null && mounted) setState(() => _mission = result);
  }

  Future<void> _openTruckDestination(MissionTruck truck) async {
    final result = await showModalBottomSheet<Mission>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => _TruckDestinationSheet(
            mission: _mission, truck: truck, service: _service));
    if (result != null && mounted) setState(() => _mission = result);
  }

  Future<void> _openReception(MissionRemoval removal) async {
    final result = await Navigator.push<Mission>(
        context,
        MaterialPageRoute(
            builder: (_) => _ReceptionPhotoScreen(
                mission: _mission, removal: removal, service: _service)));
    if (result != null && mounted) setState(() => _mission = result);
  }
}

class _RemovalScreen extends StatefulWidget {
  const _RemovalScreen(
      {required this.mission,
      required this.service,
      required this.extraVehicle,
      this.selectedVehicle,
      this.existingRemoval});
  final Mission mission;
  final MissionService service;
  final MissionVehicle? selectedVehicle;
  final MissionRemoval? existingRemoval;
  final bool extraVehicle;
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
    'right': 'Côté droit'
  };
  @override
  void initState() {
    super.initState();
    _vehicleId =
        widget.selectedVehicle?.id ?? widget.existingRemoval?.carPositionId;
    _truckId = widget.existingRemoval?.truckId;
    _label.text = widget.existingRemoval?.label ?? '';
    _plate.text = widget.existingRemoval?.plate ?? '';
    if (_truckId == null && widget.mission.trucks.length == 1)
      _truckId = widget.mission.trucks.first.id;
  }

  @override
  void dispose() {
    _label.dispose();
    _plate.dispose();
    super.dispose();
  }

  Future<void> _take(String angle) async {
    final file = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 85, maxWidth: 1800);
    if (file != null) setState(() => _photos[angle] = File(file.path));
  }

  Future<void> _save() async {
    if (_truckId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sélectionnez le camion qui emporte le véhicule.')));
      return;
    }
    final existingPhotos = widget.existingRemoval?.photos ?? const {};
    if ({...existingPhotos, ..._photos}.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Les 4 vues du véhicule sont obligatoires.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final result = widget.existingRemoval == null
          ? await widget.service.createRemoval(widget.mission.id,
              carPositionId: _vehicleId,
              truckId: _truckId,
              vehicleLabel: _label.text.trim(),
              plate: _plate.text.trim(),
              photos: _photos,
              sheet: _sheet)
          : await widget.service.updateRemoval(
              widget.mission.id, widget.existingRemoval!.id,
              truckId: _truckId!,
              vehicleLabel: _label.text.trim(),
              plate: _plate.text.trim(),
              photos: _photos,
              sheet: _sheet);
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.mission.vehicles
        .where(
            (v) => !widget.mission.removals.any((r) => r.carPositionId == v.id))
        .toList();
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.existingRemoval == null
                ? 'Nouvel enlèvement'
                : 'Détail de l’enlèvement')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          if (widget.selectedVehicle != null ||
              widget.existingRemoval?.carPositionId != null)
            ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.directions_car)),
                title: Text(widget.selectedVehicle?.label ??
                    widget.existingRemoval!.label),
                subtitle: (widget.selectedVehicle?.plate ??
                            widget.existingRemoval?.plate) ==
                        null
                    ? null
                    : Text(widget.selectedVehicle?.plate ??
                        widget.existingRemoval!.plate!))
          else if (widget.mission.isProgrammed && !widget.extraVehicle)
            DropdownButtonFormField<int?>(
                value: _vehicleId,
                decoration: const InputDecoration(labelText: 'Véhicule'),
                items: [
                  ...available.map((v) =>
                      DropdownMenuItem(value: v.id, child: Text(v.label)))
                ],
                onChanged: (v) => setState(() => _vehicleId = v)),
          if (widget.selectedVehicle == null &&
              widget.existingRemoval?.carPositionId == null &&
              (widget.extraVehicle ||
                  !widget.mission.isProgrammed ||
                  _vehicleId == null)) ...[
            const SizedBox(height: 12),
            TextField(
                controller: _label,
                decoration: const InputDecoration(
                    labelText: 'Description du véhicule')),
            const SizedBox(height: 12),
            TextField(
                controller: _plate,
                decoration: const InputDecoration(
                    labelText: 'Immatriculation (facultative)'))
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
              value: _truckId,
              decoration: const InputDecoration(
                  labelText: 'Camion qui emporte le véhicule'),
              items: widget.mission.trucks
                  .map((t) => DropdownMenuItem(
                      value: t.id,
                      child: Text([t.brand, t.registration]
                          .where((v) => (v ?? '').isNotEmpty)
                          .join(' • '))))
                  .toList(),
              onChanged: (v) => setState(() => _truckId = v)),
          const SizedBox(height: 20),
          const Text('4 photos obligatoires',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: _angles.entries
                  .map((entry) => InkWell(
                      onTap: () => _take(entry.key),
                      child: Container(
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: _photos.containsKey(entry.key)
                                      ? SendraTheme.green
                                      : Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                              image: _photoProvider(entry.key) == null
                                  ? null
                                  : DecorationImage(
                                      image: _photoProvider(entry.key)!,
                                      fit: BoxFit.cover)),
                          child: _photoProvider(entry.key) == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      const Icon(Icons.add_a_photo_outlined),
                                      const SizedBox(height: 6),
                                      Text(entry.value)
                                    ])
                              : Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                      width: double.infinity,
                                      color: Colors.black54,
                                      padding: const EdgeInsets.all(5),
                                      child: Text(entry.value,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: Colors.white)))))))
                  .toList()),
          const SizedBox(height: 16),
          OutlinedButton.icon(
              onPressed: () async {
                final image = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                    maxWidth: 1800);
                if (image != null) setState(() => _sheet = File(image.path));
              },
              icon: Icon(_sheet != null ||
                      widget.existingRemoval?.sheetPhotoUrl != null
                  ? Icons.assignment_turned_in
                  : Icons.assignment_add),
              label: Text(_sheet != null ||
                      widget.existingRemoval?.sheetPhotoUrl != null
                  ? 'Fiche disponible — remplacer'
                  : 'Ajouter la fiche plus tard (facultatif)')),
          const SizedBox(height: 20),
          ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(_saving
                  ? 'Enregistrement…'
                  : widget.existingRemoval == null
                      ? 'Valider l’enlèvement'
                      : 'Enregistrer les modifications')),
        ]));
  }

  ImageProvider? _photoProvider(String angle) {
    final local = _photos[angle];
    if (local != null) return FileImage(local);
    final remote = widget.existingRemoval?.photos[angle];
    return remote == null ? null : NetworkImage(remote);
  }
}

class _ReceptionPhotoScreen extends StatefulWidget {
  const _ReceptionPhotoScreen(
      {required this.mission, required this.removal, required this.service});
  final Mission mission;
  final MissionRemoval removal;
  final MissionService service;
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
    'sheet': 'Fiche du véhicule'
  };

  ImageProvider? _provider(String angle) {
    if (_photos[angle] != null) return FileImage(_photos[angle]!);
    final remote = widget.removal.receptionPhotos[angle];
    return remote == null ? null : NetworkImage(remote);
  }

  Future<void> _take(String angle) async {
    final image = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 85, maxWidth: 1800);
    if (image != null) setState(() => _photos[angle] = File(image.path));
  }

  Future<void> _save() async {
    if ({...widget.removal.receptionPhotos, ..._photos}.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Les 4 angles et la fiche sont obligatoires.')));
      return;
    }
    if (_photos.isEmpty && widget.removal.received) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    try {
      final mission = await widget.service
          .storeReception(widget.mission.id, widget.removal.id, _photos);
      if (mounted) Navigator.pop(context, mission);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text('Réception • ${widget.removal.label}')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF087F42), Color(0xFF12A85C)]),
                borderRadius: BorderRadius.circular(18)),
            child: const Row(children: [
              Icon(Icons.verified_user_outlined, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                  child: Text('Photographiez l’état du véhicule à son arrivée.',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)))
            ])),
        const SizedBox(height: 18),
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
                              width: 1.5),
                          image: image == null
                              ? null
                              : DecorationImage(
                                  image: image, fit: BoxFit.cover)),
                      child: image == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  const Icon(Icons.add_a_photo_outlined,
                                      color: SendraTheme.green),
                                  const SizedBox(height: 7),
                                  Text(entry.value, textAlign: TextAlign.center)
                                ])
                          : Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(7),
                                  decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.vertical(
                                          bottom: Radius.circular(14))),
                                  child: Text(entry.value,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.white))))));
            }).toList()),
        const SizedBox(height: 20),
        ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(_saving
                ? 'Enregistrement…'
                : widget.removal.received
                    ? 'Enregistrer les modifications'
                    : 'Valider la réception'))
      ]));
}

class _TruckDestinationSheet extends StatefulWidget {
  const _TruckDestinationSheet(
      {required this.mission, required this.truck, required this.service});
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sélectionnez la fourrière du camion.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await widget.service
          .setTruckDestination(widget.mission.id, widget.truck.id, _pound!);
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: EdgeInsets.fromLTRB(
          22, 12, 22, MediaQuery.of(context).viewInsets.bottom + 28),
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
                        borderRadius: BorderRadius.circular(5)))),
            const SizedBox(height: 18),
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF087F42), Color(0xFF12A85C)]),
                    borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.local_shipping_outlined,
                          color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                            [widget.truck.brand, widget.truck.registration]
                                .where((v) => (v ?? '').isNotEmpty)
                                .join(' • '),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const Text('Destination du camion',
                            style: TextStyle(color: Colors.white70))
                      ]))
                ])),
            const SizedBox(height: 18),
            const Text('Choisir la fourrière',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            const Text(
                'Cette destination s’appliquera à toutes les voitures associées à ce camion.',
                style: TextStyle(color: SendraTheme.muted)),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
                value: _pound,
                isExpanded: true,
                decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.local_parking,
                        color: SendraTheme.green),
                    labelText: 'Fourrière de destination',
                    filled: true,
                    fillColor: const Color(0xFFF3F8F5),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none)),
                items: widget.mission.pounds
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _pound = v)),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(_saving
                        ? 'Enregistrement…'
                        : 'Enregistrer la destination')))
          ])));
}
