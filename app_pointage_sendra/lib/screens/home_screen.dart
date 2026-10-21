import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../pointage_controller.dart';

const _green = Color(0xFF087A46);
const _darkGreen = Color(0xFF075B3E);
const _surface = Color(0xFFF4F8F5);

typedef _PunchChoice = ({
  String type,
  String label,
  IconData icon,
  bool available,
  DateTime? recordedAt,
});

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});
  final PointageController controller;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _openingPunch = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        widget.controller.isSignedIn &&
        !_openingPunch) {
      widget.controller.refresh();
    }
  }

  Future<void> _confirmLogout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Vous devrez saisir vos identifiants pour revenir dans l’application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (yes == true) await widget.controller.logout();
  }

  Future<void> _confirmJoin() async {
    await widget.controller.join();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final name = '${c.user?['first_name'] ?? ''} ${c.user?['last_name'] ?? ''}'
        .trim();
    return Scaffold(
      drawer: _HomeDrawer(controller: c, onLogout: _confirmLogout),
      body: RefreshIndicator(
        onRefresh: c.refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton.filledTonal(
                      tooltip: 'Ouvrir le menu',
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu_rounded),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _todayLabel(),
                    style: const TextStyle(
                      color: Color(0xFF5B7164),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Bonjour ${name.isEmpty ? '' : name.split(' ').first} 👋',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF173A28),
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Prêt à enregistrer votre journée ?',
              style: TextStyle(color: Color(0xFF65776C), fontSize: 16),
            ),
            const SizedBox(height: 26),
            if (c.error != null) _MessageCard(c.error!, error: true),
            if (c.notice != null) _MessageCard(c.notice!),
            if (c.user == null && c.error != null)
              _StatusCard(
                icon: Icons.wifi_off_outlined,
                title: 'Compte indisponible',
                description:
                    'Impossible de charger votre profil. Réessayez dans un instant.',
                button: 'Réessayer',
                onPressed: c.busy ? null : c.refresh,
              )
            else if (c.status == 'not_registered')
              _StatusCard(
                icon: Icons.app_registration,
                title: 'Demander l’accès au pointage',
                description:
                    'Envoyez votre demande pour que votre responsable valide votre accès.',
                button: 'Envoyer ma demande',
                onPressed: c.busy ? null : _confirmJoin,
              )
            else if (c.status == 'pending')
              _StatusCard(
                icon: Icons.phonelink_lock,
                title: c.deviceRegistered
                    ? 'Inscription en attente'
                    : 'Lier ce téléphone',
                description: c.deviceRegistered
                    ? 'Téléphone lié. Un administrateur doit vérifier votre identité et valider votre compte.'
                    : 'Confirmez avec l’empreinte ou Face ID de ce téléphone. Il doit être réservé à vous : retirez les biométries des autres personnes avant de le lier. Votre responsable validera ensuite votre identité.',
                button: c.deviceRegistered ? null : 'Lier mon téléphone',
                onPressed: c.busy ? null : c.registerDevice,
              )
            else if (c.status == 'disabled')
              const _StatusCard(
                icon: Icons.lock_outline,
                title: 'Accès désactivé',
                description: 'Contactez votre responsable.',
              )
            else
              ..._approvedContent(context),
          ],
        ),
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  DateTime? _recordedAt(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '')?.toLocal();

  String _hour(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _choosePunch(List<_PunchChoice> options) async {
    if (_openingPunch) return;
    _openingPunch = true;
    try {
      final secret = await widget.controller.unlockForPunch();
      if (secret == null || !mounted) return;
      await widget.controller.refresh();
      if (!mounted || widget.controller.error != null) return;
      options = _punchOptions();
      final selected = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: _surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (context) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .85,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Votre pointage',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _darkGreen,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Choisissez l’étape que vous souhaitez enregistrer.',
                      style: TextStyle(color: Color(0xFF5D7065)),
                    ),
                    const SizedBox(height: 20),
                    ...options.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PunchChoiceCard(
                          choice: entry.value,
                          number: entry.key + 1,
                          recordedTime: entry.value.recordedAt == null
                              ? null
                              : _hour(entry.value.recordedAt!),
                          onTap: entry.value.available
                              ? () => Navigator.pop(context, entry.value.type)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'Un pointage enregistré reste indisponible jusqu’à demain.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6D7D73),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      if (selected != null) await widget.controller.punch(selected, secret);
    } finally {
      _openingPunch = false;
    }
  }

  List<Widget> _approvedContent(BuildContext context) {
    final c = widget.controller;
    final opened = _currentOpenSession();
    final site = c.assignment?['site'] is Map
        ? (c.assignment!['site'] as Map).cast<String, dynamic>()
        : opened?['site'] is Map
        ? (opened!['site'] as Map).cast<String, dynamic>()
        : null;
    if (site == null) {
      return [
        const _StatusCard(
          icon: Icons.schedule,
          title: 'En attente d’affectation',
          description:
              'Votre responsable doit définir le site et les horaires de travail.',
        ),
      ];
    }
    final today = c.history
        .where(
          (record) =>
              record['work_date']?.toString().startsWith(
                DateTime.now().toIso8601String().substring(0, 10),
              ) ==
              true,
        )
        .firstOrNull;
    final options = _punchOptions();
    final complete = today?['departed_at'] != null && opened == null;
    return [
      Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height * .53,
        ),
        padding: const EdgeInsets.fromLTRB(25, 28, 25, 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B8650), _darkGreen],
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: _darkGreen.withValues(alpha: .16),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              button: !complete,
              label: complete
                  ? 'Journée terminée'
                  : 'Pointer avec la biométrie',
              child: InkWell(
                onTap:
                    complete ||
                        c.busy ||
                        !c.pointageAvailable ||
                        !c.thisDeviceRegistered
                    ? null
                    : () => _choosePunch(options),
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: _BiometricMark(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Votre présence en un geste',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Touchez l’empreinte, identifiez-vous, puis choisissez le moment de votre journée.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFE2F3E8),
                fontSize: 16,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white,
                    size: 17,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      site['name']?.toString() ?? 'Site',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (complete) ...[
              const SizedBox(height: 28),
              const Text(
                'Votre journée est terminée. Les choix reviennent demain.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (!complete && (!c.pointageAvailable || !c.thisDeviceRegistered))
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Ce téléphone n’est pas autorisé pour ce compte. Contactez votre responsable.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
      if (c.busy)
        const Padding(
          padding: EdgeInsets.only(top: 14),
          child: LinearProgressIndicator(),
        ),
    ];
  }

  Map<String, dynamic>? _currentOpenSession() {
    final opened = widget.controller.openSession;
    if (opened == null) return null;
    final today = DateTime.now();
    final date = DateTime.tryParse(opened['work_date']?.toString() ?? '');
    if (date == null) return null;
    final difference = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    if (difference >= 0) return opened;
    final end = DateTime.tryParse(
      opened['scheduled_end']?.toString() ?? '',
    )?.toLocal();
    return difference == -1 &&
            end != null &&
            today.isBefore(end.add(const Duration(hours: 2)))
        ? opened
        : null;
  }

  List<_PunchChoice> _punchOptions() {
    final c = widget.controller;
    final opened = _currentOpenSession();
    final today = c.history
        .where(
          (record) =>
              record['work_date']?.toString().startsWith(
                DateTime.now().toIso8601String().substring(0, 10),
              ) ==
              true,
        )
        .firstOrNull;
    final session = opened ?? today;
    return <_PunchChoice>[
      (
        type: 'arrival',
        label: 'Début de travail',
        icon: Icons.login_rounded,
        available: session == null,
        recordedAt: _recordedAt(session?['arrived_at']),
      ),
      (
        type: 'break_start',
        label: 'Début de pause',
        icon: Icons.pause_rounded,
        available: opened != null && opened['break_started_at'] == null,
        recordedAt: _recordedAt(session?['break_started_at']),
      ),
      (
        type: 'break_end',
        label: 'Fin de pause',
        icon: Icons.play_arrow_rounded,
        available:
            opened != null &&
            opened['break_started_at'] != null &&
            opened['break_ended_at'] == null,
        recordedAt: _recordedAt(session?['break_ended_at']),
      ),
      (
        type: 'departure',
        label: 'Fin de travail',
        icon: Icons.logout_rounded,
        available:
            opened != null &&
            (opened['break_started_at'] == null ||
                opened['break_ended_at'] != null),
        recordedAt: _recordedAt(session?['departed_at']),
      ),
    ];
  }
}

class _BiometricMark extends StatefulWidget {
  const _BiometricMark();

  @override
  State<_BiometricMark> createState() => _BiometricMarkState();
}

class _BiometricMarkState extends State<_BiometricMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);
  bool _faceAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final types = await LocalAuthentication().getAvailableBiometrics();
      if (mounted) {
        setState(
          () => _faceAvailable =
              types.contains(BiometricType.face) ||
              (types.contains(BiometricType.weak) &&
                  !types.contains(BiometricType.strong)),
        );
      }
    } catch (_) {
      // Le pointage reste piloté par la biométrie native du stockage sécurisé.
    }
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _scan,
    builder: (context, _) => Container(
      width: 148,
      height: 148,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .10),
        border: Border.all(
          color: Colors.white.withValues(alpha: .30),
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 113,
            height: 113,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: .16),
                width: 1.5,
              ),
            ),
          ),
          Icon(
            _faceAvailable ? Icons.face_rounded : Icons.fingerprint_rounded,
            color: Colors.white,
            size: 79,
          ),
          Positioned(
            top: 27 + _scan.value * 88,
            left: 30,
            right: 30,
            child: Container(
              height: 2.5,
              decoration: BoxDecoration(
                color: const Color(0xFFB9FFD5),
                borderRadius: BorderRadius.circular(3),
                boxShadow: const [
                  BoxShadow(color: Color(0xFFB9FFD5), blurRadius: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer({required this.controller, required this.onLogout});

  final PointageController controller;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final first = controller.user?['first_name']?.toString() ?? '';
    final last = controller.user?['last_name']?.toString() ?? '';
    final name = '$first $last'.trim();
    void open(Widget page) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }

    return Drawer(
      backgroundColor: _surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_green, _darkGreen]),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: .18),
                    child: Text(
                      first.isEmpty ? 'S' : first[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name.isEmpty ? 'Mon compte' : name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Espace pointage',
                    style: TextStyle(color: Color(0xFFD7F0E1)),
                  ),
                ],
              ),
            ),
            _DrawerEntry(
              icon: Icons.person_outline_rounded,
              label: 'Profil',
              onTap: () => open(_ProfileScreen(controller: controller)),
            ),
            _DrawerEntry(
              icon: Icons.bar_chart_rounded,
              label: 'Statistiques',
              onTap: () => open(_HistoryScreen(controller: controller)),
            ),
            _DrawerEntry(
              icon: Icons.shield_outlined,
              label: 'Confidentialité',
              onTap: () => open(const _PrivacyScreen()),
            ),
            const Spacer(),
            const Divider(indent: 24, endIndent: 24),
            _DrawerEntry(
              icon: Icons.logout_rounded,
              label: 'Se déconnecter',
              color: const Color(0xFF9C3939),
              onTap: () {
                Navigator.pop(context);
                onLogout();
              },
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _DrawerEntry extends StatelessWidget {
  const _DrawerEntry({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = _darkGreen,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
    child: ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 19),
      onTap: onTap,
    ),
  );
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen({required this.controller});
  final PointageController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.user ?? {};
    final site = controller.assignment?['site'];
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.account_circle_rounded, color: _green, size: 88),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim(),
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: _darkGreen,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _InfoTile(
            icon: Icons.phone_outlined,
            title: 'Téléphone',
            value: user['telephone']?.toString() ?? '—',
          ),
          _InfoTile(
            icon: Icons.location_on_outlined,
            title: 'Site de pointage',
            value: site is Map
                ? site['name']?.toString() ?? '—'
                : 'Non affecté',
          ),
          _InfoTile(
            icon: Icons.verified_user_outlined,
            title: 'Accès',
            value: controller.status == 'approved' ? 'Validé' : 'En attente',
          ),
        ],
      ),
    );
  }
}

