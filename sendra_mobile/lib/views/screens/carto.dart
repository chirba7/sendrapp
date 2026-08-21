import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationScreen extends StatelessWidget {
  final double latitude;
  final double longitude;

  NavigationScreen({required this.latitude, required this.longitude});

  Future<void> openGoogleMaps(BuildContext context) async {
    final googleMapsUrl =
    Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving');

    print("Tentative d'ouverture de Google Maps avec l'URL : $googleMapsUrl");

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);

        // Attendre 1 seconde avant de revenir à l'écran précédent
        await Future.delayed(Duration(seconds: 1));
        // Une fois Google Maps ouvert, on revient à l'écran précédent
        Navigator.pop(context);
      } else {
        print("Impossible d'ouvrir Google Maps.");
        throw 'Impossible d\'ouvrir Google Maps.';
      }
    } catch (e) {
      print("Exception lors de l'ouverture de Google Maps : $e");
      throw 'Une erreur est survenue : $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Navigation vers l\'épave',
          style: TextStyle(
            color: Colors.white, // Couleur du texte en blanc
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.green[800], // Couleur personnalisée de la barre d'app
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 8, // Ombre légère sous la barre d'app
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Icône avec effet d'ombre et animation d'échelle
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 6), // Ombre sous l'icône
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
              SizedBox(height: 20),
              Text(
                'Vous allez être dirigé vers l\'épave. Appuyez sur le bouton ci-dessous pour commencer la navigation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 40),
              // Bouton avec animation et effets de hover
              GestureDetector(
                onTap: () {
                  openGoogleMaps(context); // Passer context ici
                }, // Action lors du clic sur le bouton
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.green[800],
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Naviguer avec Google Maps',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
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
    );
  }
}
