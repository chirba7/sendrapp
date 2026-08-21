import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../routes/routes.dart';
import '../../utils/custom_color.dart';
import '../../utils/custom_style.dart';
import '../../utils/dimsensions.dart';
import '../../utils/size.dart';
import '../../utils/strings.dart';
import '../screens/drawer_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}
class Slide {
  final String title;
  final String description;
  final IconData icon;

  Slide({required this.title, required this.description, required this.icon});
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> allSignalements = [];
  bool _isLoading = false;
  bool _hasNextPage = false;
  bool _allSlidesSeen = false;
  bool _isInitialLoading = true;

  // Déclarez une variable pour suivre l'index de la diapositive actuelle
  int _currentPageIndex = 0;

  // Fonction pour mettre à jour l'index de la diapositive actuelle
  void _updateCurrentPageIndex(int index) {
    setState(() {
      _currentPageIndex = index;
      if (_currentPageIndex == slides.length - 1) {
        _allSlidesSeen = true;
      } else {
        _allSlidesSeen = false;
      }
    });
  }

  late SharedPreferences _prefs;
  bool _showSlides = true;
  bool _showScrollIndicator = true; // Définition de la variable ici
  double _scrollIndicatorPosition = 0; // Position initiale de l'indicateur de défilement
  bool _scrolling = false; // Variable pour indiquer si le défilement est en cours
  double _lastScrollIndicatorPosition = 0.0; // Dernière position de l'indicateur