class _PrivacyScreen extends StatelessWidget {
  const _PrivacyScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Confidentialité')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _InfoTile(
          icon: Icons.fingerprint_rounded,
          title: 'Biométrie',
          value:
              'Votre empreinte ou votre visage reste dans le système sécurisé du téléphone. L’application ne reçoit pas ces données.',
        ),
        _InfoTile(
          icon: Icons.location_on_outlined,
          title: 'Position',
          value:
              'Votre position est relevée uniquement quand vous confirmez un pointage.',
        ),
        _InfoTile(
          icon: Icons.phonelink_lock_outlined,
          title: 'Téléphone lié',
          value:
              'Un seul téléphone est associé à votre compte. Contactez votre responsable pour en changer.',
        ),
      ],
    ),
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _green),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(color: Color(0xFF55695D), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _PunchChoiceCard extends StatelessWidget {
  const _PunchChoiceCard({
    required this.choice,
    required this.number,
    required this.recordedTime,
    required this.onTap,
  });

  final _PunchChoice choice;
  final int number;
  final String? recordedTime;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final done = recordedTime != null;
    final active = choice.available;
    final accent = switch (choice.type) {
      'arrival' => const Color(0xFF087A46),
      'break_start' => const Color(0xFFB65B0B),
      'break_end' => const Color(0xFF1764A3),
      'departure' => const Color(0xFF7045A2),
      _ => _green,
    };
    final color = accent;
    final background = active ? Colors.white : accent.withValues(alpha: .045);
    final status = done
        ? 'Enregistré à $recordedTime'
        : active
        ? 'Disponible maintenant'
        : 'À venir';
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 82),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? accent : accent.withValues(alpha: .18),
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(choice.icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${number.toString().padLeft(2, '0')}  ${choice.label}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: active || done
                            ? const Color(0xFF173A28)
                            : const Color(0xFF68766D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 13,
                        color: color,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                done
                    ? Icons.check_circle_rounded
                    : active
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.lock_outline_rounded,
                color: color,
                size: active ? 19 : 22,
              ),
            ],
          ),
        ),
      ),
    );
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
    appBar: AppBar(title: const Text('Statistiques')),
    body: RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListenableBuilder(
        listenable: controller,
        builder: (_, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Vos pointages récents',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: _darkGreen,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Retrouvez les horaires enregistrés pour chaque journée.',
              style: TextStyle(color: Color(0xFF65776C)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Journées',
                    value: '${controller.history.length}',
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: 'Terminées',
                    value:
                        '${controller.history.where((item) => item['departed_at'] != null).length}',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (controller.history.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: Text('Aucun pointage enregistré.')),
              ),
            ...controller.history.map(
              (record) => Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _day(record['work_date']),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.login, color: _green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Début de travail  ${_time(record['arrived_at'])}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.pause_circle_outline, color: _green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Début de pause  ${_time(record['break_started_at'])}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.play_circle_outline, color: _green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Fin de pause  ${_time(record['break_ended_at'])}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.logout, color: _green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Fin de travail  ${_time(record['departed_at'])}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _darkGreen,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFB6EFD0)),
        const SizedBox(height: 14),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(label, style: const TextStyle(color: Color(0xFFD7F0E1))),
      ],
    ),
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.description,
    this.button,
    this.onPressed,
  });
  final IconData icon;
  final String title, description;
  final String? button;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 42, color: _green),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(description),
          if (button != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onPressed, child: Text(button!)),
          ],
        ],
      ),
    ),
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard(this.message, {this.error = false});
  final String message;
  final bool error;
  @override
  Widget build(BuildContext context) => Card(
    color: error ? const Color(0xFFFFECE9) : const Color(0xFFE5F5EC),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Text(
        message,
        style: TextStyle(
          color: error ? const Color(0xFF9F3124) : const Color(0xFF075B3E),
        ),
      ),
    ),
  );
}
