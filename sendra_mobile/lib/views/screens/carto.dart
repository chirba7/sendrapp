import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationScreen extends StatelessWidget {
  final double latitude;
  final double longitude;

  const NavigationScreen(
      {super.key, required this.latitude, required this.longitude});

  Future<void> openGoogleMaps(BuildContext context) async {
    final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);

        // Attendre 1 seconde avant de revenir à l'écran précédent
        await Future.delayed(const Duration(seconds: 1));
        // Une fois Google Maps ouvert, on revient à l'écran précédent
        if (!context.mounted) return;
        Navigator.pop(context);
      } else {
        debugPrint("Impossible d'ouvrir Google Maps.");
        throw 'Impossible d\'ouvrir Google Maps.';
      }
    } catch (e) {
      debugPrint("Exception lors de l'ouverture de Google Maps : $e");
      throw 'Une erreur est survenue : $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Navigation vers l\'épave',
          style: TextStyle(
            // Couleur du texte en blanc
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        // Couleur personnalisée de la barre d'app
        elevation: 8, // Ombre légère sous la barre d'app
      ),
      // Défile si l'écran est trop bas (Fold fermé, clavier) au lieu de
      // déborder.
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // Icône avec effet d'ombre et animation d'échelle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6), // Ombre sous l'icône
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () {
                      // Animation ou action au clic
                    },
                    child: Icon(
                      Icons.directions_car, // Icône de voiture
                      size: 120,
                      color: Colors.green[800],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Vous allez être dirigé vers l\'épave. Appuyez sur le bouton ci-dessous pour commencer la navigation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 40),
                // Bouton avec animation et effets de hover
                GestureDetector(
                  onTap: () {
                    openGoogleMaps(context); // Passer context ici
                  }, // Action lors du clic sur le bouton
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.green[800],
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Naviguer avec Google Maps',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Message supplémentaire ou image
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Assurez-vous que votre GPS est activé pour une navigation fluide.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
