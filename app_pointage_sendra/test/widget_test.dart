import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sendra_pointage/pointage_controller.dart';
import 'package:sendra_pointage/screens/auth_screen.dart';

void main() {
  testWidgets('la connexion et l’inscription affichent les champs attendus', (tester) async {
    final controller = PointageController();
    await tester.pumpWidget(MaterialApp(home: AuthScreen(controller: controller)));
    expect(find.text('Se connecter'), findsWidgets);
    expect(find.text('Téléphone'), findsOneWidget);
    await tester.tap(find.text('S’inscrire'));
    await tester.pumpAndSettle();
    expect(find.text('Créer votre compte'), findsOneWidget);
    expect(find.text('Prénom'), findsOneWidget);
    expect(find.text('Recevoir un code SMS'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('un compte existant peut récupérer son mot de passe', (tester) async {
    final controller = PointageController();
    await tester.pumpWidget(MaterialApp(home: AuthScreen(controller: controller)));
    await tester.ensureVisible(find.text('Mot de passe oublié ?'));
    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pumpAndSettle();
    expect(find.text('Retrouver votre compte'), findsOneWidget);
    expect(find.text('Recevoir un code SMS'), findsOneWidget);
    expect(find.text('Enregistrer le mot de passe'), findsOneWidget);
    controller.dispose();
  });
}
