import 'package:shared_preferences/shared_preferences.dart';

/// Rôles staff (accès au workflow métier complet : véhicule, infraction,
/// dommages, enlèvement, approbation) vs citoyen (lecture seule sur ses
/// propres signalements) — cf. AUDIT_SENDRA.md §1.1. Convention de rôles
/// partagée avec le backend : 1=Admin, 2=Agent, 3=Autorité commune,
/// 4=Autorité préfecture, 5=citoyen.
class Session {
  static const _roleKey = 'role_id';

  static Future<void> saveRoleId(int? roleId) async {
    final prefs = await SharedPreferences.getInstance();
    if (roleId == null) {
      await prefs.remove(_roleKey);
    } else {
      await prefs.setInt(_roleKey, roleId);
    }
  }

  static Future<int?> getRoleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_roleKey);
  }

  static Future<bool> isStaff() async {
    final roleId = await getRoleId();
    return roleId != null && roleId >= 1 && roleId <= 4;
  }

  static Future<bool> isAgent() async => (await getRoleId()) == 2;
}
