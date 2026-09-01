import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:walletium/controller/bottom_navigation_controller.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/sendra_theme.dart';
import 'package:walletium/views/screens/cartography_screen.dart';
import 'package:walletium/views/screens/home_screen.dart';

class BottomNavigationWidget extends StatefulWidget {
  const BottomNavigationWidget({super.key});

  @override
  _BottomNavigationWidgetState createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  final _controller = Get.put(BottomNavigationController());

  static const List<Widget> mainScreens = [
    const HomeScreen(),
    CartographyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: SendraTheme.surface,
        body: IndexedStack(
          index: _controller.getIndex(),
          children: mainScreens,
        ),
        floatingActionButton: FloatingActionButton.extended(
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
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.directions_car_outlined),
                  selectedIcon:
                      Icon(Icons.directions_car, color: SendraTheme.green),
                  label: 'Participations',
                ),
                NavigationDestination(
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
