import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:walletium/controller/bottom_navigation_controller.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/views/screens/cartography_screen.dart';
import 'package:walletium/views/screens/home_screen.dart';

class BottomNavigationWidget extends StatefulWidget {
  BottomNavigationWidget({Key? key}) : super(key: key);

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
        backgroundColor: CustomColor.primaryBackgroundColor,
        body: IndexedStack(
          index: _controller.getIndex(),
          children: mainScreens,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Get.toNamed(Routes.depositScreen),
          backgroundColor: CustomColor.primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_a_photo),
          label: const Text('Signaler'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _controller.getIndex(),
          onTap: _controller.setIndex,
          items: BottomNavigationController.navigationBarItems,
          selectedItemColor: CustomColor.primaryColor,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

}
