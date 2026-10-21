import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:walletium/controller/bottom_navigation_controller.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/sendra_theme.dart';
import 'package:walletium/views/screens/cartography_screen.dart';
import 'package:walletium/views/screens/home_screen.dart';
import 'package:walletium/views/screens/missions_screen.dart';
import 'package:walletium/utils/session.dart';

class BottomNavigationWidget extends StatefulWidget {
  const BottomNavigationWidget({super.key});

  @override
  State<BottomNavigationWidget> createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  final _controller = Get.put(BottomNavigationController());
  bool? _isAgent;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final isAgent = await Session.isAgent();
    if (!mounted) return;
    if (!isAgent && _controller.getIndex() > 1) _controller.setIndex(0);
    setState(() => _isAgent = isAgent);
  }

  @override
  Widget build(BuildContext context) {
    if (_isAgent == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final screens = <Widget>[
      const HomeScreen(),
      if (_isAgent!) const MissionsScreen(),
      const CartographyScreen(),
    ];
    return Obx(
      () => Scaffold(
        backgroundColor: SendraTheme.surface,
        body: IndexedStack(
          index: _controller.getIndex(),
          children: screens,
        ),
        floatingActionButton: Transform.translate(
          offset: const Offset(0, -24),
          child: FloatingActionButton.extended(
            onPressed: () => Get.toNamed(Routes.depositScreen),
            elevation: 4,
            backgroundColor: SendraTheme.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text(
              'Signaler',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: SendraTheme.border)),
            ),
            child: NavigationBar(
              height: 70,
              selectedIndex: _controller.getIndex(),
              onDestinationSelected: _controller.setIndex,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              indicatorColor: const Color(0xFFE1F3E8),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.directions_car_outlined),
                  selectedIcon:
                      Icon(Icons.directions_car, color: SendraTheme.green),
                  label: 'Participations',
                ),
                if (_isAgent!)
                  const NavigationDestination(
                    icon: Icon(Icons.assignment_outlined),
                    selectedIcon:
                        Icon(Icons.assignment, color: SendraTheme.green),
                    label: 'Mission',
                  ),
                const NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map, color: SendraTheme.green),
                  label: 'Cartographie',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
