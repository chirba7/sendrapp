import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:walletium/views/screens/vehicule_screen.dart';
import '../../utils/session.dart';
import '../../utils/strings.dart';
import '../../utils/sendra_theme.dart';
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
  bool _isStaff = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchSignalementData();
    });
  }

  Future<Map<String, dynamic>> fetchSignalementDetails(
      int signalementId) async {
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
      _isStaff = await Session.isStaff();
      final args = ModalRoute.of(context)!.settings.arguments;

      if (args is Map) {
        // Reçu depuis un écran citoyen (liste "mes signalements") : les
        // données sont déjà complètes, pas de re-fetch via l'API staff-only
        // listerSignalement/{id} (403 pour un citoyen).
        signalementData = Map<String, dynamic>.from(args);
        signalementDataFuture = Future.value(signalementData);
      } else {
        // Reçu depuis un écran staff (liste globale, redirection après
        // enlèvement/dommages) : simple ID, on va chercher le détail à jour.
        final signalementId = int.parse(args.toString());
        signalementDataFuture = fetchSignalementDetails(signalementId);
        signalementData = await signalementDataFuture;
      }

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
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Si la permission est refusée ou refusée définitivement, demander la permission
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          // Si l'utilisateur refuse toujours la permission, affichez un message
          _showPermissionDeniedDialog();
          return;
        }
      }
      // Récupérer la position du signalement
      double signalementLat =
          double.parse(signalementData['latitude'].toString());
      double signalementLng =
          double.parse(signalementData['longitude'].toString());

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
          content: Text(
              'Veuillez activer les services de localisation pour continuer.'),
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
              Icon(Icons.error,
                  color: Colors.orange, size: 32), // Icône d'erreur plus grande
              SizedBox(width: 15),
              Expanded(
                child: Text(
                  'Autorisation de localisation requise !',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize:
                        18, // Augmenter la taille de la police pour une meilleure visibilité
                  ),
                  softWrap: true, // Permet au texte de passer à la ligne
                  overflow:
                      TextOverflow.visible, // Pas d'ellipses, texte complet
                ),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 8.0), // Ajout d'un peu de padding autour du texte
            child: Text(
              'Pour afficher l\'itinéraire, veuillez activer la localisation dans les paramètres de votre appareil.',
              style: TextStyle(
                  fontSize: 16, height: 1.5), // Augmentation de la lisibilité
              softWrap: true, // Permet au texte de passer à la ligne
              textAlign: TextAlign
                  .center, // Centrer le texte pour une meilleure présentation
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                12), // Coins arrondis plus marqués pour un effet plus moderne
          ),
          elevation: 6, // Ajouter une ombre pour un effet flottant
          backgroundColor:
              Colors.white, // Fond blanc pour un contraste plus marqué
          actionsPadding: EdgeInsets.symmetric(
              horizontal: 20, vertical: 10), // Espacement des boutons
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue, // Couleur du texte
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8), // Coins arrondis du bouton
                ),
                backgroundColor: Colors.blue
                    .withValues(alpha: 0.1), // Fond léger pour le bouton
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20), // Un peu de padding pour le bouton
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
        title: const Text('Détail du signalement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        foregroundColor: SendraTheme.ink,
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
    final isApproved = signalementData['is_approve'] == true;
    final isResolved = signalementData['etat']?.toString() == 'ENLEVE';
    // Une fois approuvé (et tant que ce n'est pas résolu), la constatation
    // (infos/véhicule/infraction/dommages) n'est plus l'action prioritaire —
    // elle est repliée dans un seul bouton dépliable, et l'enlèvement (la
    // vraie prochaine étape) est mis en relief. Un signalement résolu
    // retrouve l'affichage à plat des 5 items, comme avant approbation.
    final grouped = _isStaff && isApproved && !isResolved;

    return RefreshIndicator(
      onRefresh: fetchSignalementData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _workflowHeader(signalementData),
            _localisationButton(),
            if (!grouped) _menuItem('Informations de base', signalementData),
            // Le workflow métier (véhicule, infraction, dommages, enlèvement)
            // est réservé au staff côté API (role:1,2,3,4) — masqué pour un
            // citoyen, qui n'a qu'une vue de suivi de son signalement.
            if (_isStaff) ...[
              if (!isApproved) ...[
                _menuItem('Véhicule', signalementData),
                _menuItem('Infraction', signalementData),
                _menuItem('Dommages', signalementData),
                if (signalementData['dommages_saisis'] == true)
                  _approvalStatus(signalementData['etat']?.toString()),
              ] else if (grouped) ...[
                _constatationGroup(signalementData),
                _enlevementHighlight(signalementData),
              ] else ...[
                _menuItem('Véhicule', signalementData),
                _menuItem('Infraction', signalementData),
                _menuItem('Dommages', signalementData),
                _menuItem('Enlèvement', signalementData),
              ],
            ] else
              _citizenStatusCard(signalementData['etat']?.toString()),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _constatationGroup(Map<String, dynamic> signalementData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SendraTheme.border),
        ),
        color: Colors.white,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('📋', style: TextStyle(fontSize: 23)),
            ),
            title: const Text(
              'Constatation',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            subtitle: const Text(
              'Informations, véhicule, infraction, dommages',
              style: TextStyle(color: SendraTheme.muted, fontSize: 12.5),
            ),
            childrenPadding: const EdgeInsets.only(bottom: 6),
            children: [
              _menuItem('Informations de base', signalementData),
              _menuItem('Véhicule', signalementData),
              _menuItem('Infraction', signalementData),
              _menuItem('Dommages', signalementData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _enlevementHighlight(Map<String, dynamic> signalementData) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            final signalementId = signalementData['signalementId'];
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  RemovalForm(signalementId: signalementId),
            ));
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [SendraTheme.green, SendraTheme.forest],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: SendraTheme.green.withValues(alpha: .3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('🚛', style: TextStyle(fontSize: 25)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enlèvement',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Signalement approuvé — prochaine étape',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .85),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _workflowHeader(Map<String, dynamic> data) {
    final status = data['etat']?.toString() ?? 'SIGNALE';
    final color = status == 'ENLEVE'
        ? SendraTheme.green
        : status == 'EN COURS'
            ? SendraTheme.amber
            : Colors.red.shade600;
    final label = status == 'ENLEVE'
        ? 'Résolu'
        : status == 'EN COURS'
            ? 'En cours'
            : status == 'REJETE'
                ? 'Rejeté'
                : 'À constater';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SendraTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              const Spacer(),
              Text(
                'N° ${data['signalementId'] ?? ''}',
                style: const TextStyle(
                    color: SendraTheme.muted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data['titre']?.toString() ?? 'Signalement',
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 18, color: SendraTheme.green),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  data['commune']?.toString() ?? 'Commune non renseignée',
                  style: const TextStyle(color: SendraTheme.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _citizenStatusCard(String? etat) {
    final label = switch (etat) {
      'SIGNALE' => 'Signalement reçu, en attente de traitement',
      'EN COURS' => 'Traitement en cours',
      'ENLEVE' => 'Véhicule enlevé',
      'REJETE' => 'Signalement rejeté',
      _ => 'Statut : ${etat ?? 'inconnu'}',
    };
    final color = switch (etat) {
      'ENLEVE' => Colors.green,
      'REJETE' => Colors.red,
      'EN COURS' => Colors.orange,
      _ => Colors.blueGrey,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Card(
        color: color.withOpacity(0.08),
        child: ListTile(
          leading: Icon(Icons.timeline, color: color),
          title: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          subtitle: const Text(
              'Faites glisser la page vers le bas pour actualiser le statut.'),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: ElevatedButton.icon(
        onPressed: _showRouteToSignalement,
        icon: Icon(
          Icons.location_on,
          size: 22,
        ),
        label: Text(
          'Voir l\'itinéraire',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: SendraTheme.green,
          foregroundColor:
              Colors.white, // Couleur du texte et de l'icône en blanc
          minimumSize: const Size(double.infinity, 52),
          textStyle: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold), // Texte plus lisible
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          splashFactory:
              InkRipple.splashFactory, // Effet de splash plus dynamique
        ),
      ),
    );
  }

  Widget _menuItem(String title, [Map<String, dynamic>? signalementData]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SendraTheme.border),
        ),
        color: Colors.white, // Couleur de fond claire
        child: ListTile(
          contentPadding:
              EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          leading: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _emojiForTitle(title),
              style: const TextStyle(fontSize: 23),
            ),
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
                builder: (context) =>
                    InfractionForm(signalementId: signalementId),
              ));
            } else if (title == 'Dommages') {
              final updated =
                  await Navigator.of(context).push<bool>(MaterialPageRoute(
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

  String _emojiForTitle(String title) {
    return switch (title) {
      'Informations de base' => '📋',
      'Véhicule' => '🚗',
      'Infraction' => '⚠️',
      'Dommages' => '🛠️',
      'Enlèvement' => '🚛',
      _ => '📌',
    };
  }

// Fonction pour obtenir l'icône correspondante en fonction du titre
  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'Informations de base':
        return Icons
            .library_books; // Icône de livre ou de données (plus spécifique pour les informations)
      case 'Véhicule':
        return Icons
            .directions_car_filled; // Icône de voiture remplie (plus explicite)
      case 'Infraction':
        return Icons
            .report_problem; // Icône de rapport de problème (plus adapté aux infractions)
      case 'Dommages':
        return Icons.draw; // Icône de rapport pour dommages (plus approprié)
      //return Icons.report_problem;; // Icône de rapport pour dommages (plus approprié)
      case 'Enlèvement':
        return Icons
            .remove_circle; // Icône de suppression définitive (plus explicite pour "enlèvement")
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
