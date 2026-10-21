import 'package:get/get.dart';
import 'package:walletium/routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletium/utils/session.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _goToScreen();
  }

  Future<void> _goToScreen() async {
    final minimumDisplay =
        Future<void>.delayed(const Duration(milliseconds: 1700));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final authorized =
        token != null && token.isNotEmpty && await Session.isAgent();
    final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;
    await minimumDisplay;
    Get.offAllNamed(
        authorized ? Routes.bottomNavigationScreen :
        hasSeenWelcome ? Routes.signInScreen : Routes.welcomeScreen);
  }
}