  late String nextPageUrl;
  String token = '';

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _fetchData();
    getUserData();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final bool hasSeenSlides = _prefs.getBool('hasSeenSlides') ?? false;
    setState(() {
      _showSlides = !hasSeenSlides;
    });
  }

  // Correction : _isInitialLoading n'était remis à false que dans le
  // catch — un chargement RÉUSSI (même avec une liste vide, ex. total: 0)
  // laissait le spinner "Chargement des signalements..." tourner
  // indéfiniment. Le `finally` garantit qu'il se referme dans tous les cas.
  Future<void> _fetchData() async {
    setState(() {
      _isInitialLoading = true;
    });

    try {
      List<dynamic> fetchedSignalements = await fetchSignalements();
      setState(() {
        allSignalements = fetchedSignalements;
      });
    } catch (e) {
      // Handle errors
    } finally {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? 'No name';
    });
  }

  Future<List<dynamic>> fetchSignalements() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';

    final url = Uri.parse(Strings.apiURI + 'listerSignalements');
    print('URL de la requête liste signalements: $url');

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer ' + token,
      },
    );

    print('Statut de la réponse liste signalements: ${response.statusCode}');
    print('Réponse du serveur liste signalements: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _hasNextPage = data['links']['next'] != null;
        nextPageUrl = data['links']['next'] ?? '';
      });
      return data['data'];
    } else if (response.statusCode == 401) {
      // Clear all session data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('userId');
      await prefs.remove('fullName');
      await prefs.remove('phone');
      await prefs.remove('lastRoute');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre session a expiré. Vous allez être redirigé vers la page de connexion.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      Get.offAllNamed(Routes.signInScreen);
      throw Exception('Session expired');
    } else {
      throw Exception('Error fetching signalements: ${response.statusCode}');
    }
  }



  @override
  Widget build(BuildContext context) {
    return _showSlides ? _buildIntroSlides() : _buildHomeScreen();
  }

  final List<Slide> slides = [
    Slide(
      title: "Bienvenue sur l'application",
      description: "Découvrez les fonctionnalités et les informations importantes sur notre application.",
      icon: Icons.mobile_screen_share,
    ),
    Slide(
      title: "Localisation",
      description: "Découvrez comment localiser facilement les véhicules sur la carte.",
      icon: Icons.map,
    ),
    Slide(
      title: "Informations de base",
      description: "Accédez aux informations de base concernant chaque signalement.",
      icon: Icons.library_books,
    ),
    Slide(
      title: "Véhicule",
      description: "Ajoutez les détails relatifs au véhicule concerné par le signalement.",
      icon: Icons.directions_car,
    ),
    Slide(
      title: "Infraction",
      description: "Indiquez les infractions associées au signalement pour un traitement approprié.",
      icon: Icons.report_problem,
    ),
    Slide(
      title: "Dommages",
      description: "Dessinez les dommages en utilisant notre outil de dessin.",
      icon: Icons.draw,
    ),
    Slide(
      title: "Approbation",
      description: "Soumettez les signalements pour approbation après vérification.",
      icon: Icons.check_circle,
    ),
    Slide(
      title: "Enlèvement",
      description: "Organisez l'enlèvement des véhicules signalés.",
      icon: Icons.remove_circle,
    ),
  ];


  Widget _buildIntroSlides() {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            itemCount: slides.length,
            onPageChanged: _updateCurrentPageIndex,
            itemBuilder: (context, index) {
              final slide = slides[index];
              return _buildSlide(slide);
            },
          ),
          Positioned(
            bottom: 40,
            right: 20,
            child: ElevatedButton(
              onPressed: _closeSlides,
              child: Text(
                'Commencer',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF1B5E20), // Vert foncé
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor : Colors.white, // Blanc
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Color(0xFF1B5E20)), // Bordure vert foncé
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildPageIndicators(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(Slide slide) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            slide.icon,
            size: 100,
            color: Color(0xFF1B5E20), // Vert foncé
          ),
          SizedBox(height: 20),
          Text(
            slide.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20), // Vert foncé
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              slide.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF1B5E20)), // Vert foncé
            ),
          ),
        ],
      ),
    );
  }

  // Fonction pour construire les indicateurs de pagination
  List<Widget> _buildPageIndicators() {
    List<Widget> indicators = [];
    for (int i = 0; i < slides.length; i++) {
      indicators.add(
        Container(
          width: 10,
          height: 10,
          margin: EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPageIndex == i ? Colors.green : Colors.grey, // Couleur différente pour la diapositive actuelle
          ),
        ),
      );
    }
    return indicators;
  }

  Future<void> _closeSlides() async {
    if (_allSlidesSeen) {
      await _prefs.setBool('hasSeenSlides', true);
      setState(() {
        _showSlides = false;
      });
    } else {
      // Affichez un message à l'utilisateur pour lui indiquer de voir tous les slides.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez parcourir tous les slides avant de continuer.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black, // Couleur de fond de la SnackBar
          elevation: 8, // Élévation pour ajouter une ombre
          behavior: SnackBarBehavior.floating, // Centrer le SnackBar
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Coins arrondis
        ),
      );

    }
  }

  void _showSlidesAgain() async {
    await _prefs.setBool('hasSeenSlides', false);
    setState(() {
      _showSlides = true;
    });
  }

  Widget _buildHomeScreen() {
    return Scaffold(
      backgroundColor: CustomColor.primaryBackgroundColor,
      drawer: const DrawerScreen(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.grey, Colors.green[900]!],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: CustomColor.whiteColor),
        title: Center(
          child: Image.asset(
            'assets/images/EPAVIE2.png',
            fit: BoxFit.contain,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.slideshow),
            onPressed: _showSlidesAgain,
          ),
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  child: contentBox(context),
                ),
              );
            },
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollStartNotification) {
            setState(() {
              _scrolling = true;
            });
          } else if (scrollNotification is ScrollEndNotification) {
            setState(() {
              _scrolling = false;
            });
            if (scrollNotification.metrics.pixels ==
                scrollNotification.metrics.maxScrollExtent) {
              _loadMoreSignalements();
            }
          } else if (scrollNotification is ScrollUpdateNotification) {
            setState(() {
              _scrollIndicatorPosition = scrollNotification.metrics.pixels;
            });
          }
          return true;
        },
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                // Réinitialiser les données et rafraîchir
                setState(() {
                  allSignalements = [];
                  _hasNextPage = false;
                });
                await _fetchData();
              },
              color: Colors.green.shade900, // Couleur du loader assortie à l'app
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                child: Column(
                  children: [
                    if (allSignalements.isNotEmpty)
                      _transactionHistoryWidget(context, allSignalements),
                    if (allSignalements.isEmpty)
                      Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Center(
                          child: _isInitialLoading
                              ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade900),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Chargement des signalements...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                              : Text(
                            'Aucun signalement disponible',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: Visibility(
                visible: _showScrollIndicator,
                child: Container(
                  width: 4.0,
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                    color: Colors.white60.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Align(
                    alignment: Alignment(1, _calculateIndicatorPosition()),
                    child: Container(
                      width: 4.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget contentBox(context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                offset: Offset(0, 10),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 15),
              Text(
                'Les signalements expirent après 10 jours. Après ce délai, pour découvrir de nouveaux signalements, n\'hésitez pas à en effectuer vous-même ou patientez jusqu\'à ce qu\'un autre utilisateur le fasse.\n\n'
                    'Cliquez sur le signalement afin d\'accéder à la constatation.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 22),
              Align(
                alignment: Alignment.bottomCenter,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'OK',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Correction : quand la liste est vide (0 signalement), totalHeight
  // valait 0 -> division par zéro -> NaN -> Alignment(1, NaN) plantait le
  // rendu à CHAQUE frame (RRect argument contained a NaN value), d'où le
  // ralentissement massif observé pendant le chargement/liste vide.
  double _calculateIndicatorPosition() {
    double totalHeight = _getListTotalHeight();
    if (totalHeight <= 0) {
      return -1.0;
    }

    double position;
    if (_scrolling) {
      double scrollPosition = _scrollIndicatorPosition.clamp(0.0, totalHeight);
      position = scrollPosition / totalHeight;
    } else {
      position = _scrollIndicatorPosition / totalHeight;
    }
    return position.clamp(-1.0, 1.0);
  }

  double _getListTotalHeight() {
    double totalHeight = 0;
    for (dynamic signalement in allSignalements) {
      totalHeight += 120;
    }
    return totalHeight;
  }

  void _loadMoreSignalements() async {
    if (!_isLoading && _hasNextPage) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.get(Uri.parse(nextPageUrl), headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ' + token,
        });

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            allSignalements.addAll(data['data']);
            _hasNextPage = data['links']['next'] != null;
            nextPageUrl = data['links']['next'] ?? '';
            _isLoading = false;
          });
        } else {
          throw Exception('Error fetching more signalements');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        // Handle error
      }
    }
  }

  Container _transactionHistoryWidget(
      BuildContext context, List<dynamic> signalements) {
    return Container(
      padding: EdgeInsets.all(Dimensions.defaultPaddingSize * 0.5),
      decoration: BoxDecoration(
        color: Color.fromRGBO(255, 254, 254, 1),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          topLeft: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          addVerticalSpace(20.h),
          Padding(
            padding: EdgeInsets.only(bottom: 30.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.defaultPaddingSize * 0.3),
              child: Center(
                child: Text(
                  Strings.transactionsHistory,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey, // Blanc en haut
                    Colors.green.shade900, // Vert foncé en bas
                  ],
                ),
                borderRadius: BorderRadius.circular(5.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    spreadRadius: 3,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          addVerticalSpace(5.h),
          _transactionHistoryListWidget(context, signalements),
        ],
      ),
    );
  }

  Widget _transactionHistoryListWidget(
      BuildContext context, List<dynamic> signalements) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      itemCount: signalements.length,
      itemBuilder: (BuildContext context, int index) {
        final signalement = signalements[index];

        IconData iconData;
        Color iconColor;
        switch (signalement['etat']) {
          case 'SIGNALE':
            iconData = Icons.visibility;
            iconColor = Colors.red;
            break;
          case 'EN COURS':
            iconData = Icons.visibility;
            iconColor = Colors.orange;
            break;
          case 'ENLEVE':
            iconData = Icons.visibility;
            iconColor = Colors.green;
            break;
          default:
            iconData = Icons.info;
            iconColor = Colors.black;

        }
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/depositMoneyDetailsScreen',
              arguments: signalement['signalementId'],
            );
          },
          child: SizedBox(
            height: 120,
            child: Padding(
              padding: EdgeInsets.all(Dimensions.defaultPaddingSize * 0.3),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 3,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      child: signalement['image_url'] != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.network(
                          signalement['image_url'],
                          fit: BoxFit.cover,
                        ),
                      )
                          : Container(),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                signalement['titre'] ?? '',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            SizedBox(height: 5),
                            Flexible(
                              child: Text(
                                signalement['commune'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),

                            SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.grey[600],
                                  size: 16,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  signalement['formatted_date'] ?? '',
                                  style: TextStyle(
                                    color: Colors.blueGrey,
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          iconData,
                          color: iconColor,
                        ),
                        SizedBox(height: 5),
                        Text(
                          signalement['etat'] == 'SIGNALE' ? 'Signalé' :
                          signalement['etat'] == 'EN COURS' ? 'En cours' : 'Résolu',
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 5),
                    Text(
                      signalement['created_date'] ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


