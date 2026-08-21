import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:walletium/views/screens/vehicule_screen.dart';
import '../../utils/strings.dart';
import 'carto.dart';
import 'dommages_screen.dart';
import 'enlevement_screen.dart';
import 'informationBase_screen.dart';
import 'infraction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DepositMoneyDetailsScreen extends StatefulWidget {
  DepositMoneyDetailsScreen({Key? key}) : super(key: key);

  @override
  _DepositMoneyDetailsScreenState createState() =>
      _DepositMoneyDetailsScreenState();
}

class _DepositMoneyDetailsScreenState extends State<DepositMoneyDetailsScreen> {
  late Future<Map<String, dynamic>> signalementDataFuture = Future.value({});
  bool isLoading = true;
  Map<String, dynamic> signalementData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchSignalementData();
    });
  }

  Future<Map<String, dynamic>> fetchSignalementDetails(int signalementId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Strings.apiURI + 'listerSignalement/$signalementId';
    final headers = {'Authorization': 'Bearer $token'};

    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse.containsKey('data') && jsonResponse['data'].isNotEmpty) {
        return jsonResponse['data'][0];
      } else {
        throw Exception('Aucune donnée trouvée pour ce signalement');
      }
    } else {
      throw Exception('Erreur de chargement des détails du signalement');
    }
  }

  Future<void> fetchSignalementData() async {
    try {
      final signalementId = ModalRoute.of(context)!.settings.arguments.toString();
      signalementDataFuture = fetchSignalementDetails(int.parse(signalementId));
      signalementData = await signalementDataFuture;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Erreur: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _showRouteToSignalement() async {
    try {
      // Vérifier si les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Si les services de localisation ne sont pas activés, demandez à l'utilisateur de les activer
        _showLocationServiceDialog();
        return;
      }

      // Vérifier et demander la permission de localisation si nécessaire
      LocationPermission permission = await Geolocator.checkPermission();

      // Si les permissions ne sont pas accordées, demandez la permission
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        // Si la permission est refusée ou refusée définitivement, demander la permission
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          // Si l'utilisateur refuse toujours la permission, affichez un message
          _showPermissionDeniedDialog();
          return;
        }
      }
      // Récupérer la position du signalement
      double signalementLat = double.parse(signalementData['latitude'].toString());
      double signalementLng = double.parse(signalementData['longitude'].toString());

      // Rediriger vers NavigationScreen avec les coordonnées du signalement
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NavigationScreen(
            latitude: signalementLat,
            longitude: signalementLng,
          ),
        ),
      );
      /*
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapScreen(
            currentLocation: LatLng(currentPosition.latitude, currentPosition.longitude),
            destinationLocation: LatLng(signalementLat, signalementLng),
          ),
        ),
      );
       */
    } catch (e) {
      print('Erreur lors de la récupération de la position : $e');
    }
  }

