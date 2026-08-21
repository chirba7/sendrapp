import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../routes/routes.dart';
import '../../utils/custom_color.dart';
import '../../utils/dimsensions.dart';
import '../../utils/strings.dart';

class DrawerScreen extends StatelessWidget {
  const DrawerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                physics: BouncingScrollPhysics(),
                children: [
                  SizedBox(height: 15),
                  _buildSection(
                    context,
                    "INFORMATIONS",
                    [
                      MenuItemData(
                        title: Strings.aboutUs,
                        icon: FontAwesomeIcons.circleInfo,
                        onTap: () => Get.toNamed(Routes.aboutUsScreen),
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade700, Colors.amber.shade600],
                        ),
                      ),
                      MenuItemData(
                        title: "Politique de confidentialité",
                        icon: Icons.privacy_tip_rounded,
                        onTap: () => _launchPrivacyPolicy(context),
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade700, Colors.purple.shade600],
                        ),
                      ),
                    ],
                  ),

                  _buildSection(
                    context,
                    "COMPTE & PROFIL",
                    [
                      MenuItemData(
                        title: Strings.profile,
                        icon: Icons.person_rounded,
                        onTap: () => Get.toNamed(Routes.profileScreen),
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade700, Colors.blue.shade600],
                        ),
                      ),
                      MenuItemData(
                        title: "Supprimer le compte",
                        icon: Icons.delete_forever_rounded,
                        onTap: () => _showDeleteAccountConfirmation(context),
                        gradient: LinearGradient(
                          colors: [Colors.red.shade800, Colors.red.shade600],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(color: Colors.grey.shade300, thickness: 1.0),
                  ),

                  _buildLogoutButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.22,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CustomColor.primaryColor.withOpacity(0.9),
            CustomColor.primaryColor.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Motif de cercles décoratifs
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Logo centré
          Center(
            child: Container(
              padding: EdgeInsets.all(Dimensions.defaultPaddingSize * 0.8),
              child: Image.asset(
                'assets/images/EPAVIE2.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<MenuItemData> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items.map((item) => _buildMenuItem(context, item)).toList(),
        SizedBox(height: 15),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, MenuItemData item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.grey.withOpacity(0.1),
          highlightColor: Colors.grey.withOpacity(0.05),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: item.gradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: item.gradient.colors.first.withOpacity(0.4),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    item.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
      child: GestureDetector(
        onTap: () => _showLogoutConfirmation(context),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade700, Colors.redAccent.shade400],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade200.withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 1,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.power_settings_new_rounded,
                color: Colors.white,
              ),
              SizedBox(width: 10),
              Text(
                Strings.signOut,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
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
                padding: EdgeInsets.all(8),
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
              SizedBox(width: 12),
              Text(
                "Déconnexion",
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
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
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                "Annuler",
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
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Se déconnecter",
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
      GetSnackBar(
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
              "Déconnexion en cours...",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: CustomColor.primaryColor,
        duration: Duration(milliseconds: 1200),
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

    // Petite pause pour l'animation
    await Future.delayed(Duration(milliseconds: 800));

    // Rediriger vers l'écran de connexion
    Get.offAllNamed(Routes.signInScreen);
  }

  Future<void> _launchPrivacyPolicy(BuildContext context) async {
    // Effet de transition avant le lancement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade600),
                ),
                SizedBox(height: 15),
                Text(
                  "Chargement de la politique de confidentialité...",
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    final Uri url = Uri.parse('https://www.privacypolicies.com/live/12076de3-e527-407e-b179-24c0007dde47');
    try {
      await Future.delayed(Duration(milliseconds: 700)); // Pause pour l'animation
      Navigator.of(context).pop(); // Fermer le dialogue

      await launchUrl(
        url,
        mode: LaunchMode.inAppWebView,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Fermer le dialogue en cas d'erreur
      // Afficher un message d'erreur plus élégant
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                ),
                SizedBox(width: 10),
                Text("Échec de connexion"),
              ],
            ),
            content: Text(
              "Impossible d'accéder à la politique de confidentialité. Veuillez vérifier votre connexion internet et réessayer.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "OK",
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
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Supprimer le compte",
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
                "⚠️ ATTENTION",
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Cette action est définitive et irréversible. Toutes vos données seront supprimées définitivement :",
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "• Votre profil utilisateur\n• Vos données personnelles\n• Votre historique\n• Toutes vos informations",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 15),
              Text(
                "Êtes-vous sûr(e) de vouloir continuer ?",
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
                "Annuler",
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
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                "Supprimer",
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
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
              SizedBox(height: 15),
              Text(
                "Suppression du compte en cours...",
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
        _showErrorDialog(
          context,
          "Erreur de données",
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
      final requestBody = json.encode({
        "telephone": phone
      });

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
                SizedBox(width: 10),
                Text(
                  "Compte supprimé",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              responseData['message'] ?? "Votre compte a été supprimé avec succès.",
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
                child: Text("OK"),
              ),
            ],
          ),
          barrierDismissible: false,
        );

      } else if (response.statusCode == 401) {
        // Non autorisé
        debugPrint('Erreur 401: Non autorisé');
        _showErrorDialog(
          context,
          "Erreur d'autorisation",
          "Votre session a expiré. Veuillez vous reconnecter et réessayer.",
        );
      } else {
        // Autres erreurs
        debugPrint('Erreur ${response.statusCode}: $responseBody');

        // Tenter de décoder la réponse d'erreur
        try {
          final errorData = json.decode(responseBody);
          _showErrorDialog(
            context,
            "Erreur de suppression",
            errorData['message'] ?? "Une erreur est survenue lors de la suppression du compte.",
          );
        } catch (e) {
          _showErrorDialog(
            context,
            "Erreur de suppression",
            "Une erreur est survenue lors de la suppression du compte.",
          );
        }
      }

    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      Get.back();

      debugPrint('Exception lors de la suppression: $e');

      _showErrorDialog(
        context,
        "Erreur de connexion",
        "Impossible de contacter le serveur. Vérifiez votre connexion internet et réessayez.",
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
            SizedBox(width: 10),
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
            child: Text("OK"),
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
  final LinearGradient gradient;

  const MenuItemData({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.gradient,
  });
}