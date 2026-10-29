import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:walletium/controller/bottom_navigation_controller.dart';
import 'package:walletium/utils/app_brand.dart';
import 'package:walletium/utils/app_prefs.dart';
import 'package:walletium/utils/signaler_flow.dart';
import 'package:walletium/utils/sendra_theme.dart';
import 'package:walletium/views/screens/cartography_screen.dart';
import 'package:walletium/views/screens/home_screen.dart';
import 'package:walletium/views/screens/missions_screen.dart';
import 'package:walletium/widgets/others/guide_view.dart';

class BottomNavigationWidget extends StatefulWidget {
  const BottomNavigationWidget({super.key});

  @override
  State<BottomNavigationWidget> createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  final _controller = Get.put(BottomNavigationController());

  // Rôle lu de façon synchrone (préférences préchargées dans main) : plus
  // d'écran de chargement intermédiaire à l'arrivée sur l'accueil.
  late final bool _isAgent = AppPrefs.isAgent;

  // Guide de bienvenue : décidé de façon synchrone, il s'affiche en plein
  // écran dès la première connexion — avant, il était construit dans
  // l'onglet avec une valeur par défaut « affiché » puis masqué après lecture
  // asynchrone des préférences : on en voyait un bout puis il disparaissait.
  late bool _showGuide =
      !(AppPrefs.maybe?.getBool(AppBrand.guideSeenKey) ?? false);

  Future<void> _closeGuide() async {
    setState(() => _showGuide = false);
    final prefs = await AppPrefs.init();
    await prefs.setBool(AppBrand.guideSeenKey, true);
  }

  // Onglets construits seulement à la première visite. Avant, l'IndexedStack
  // construisait dès l'ouverture la carte Google Maps, la géolocalisation et
  // le chargement des missions, en plus de la liste : c'était la principale
  // cause de lenteur à l'arrivée sur l'accueil.
  late final List<bool> _built;

  late final List<_Tab> _tabs = [
    _Tab(
      'Participations',
      'Accueil',
      Icons.directions_car_outlined,
      Icons.directions_car_rounded,
      () => const HomeScreen(),
    ),
    if (_isAgent)
      _Tab(
        'Missions',
        'Missions',
        Icons.assignment_outlined,
        Icons.assignment_rounded,
        () => const MissionsScreen(),
      ),
    _Tab(
      'Cartographie',
      'Carte',
      Icons.map_outlined,
      Icons.map_rounded,
      () => const CartographyScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (_controller.getIndex() >= _tabs.length) _controller.setIndex(0);
    _built = List<bool>.filled(_tabs.length, false);
    _built[_controller.getIndex()] = true;
  }

  void _select(int index) {
    if (index == _controller.getIndex()) return;
    HapticFeedback.selectionClick();
    _built[index] = true;
    _controller.setIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SendraTheme.overlayLight,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showGuide
            ? GuideView(key: const ValueKey('guide'), onDone: _closeGuide)
            : KeyedSubtree(key: const ValueKey('app'), child: _buildApp()),
      ),
    );
  }

  Widget _buildApp() {
    return Obx(() {
      final index = _controller.getIndex();
      final etroit = MediaQuery.sizeOf(context).width / _tabs.length < 120;
      return Scaffold(
        backgroundColor: SendraTheme.surface,
        body: IndexedStack(
          index: index,
          children: [
            // Les onglets masqués gardent leur état mais n'animent plus
            // rien en arrière-plan (bouton Signaler, carte…).
            for (var i = 0; i < _tabs.length; i++)
              TickerMode(
                enabled: i == index,
                child: _built[i] ? _tabs[i].builder() : const SizedBox.shrink(),
              ),
          ],
        ),
        // Sur l'accueil, le grand bouton Signaler est dans la page (tiers
        // haut) ; ailleurs il reste accessible en bouton flottant.
        floatingActionButton: index == 0
            ? null
            : FloatingActionButton.extended(
                heroTag: 'signaler',
                onPressed: () => SignalerFlow.demarrer(context),
                icon: const Icon(Icons.add_a_photo_rounded),
                label: const Text('Signaler'),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: SendraTheme.border)),
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: _select,
            destinations: [
              for (final tab in _tabs)
                NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.selectedIcon),
                  // Écran étroit (Fold fermé) : libellé court pour que
                  // chaque onglet tienne dans sa largeur.
                  label: etroit ? tab.shortLabel : tab.label,
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _Tab {
  _Tab(this.label, this.shortLabel, this.icon, this.selectedIcon, this.builder);
  final String label;
  final String shortLabel;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function() builder;
}
