import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'pointage_controller.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  final controller = PointageController();
  await controller.initialize();
  runApp(PointageApp(controller: controller));
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => FlutterNativeSplash.remove(),
  );
}

class PointageApp extends StatelessWidget {
  const PointageApp({super.key, required this.controller});

  final PointageController controller;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF087A46);
    return MaterialApp(
      title: 'Sendra Pointage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFF4F8F5),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF18352A)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: Color(0xFF667A70)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
      home: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (!controller.isSignedIn) return AuthScreen(controller: controller);
          return HomeScreen(controller: controller);
        },
      ),
    );
  }
}
