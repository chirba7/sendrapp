import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/services/offline_signalement_service.dart';
import 'firebase_options.dart';
import 'utils/app_prefs.dart';
import 'utils/sendra_theme.dart';
import 'package:http/http.dart' as http;
import 'demo/demo.dart';
import 'package:walletium/services/session_client.dart';

void main() {
  // Démo web (--dart-define=DEMO=true) : faux serveur, photos d'exemple et
  // position fixe à Dakar. Les versions Android ne sont pas concernées.
  if (kDemo) {
    final reseau = http.Client();
    Demo.installer();
    http.runWithClient(_demarrer, () => Demo.client(reseau));
    return;
  }
  // Toutes les requêtes de l'app passent par SessionClient : retour à
  // l'écran de connexion quand la session a expiré (30/10/2026).
  final reseau = http.Client();
  http.runWithClient(_demarrer, () => SessionClient(reseau));
}

Future<void> _demarrer() async {
  WidgetsFlutterBinding.ensureInitialized();

  // En production, les traces de débogage ne doivent ni ralentir l'app ni
  // exposer de données (réponses d'API, jetons) dans les logs du téléphone.
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // En production, un bloc qui plante affichait une zone grise ou blanche
  // muette. On montre un encart lisible : le reste de la page reste
  // utilisable et le message peut être remonté tel quel.
  ErrorWidget.builder = (FlutterErrorDetails details) => Material(
        color: const Color(0xFFFFF4E5),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Cette partie n’a pas pu s’afficher.\n${details.exceptionAsString()}',
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF8A4B00), fontSize: 12.5),
          ),
        ),
      );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(SendraTheme.overlayGreen);

  // Firebase et les préférences sont chargés en parallèle : le splash natif
  // reste affiché pendant ce temps, sans écran blanc intermédiaire.
  await Future.wait([
    if (!kDemo) Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    AppPrefs.init(),
  ]);

  runApp(const MyApp());

  // Renvoie les signalements créés hors ligne dès qu'une connexion est
  // disponible — démarré après le premier rendu pour ne pas le retarder.
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => OfflineSignalementService.instance.demarrerSynchroAuto(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tailles en dp natifs de Flutter (plus de mise à l'échelle sur une
    // maquette 414 × 896) : les écrans s'adaptent par leurs contraintes,
    // y compris sur un Fold fermé où le texte devenait minuscule.
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'epaVie',
      theme: SendraTheme.light,
      initialRoute: Routes.splashScreen,
      getPages: Routes.list,
      // Transition unique, courte et fluide pour toutes les pages.
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 280),
      // Remarque : l'ancien GetObserver écrivait la route courante dans
      // SharedPreferences à CHAQUE navigation (écriture disque sur le
      // thread UI) alors que cette valeur n'était plus jamais relue.
      builder: (context, widget) {
        // Respecte la taille de texte du téléphone, dans une plage qui
        // ne casse pas les mises en page.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.15,
            ),
          ),
          child: widget!,
        );
      },
    );
  }
}
