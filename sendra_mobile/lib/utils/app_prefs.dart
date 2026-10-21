import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences chargé une seule fois au démarrage (dans main).
/// Les écrans peuvent ainsi lire un drapeau (rôle, guide déjà vu…) de
/// façon synchrone, sans afficher un état transitoire le temps d'un await —
/// c'est ce qui provoquait l'apparition puis la disparition du guide.
class AppPrefs {
  static SharedPreferences? _instance;

  static Future<SharedPreferences> init() async =>
      _instance ??= await SharedPreferences.getInstance();

  static SharedPreferences? get maybe => _instance;

  static int? get roleId => _instance?.getInt('role_id');
  static bool get isAgent => roleId == 2;
  static bool get isStaff {
    final r = roleId;
    return r != null && r >= 1 && r <= 4;
  }
}
