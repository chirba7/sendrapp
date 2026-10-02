import 'package:flutter/material.dart';
import '../pointage_controller.dart';

const _green = Color(0xFF00A94F);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});
  final PointageController controller;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Future<void> _confirmLogout() async {
    final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Se déconnecter ?'),
      content: const Text('Vous devrez saisir vos identifiants pour revenir dans l’application.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Se déconnecter'))],
    ));
    if (yes == true) await widget.controller.logout();
  }

  Future<void> _confirmJoin() async {
    await widget.controller.join();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final name = '${c.user?['first_name'] ?? ''} ${c.user?['last_name'] ?? ''}'.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('SENDRA  •  Pointage', style: TextStyle(fontWeight: FontWeight.bold)), actions: [
        IconButton(tooltip: 'Actualiser', onPressed: c.busy ? null : c.refresh, icon: const Icon(Icons.refresh)),
        IconButton(tooltip: 'Se déconnecter', onPressed: c.busy ? null : _confirmLogout, icon: const Icon(Icons.logout)),
      ]),
      body: RefreshIndicator(onRefresh: c.refresh, child: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Bonjour, $name', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Votre présence, au bon endroit et au bon moment.'),
        const SizedBox(height: 18),
        if (c.error != null) _MessageCard(c.error!, error: true),
        if (c.notice != null) _MessageCard(c.notice!),
        if (c.user == null && c.error != null) _StatusCard(
          icon: Icons.wifi_off_outlined, title: 'Compte indisponible',
          description: 'Impossible de charger votre profil. Réessayez dans un instant.',
          button: 'Réessayer', onPressed: c.busy ? null : c.refresh,
        ) else if (c.status == 'not_registered') _StatusCard(
          icon: Icons.app_registration, title: 'Demander l’accès au pointage',
          description: 'Envoyez votre demande pour que votre responsable valide votre accès.',
          button: 'Envoyer ma demande', onPressed: c.busy ? null : _confirmJoin,
        ) else if (c.status == 'pending') _StatusCard(icon: Icons.phonelink_lock,
          title: c.deviceRegistered ? 'Inscription en attente' : 'Lier ce téléphone',
          description: c.deviceRegistered
            ? 'Téléphone lié. Un administrateur doit vérifier votre identité et valider votre compte.'
            : 'Confirmez avec l’empreinte ou Face ID de ce téléphone. Il doit être réservé à vous : retirez les biométries des autres personnes avant de le lier. Votre responsable validera ensuite votre identité.',
          button: c.deviceRegistered ? null : 'Lier mon téléphone',
          onPressed: c.busy ? null : c.registerDevice)
        else if (c.status == 'disabled') const _StatusCard(icon: Icons.lock_outline,
          title: 'Accès désactivé', description: 'Contactez votre responsable.')
        else ..._approvedContent(context),
        const SizedBox(height: 28),
        Text('Confidentialité', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Votre position est relevée seulement quand vous confirmez une arrivée ou un départ.'),
      ])),
    );
  }

  List<Widget> _approvedContent(BuildContext context) {
    final c = widget.controller;
    final opened = c.openSession;
    final site = c.assignment?['site'] is Map ? (c.assignment!['site'] as Map).cast<String, dynamic>() :
      opened?['site'] is Map ? (opened!['site'] as Map).cast<String, dynamic>() : null;
    if (site == null) {
      return [const _StatusCard(icon: Icons.schedule, title: 'En attente d’affectation',
        description: 'Votre responsable doit définir le site et les horaires de travail.')];
    }
    final arrival = opened == null;
    final now = DateTime.now();
    final complete = arrival && c.history.any((record) {
      final day = DateTime.tryParse(record['work_date']?.toString() ?? '');
      return day != null && day.year == now.year && day.month == now.month && day.day == now.day && record['departed_at'] != null;
    });
    return [
      Container(
        constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height * .58),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(28)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 112, height: 112,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .19), shape: BoxShape.circle),
              child: Icon(arrival ? Icons.login_rounded : Icons.logout_rounded, color: Colors.white, size: 72)),
          const SizedBox(height: 24),
          Text(arrival ? 'Début de travail' : 'Fin de travail', textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(arrival ? 'Vous commencez votre journée ?' : 'Vous terminez votre journée ?', textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          const Text('Votre empreinte ou Face ID et la position GPS seront demandés.', textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 16),
          Text(site['name']?.toString() ?? 'Site', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (complete) const Text('Vos deux pointages du jour sont terminés.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          else FilledButton.icon(onPressed: c.busy || !c.pointageAvailable || !c.thisDeviceRegistered
              ? null : c.punch, icon: const Icon(Icons.fingerprint),
            label: Text(arrival ? 'Confirmer et commencer' : 'Confirmer et terminer'),
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _green,
              minimumSize: const Size.fromHeight(54))),
          if (!complete && (!c.pointageAvailable || !c.thisDeviceRegistered)) const Padding(padding: EdgeInsets.only(top: 12), child: Text(
            'Ce téléphone n’est pas autorisé pour ce compte. Contactez votre responsable.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
        ]),
      ),
      if (c.busy) const Padding(padding: EdgeInsets.only(top: 14), child: LinearProgressIndicator()),
      const SizedBox(height: 18),
      Card(color: Colors.white, elevation: 0, child: ListTile(
        leading: const Icon(Icons.history, color: _green),
        title: const Text('Mes derniers pointages', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Voir mes jours et mes horaires'), trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _HistoryScreen(controller: c))),
      )),
    ];
  }
}

class _HistoryScreen extends StatelessWidget {
  const _HistoryScreen({required this.controller});
  final PointageController controller;
  String _time(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '—';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  String _day(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Historique des pointages')),
    body: RefreshIndicator(onRefresh: controller.refresh, child: ListenableBuilder(listenable: controller,
      builder: (_, _) => ListView(padding: const EdgeInsets.all(20), children: [
        if (controller.history.isEmpty) const Padding(padding: EdgeInsets.only(top: 80),
          child: Center(child: Text('Aucun pointage enregistré.'))),
        ...controller.history.map((record) => Card(color: Colors.white, child: Padding(
          padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_day(record['work_date']), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [const Icon(Icons.login, color: _green), const SizedBox(width: 8),
              Expanded(child: Text('Début de travail  ${_time(record['arrived_at'])}'))]),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.logout, color: _green), const SizedBox(width: 8),
              Expanded(child: Text('Fin de travail  ${_time(record['departed_at'])}'))]),
          ]),
        ))),
      ])),
    ),
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.icon, required this.title, required this.description, this.button, this.onPressed});
  final IconData icon;
  final String title, description;
  final String? button;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Card(color: Colors.white, elevation: 0,
    child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 42, color: _green), const SizedBox(height: 16),
      Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), Text(description),
      if (button != null) ...[const SizedBox(height: 20), FilledButton(onPressed: onPressed, child: Text(button!))],
    ])));
}

class _MessageCard extends StatelessWidget {
  const _MessageCard(this.message, {this.error = false});
  final String message;
  final bool error;
  @override
  Widget build(BuildContext context) => Card(color: error ? const Color(0xFFFFECE9) : const Color(0xFFE5F5EC),
    child: Padding(padding: const EdgeInsets.all(14), child: Text(message,
      style: TextStyle(color: error ? const Color(0xFF9F3124) : const Color(0xFF075B3E)))));
}
