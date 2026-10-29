import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/sendra_theme.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/others/photo_reseau.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String fullName = '';
  String phone = '';
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      fullName = prefs.getString('fullName') ?? 'Nom non renseigné';
      phone = prefs.getString('phone') ?? 'Téléphone non renseigné';
      photoUrl = prefs.getString('profilePhotoUrl');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SendraTheme.surface,
      // Barre du haut alignée sur le reste de l'application (fond blanc).
      appBar: AppBar(title: const Text(Strings.profile)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [SendraTheme.green, SendraTheme.forest],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(children: [
                _profilePicture(),
                const SizedBox(height: 14),
                Text(fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(phone,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: .82),
                        fontSize: 15)),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Get.toNamed(Routes.editProfileScreen);
                    await getUserData();
                  },
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  label: const Text('Modifier mes informations'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 46),
                    side: const BorderSide(color: Colors.white70),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('MON COMPTE',
                  style: TextStyle(
                      color: SendraTheme.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1)),
            ),
            Card(
              child: ListTile(
                onTap: () => Get.toNamed(Routes.changePasswordScreen),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SendraTheme.radius)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.lock_rounded, color: Color(0xFF1A73E8)),
                ),
                title: const Text(Strings.changePassword),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: SendraTheme.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profilePicture() {
    const fallback = Icon(Icons.person_rounded, color: Colors.white, size: 54);
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white54, width: 2),
      ),
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? ClipOval(
              child: PhotoReseau(photoUrl!, largeur: 96, erreur: fallback))
          : fallback,
    );
  }
}
