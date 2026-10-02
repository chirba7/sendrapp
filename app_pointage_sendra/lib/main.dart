import 'package:flutter/material.dart';

import 'pointage_controller.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = PointageController();
  runApp(PointageApp(controller: controller));
  controller.initialize();
}

class PointageApp extends StatelessWidget {
  const PointageApp({super.key, required this.controller});

  final PointageController controller;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF00A94F);
    return MaterialApp(
      title: 'Sendra Pointage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFF5FBF7),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Color(0xFF18352A))),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: Color(0xFF667A70)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
      home: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.loadingInitial) {
            return const Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Image(image: AssetImage('assets/sendra_pointage_logo.png'), width: 300),
              SizedBox(height: 28), CircularProgressIndicator(),
            ])));
          }
          if (!controller.isSignedIn) return AuthScreen(controller: controller);
          return HomeScreen(controller: controller);
        },
      ),
    );
  }
}
