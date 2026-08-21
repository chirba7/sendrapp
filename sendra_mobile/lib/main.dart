import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/services/backend_discovery_service.dart';
import 'package:walletium/utils/strings.dart';
import 'firebase_options.dart';

// Observer pour les routes
class RouteObserverMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    return null; // Ne pas rediriger, juste observer
  }

  @override
  GetPageBuilder? onPageBuildStart(GetPageBuilder? page) {
    saveLastRoute(Get.currentRoute);
    return page;
  }
}

Future<void> saveLastRoute(String route) async {
  if (route != Routes.signInScreen) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastRoute', route);
  }
}

Future<String> getInitialRoute() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final lastRoute = prefs.getString('lastRoute');

  if (token != null && token.isNotEmpty) {
    if (lastRoute != null && lastRoute.isNotEmpty && lastRoute != Routes.signInScreen) {
      return lastRoute;
    }
    return Routes.bottomNavigationScreen;
  }
  return Routes.signInScreen;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent)
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Découverte automatique de l'IP LAN du backend local (voir
  // BackendDiscoveryService) — remplace l'IP codée en dur qui cassait à
  // chaque changement de réseau/bail DHCP. Bornée dans le temps pour ne
  // jamais bloquer le démarrage de l'app (repli sur Strings.apiHostLan).
  if (!kIsWeb) {
    try {
      final host = await BackendDiscoveryService.discoverHost()
          .timeout(const Duration(seconds: 5));
      if (host != null) {
        Strings.apiHost = 'http://$host:8000';
      }
    } catch (_) {
      // Repli silencieux sur Strings.apiHostLan déjà en place par défaut.
    }
  }

  final initialRoute = await getInitialRoute();
  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(414, 896),
      builder: (_, child) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
          bottomSheetTheme:
          const BottomSheetThemeData(backgroundColor: Colors.transparent),
        ),
        initialRoute: initialRoute,
        getPages: Routes.list,
        navigatorObservers: [
          GetObserver(
                (route) {
              if (route != null && route.isBottomSheet != true && route.isDialog != true) {
                saveLastRoute(route.current);
              }
            },
          ),
        ],
        navigatorKey: Get.key,
        builder: (context, widget) {
          ScreenUtil.init(context);
          return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: widget!
          );
        },
      ),
    );
  }
}