// Affiche un message demandant à l'utilisateur d'activer les services de localisation
  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Services de localisation désactivés'),
          content: Text('Veuillez activer les services de localisation pour continuer.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

// Affiche un message informant l'utilisateur que l'autorisation de localisation est nécessaire
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.orange, size: 32), // Icône d'erreur plus grande
              SizedBox(width: 15),
              Expanded(
                child: Text(
                  'Autorisation de localisation requise !',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 18, // Augmenter la taille de la police pour une meilleure visibilité
                  ),
                  softWrap: true, // Permet au texte de passer à la ligne
                  overflow: TextOverflow.visible, // Pas d'ellipses, texte complet
                ),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0), // Ajout d'un peu de padding autour du texte
            child: Text(
              'Pour afficher l\'itinéraire, veuillez activer la localisation dans les paramètres de votre appareil.',
              style: TextStyle(fontSize: 16, height: 1.5), // Augmentation de la lisibilité
              softWrap: true, // Permet au texte de passer à la ligne
              textAlign: TextAlign.center, // Centrer le texte pour une meilleure présentation
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Coins arrondis plus marqués pour un effet plus moderne
          ),
          elevation: 6, // Ajouter une ombre pour un effet flottant
          backgroundColor: Colors.white, // Fond blanc pour un contraste plus marqué
          actionsPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Espacement des boutons
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue, // Couleur du texte
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Coins arrondis du bouton
                ),
                backgroundColor: Colors.blue.withValues(alpha: 0.1), // Fond léger pour le bouton
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Un peu de padding pour le bouton
                child: Text(
                  'OK',
                  style: TextStyle(fontSize: 16), // Taille de police du bouton
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Constatation',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,  // Ajout du gras
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: isLoading
            ? _buildLoading()
            : FutureBuilder<Map<String, dynamic>>(
                future: signalementDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoading();
                  } else if (snapshot.hasError) {
                    print('Erreur: ${snapshot.error}');
                    return _buildError();
                  } else if (snapshot.hasData) {
                    return _buildContent(snapshot.data!);
                  } else {
                    return _buildError();
                  }
                },
              ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> signalementData) {
    return RefreshIndicator(
      onRefresh: fetchSignalementData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _localisationButton(),
            _menuItem('Informations de base', signalementData),
            _menuItem('Véhicule', signalementData),
            _menuItem('Infraction', signalementData),
            _menuItem('Dommages', signalementData),
            if (signalementData['dommages_saisis'] == true &&
                signalementData['is_approve'] != true)
              _approvalStatus(signalementData['etat']?.toString()),
            if (signalementData['is_approve'] == true)
              _menuItem('Enlèvement', signalementData),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _approvalStatus(String? etat) {
    final rejected = etat == 'REJETE';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Card(
        color: rejected ? Colors.red.shade50 : Colors.orange.shade50,
        child: ListTile(
          leading: Icon(
            rejected ? Icons.cancel_outlined : Icons.hourglass_top,
            color: rejected ? Colors.red : Colors.orange.shade800,
          ),
          title: Text(
            rejected
                ? 'Demande d’approbation rejetée'
                : 'En attente d’approbation administrative',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            rejected
                ? 'L’enlèvement reste indisponible.'
                : 'Faites glisser la page vers le bas pour actualiser le statut.',
          ),
        ),
      ),
    );
  }

  Widget _localisationButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: _showRouteToSignalement,
        icon: Icon(
          Icons.location_on,
          size: 30.0, // Augmenter la taille de l'icône pour plus de visibilité
        ),
        label: Text(
          'Voir l\'itinéraire',
          style: TextStyle(
            fontSize: 18.0, // Augmenter la taille du texte pour une meilleure lisibilité
            fontWeight: FontWeight.bold, // Rendre le texte plus audacieux
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700], // Couleur de fond verte
          foregroundColor: Colors.white, // Couleur du texte et de l'icône en blanc
          padding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 24.0), // Espacement équilibré
          textStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold), // Texte plus lisible
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // Coins plus arrondis pour un effet moderne
          ),
          elevation: 6.0, // Ajouter de l'ombre pour donner du relief au bouton
          shadowColor: Colors.green[600], // Ombre verte pour un effet plus doux
          splashFactory: InkRipple.splashFactory, // Effet de splash plus dynamique
        ),
      ),
    );
  }


  Widget _menuItem(String title, [Map<String, dynamic>? signalementData]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Card(
        elevation: 4.0, // Augmentation de l'élévation pour un effet de profondeur
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // Coins arrondis plus prononcés
        ),
        color: Colors.white, // Couleur de fond claire
        shadowColor: Colors.grey.withValues(alpha: 0.5), // Ombre douce
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          leading: Icon(
            _getIconForTitle(title), // Fonction pour obtenir l'icône en fonction du titre
            size: 28.0, // Taille de l'icône augmentée
            color: Colors.blue, // Icônes colorées
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600, // Police plus lourde
              fontSize: 18.0, // Taille du texte légèrement agrandie
              color: Colors.black, // Couleur noire pour un meilleur contraste
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey, // Icône de navigation dans une couleur discrète
          ),
          onTap: () async {
            final signalementId = signalementData?['signalementId'];
            if (title == 'Informations de base') {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => BasicInfoForm(
                  signalementData: signalementData!,
                ),
              ));
            } else if (title == 'Véhicule') {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => VehicleForm(
                  signalementId: signalementId,
                ),
              ));
            } else if (title == 'Infraction') {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => InfractionForm(signalementId: signalementId),
              ));
            } else if (title == 'Dommages') {
              final updated = await Navigator.of(context).push<bool>(MaterialPageRoute(
                builder: (context) => DommagesScreen(
                  signalementId: signalementId,
                ),
              ));
              if (updated == true && mounted) {
                await fetchSignalementData();
              }
            } else if (title == 'Enlèvement') {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => RemovalForm(signalementId: signalementId),
              ));
            }
          },
        ),
      ),
    );
  }

// Fonction pour obtenir l'icône correspondante en fonction du titre
  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'Informations de base':
        return Icons.library_books; // Icône de livre ou de données (plus spécifique pour les informations)
      case 'Véhicule':
        return Icons.directions_car_filled; // Icône de voiture remplie (plus explicite)
      case 'Infraction':
        return Icons.report_problem; // Icône de rapport de problème (plus adapté aux infractions)
      case 'Dommages':
        return Icons.draw; // Icône de rapport pour dommages (plus approprié)
        //return Icons.report_problem;; // Icône de rapport pour dommages (plus approprié)
      case 'Enlèvement':
        return Icons.remove_circle; // Icône de suppression définitive (plus explicite pour "enlèvement")
      default:
        return Icons.list; // Icône de liste générique pour un menu
    }
  }


  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Text(
        'Échec du chargement des détails du signalement.',
        style: TextStyle(
          color: Colors.red,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
