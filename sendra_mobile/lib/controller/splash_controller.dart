import 'package:get/get.dart';
import 'package:walletium/routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _goToScreen();
  }

  Future<void> _goToScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final lastRoute = prefs.getString('lastRoute');

    await Future<void>.delayed(const Duration(milliseconds: 2200));

    if (token != null && token.isNotEmpty) {
      final destination = lastRoute != null &&
              lastRoute.isNotEmpty &&
              lastRoute != Routes.signInScreen &&
              lastRoute != Routes.splashScreen
          ? lastRoute
          : Routes.bottomNavigationScreen;
      Get.offAllNamed(destination);
      return;
    }
    Get.offAllNamed(Routes.signInScreen);
  }
}
