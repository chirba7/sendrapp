import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../routes/routes.dart';
import '../../utils/app_brand.dart';
import '../../utils/app_prefs.dart';
import '../../utils/custom_color.dart';
import '../../utils/ecran.dart';
import '../../utils/sendra_theme.dart';
import '../../utils/strings.dart';
import 'package:walletium/widgets/others/photo_reseau.dart';

class DrawerScreen extends StatelessWidget {
  const DrawerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Drawer(
      width: width < 360 ? width * .86 : 312,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              // Marge basse : le bouton de déconnexion reste au-dessus de la
              // barre de navigation du téléphone.
              padding:
                  EdgeInsets.fromLTRB(12, 12, 12, 12 + context.margeBasSysteme),
              children: [
                _buildSection(
                  context,
                  'Informations',
                  [
                    MenuItemData(
                      title: Strings.aboutUs,
                      icon: Icons.info_rounded,
                      color: const Color(0xFFE08A00),
                      onTap: () => _go(context, Routes.aboutUsScreen),
                    ),
                    MenuItemData(
                      title: 'Politique de confidentialité',
                      icon: Icons.shield_rounded,
                      color: const Color(0xFF7B3FC4),
                      onTap: () => _launchPrivacyPolicy(context),
                    ),
                  ],
                ),
                _buildSection(
                  context,
                  'Compte & profil',
                  [
                    MenuItemData(
                      title: Strings.profile,
                      icon: Icons.person_rounded,
                      color: const Color(0xFF1A73E8),
                      onTap: () => _go(context, Routes.profileScreen),
                    ),
                    MenuItemData(
                      title: 'Supprimer le compte',
                      icon: Icons.delete_forever_rounded,
                      color: const Color(0xFFD93025),
                      onTap: () => _showDeleteAccountConfirmation(context),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Placé dans la liste (et non tout en bas) : il n'est plus
                // masqué par le bouton flottant « Signaler ».
                _buildLogoutButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ferme le menu puis ouvre la page : évite de revenir sur un menu ouvert.
  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    Get.toNamed(route);
  }

  /// En-tête du menu : fond blanc, logo epAvie (+ PRO pour l'app agents),
  /// puis la carte de l'utilisateur connecté (photo ou initiale, nom, n°).
  Widget _buildHeader(BuildContext context) {
    final prefs = AppPrefs.maybe;
    final fullName = prefs?.getString('fullName') ?? '';
    final phone = prefs?.getString('phone') ?? '';
    final photoUrl = prefs?.getString('profilePhotoUrl') ?? '';
    final initial =
        fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : '?';
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                AppBrand.drawerLogo,
                height: 46,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
                filterQuality: FilterQuality.medium,
              ),
              if (fullName.isNotEmpty || phone.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SendraTheme.greenSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: SendraTheme.green,
                        foregroundImage: photoUrl.isNotEmpty
                            ? vignette(
                                context, photoReseauProvider(photoUrl), 44)
                            : null,
                        child: Text(
                          initial,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (fullName.isNotEmpty)
                              Text(
                                fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: SendraTheme.ink,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if (phone.isNotEmpty)
                              Text(
                                phone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: SendraTheme.muted,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<MenuItemData> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: SendraTheme.muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          ...items.map((item) => _buildMenuItem(context, item)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, MenuItemData item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: SendraTheme.ink,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: SendraTheme.muted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _showLogoutConfirmation(context),
          // Déconnexion en rouge (action de sortie).
          style: FilledButton.styleFrom(
            backgroundColor: SendraTheme.statusSignale,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text(Strings.signOut),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Déconnexion',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "Êtes-vous sûr de vouloir vous déconnecter de l'application ?",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Annuler',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                elevation: 2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Se déconnecter',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    // Afficher un snackbar discret pour la déconnexion
    Get.showSnackbar(
      const GetSnackBar(
        messageText: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 15),
            Text(
              'Déconnexion en cours...',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: CustomColor.primaryColor,
        duration: Duration(milliseconds: 900),
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(10),
        borderRadius: 8,
        isDismissible: false,
      ),
    );

    // Nettoyer les données de session
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('fullName');
    await prefs.remove('phone');
    await prefs.remove('lastRoute');
    await prefs.remove('role_id');

    // Rediriger vers l'écran de connexion
    Get.offAllNamed(Routes.signInScreen);
  }

  Future<void> _launchPrivacyPolicy(BuildContext context) async {
    final Uri url = Uri.parse(
        'https://www.privacypolicies.com/live/12076de3-e527-407e-b179-24c0007dde47');
    try {
      final opened = await launchUrl(
        url,
        // Sur Android, ce mode ouvre un Custom Tab avec une barre système
        // et un bouton fermer/retour toujours visible. L'utilisateur revient
        // donc dans Sendra sans devoir tuer puis relancer l'application.
        mode: LaunchMode.inAppBrowserView,
      );
      if (!opened) {
        throw Exception('Ouverture refusée');
      }
    } catch (e) {
      if (!context.mounted) return;
      // Afficher un message d'erreur plus élégant
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                ),
                SizedBox(width: 10),
                Text('Échec de connexion'),
              ],
            ),
            content: const Text(
              "Impossible d'accéder à la politique de confidentialité. Veuillez vérifier votre connexion internet et réessayer.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: CustomColor.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade600,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Supprimer le compte',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚠️ ATTENTION',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Cette action est définitive et irréversible. Toutes vos données seront supprimées définitivement :',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '• Votre profil utilisateur\n• Vos données personnelles\n• Votre historique\n• Toutes vos informations',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Êtes-vous sûr(e) de vouloir continuer ?',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteUserAccount(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Supprimer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUserAccount(BuildContext context) async {
    // Afficher le dialogue de chargement
    Get.dialog(
      Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade600),
              ),
              const SizedBox(height: 15),
              Text(
                'Suppression du compte en cours...',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      // Récupérer le token et le téléphone depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final phone = prefs.getString('phone');

      debugPrint('=== SUPPRESSION DE COMPTE ===');
      debugPrint('Token utilisé: $token');
      debugPrint('Téléphone utilisé: $phone');

      if (token == null || phone == null) {
        Get.back();
        if (!context.mounted) return;
        _showErrorDialog(
          context,
          'Erreur de données',
          "Informations d'authentification manquantes. Veuillez vous reconnecter.",
        );
        return;
      }

      // Préparer les headers
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };

      debugPrint('Headers de la requête: $headers');

      // Préparer le body de la requête
      final requestBody = json.encode({'telephone': phone});

      debugPrint('Body de la requête: $requestBody');

      // Construire l'URL en utilisant le format standard
      final url = '${Strings.apiURI}delete-user';

      debugPrint('URL de la requête: $url');

      // Faire l'appel API POST
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: requestBody,
      );

      debugPrint('Status Code suppresion: ${response.statusCode}');

      // Lire la réponse
      String responseBody = response.body;
      debugPrint('Réponse complète du serveur suppresion: $responseBody');

      // Fermer le dialogue de chargement
      Get.back();

      if (response.statusCode == 200) {
        // Succès - analyser la réponse
        final responseData = json.decode(responseBody);
        debugPrint('Données de réponse décodées: $responseData');

        // Nettoyer toutes les données locales
        await prefs.clear();
        debugPrint('Données locales supprimées');

        // Afficher le message de succès
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green.shade600,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  'Compte supprimé',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              responseData['message'] ??
                  'Votre compte a été supprimé avec succès.',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 15,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.offAllNamed(Routes.signInScreen);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
          barrierDismissible: false,
        );
      } else if (response.statusCode == 401) {
        // Non autorisé
        debugPrint('Erreur 401: Non autorisé');
        if (!context.mounted) return;
        _showErrorDialog(
          context,
          "Erreur d'autorisation",
          'Votre session a expiré. Veuillez vous reconnecter et réessayer.',
        );
      } else {
        // Autres erreurs
        debugPrint('Erreur ${response.statusCode}: $responseBody');

        // Tenter de décoder la réponse d'erreur
        try {
          final errorData = json.decode(responseBody);
          if (!context.mounted) return;
          _showErrorDialog(
            context,
            'Erreur de suppression',
            errorData['message'] ??
                'Une erreur est survenue lors de la suppression du compte.',
          );
        } catch (e) {
          if (!context.mounted) return;
          _showErrorDialog(
            context,
            'Erreur de suppression',
            'Une erreur est survenue lors de la suppression du compte.',
          );
        }
      }
    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      Get.back();

      debugPrint('Exception lors de la suppression: $e');

      if (!context.mounted) return;
      _showErrorDialog(
        context,
        'Erreur de connexion',
        'Impossible de contacter le serveur. Vérifiez votre connexion internet et réessayez.',
      );
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade600,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 15,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class MenuItemData {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final LinearGradient? gradient;
  final Color color;

  const MenuItemData({
    required this.title,
    required this.icon,
    required this.onTap,
    this.gradient,
    this.color = SendraTheme.green,
  });
}
