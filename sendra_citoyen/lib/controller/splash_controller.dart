import 'package:get/get.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/app_prefs.dart';

class SplashController extends GetxController {
  /// Durée minimale du splash animé : juste le temps de l'animation
  /// d'entrée (auparavant 1,7 s d'attente fixe à chaque ouverture).
  static const minimumDisplay = Duration(milliseconds: 1100);

  @override
  void onReady() {
    super.onReady();
    _goToScreen();
  }

  Future<void> _goToScreen() async {
    final prefs = await AppPrefs.init();
    final token = prefs.getString('token');
    final authorized =
        token != null && token.isNotEmpty && AppPrefs.roleId == 5;
    final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;
    await Future<void>.delayed(minimumDisplay);
    Get.offAllNamed(
      authorized
          ? Routes.bottomNavigationScreen
          : hasSeenWelcome
              ? Routes.signInScreen
              : Routes.welcomeScreen,
    );
  }
}
