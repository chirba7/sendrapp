import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/services/offline_signalement_service.dart';
import 'firebase_options.dart';
import 'utils/app_prefs.dart';
import 'utils/sendra_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(SendraTheme.overlayGreen);

  // Firebase et les préférences sont chargés en parallèle : le splash natif
  // reste affiché pendant ce temps, sans écran blanc intermédiaire.
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
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
    return ScreenUtilInit(
      designSize: const Size(414, 896),
      minTextAdapt: true,
      builder: (_, child) => GetMaterialApp(
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
      ),
    );
  }
}
