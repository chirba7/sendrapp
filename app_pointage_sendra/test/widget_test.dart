import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sendra_pointage/pointage_controller.dart';
import 'package:sendra_pointage/pointage_api.dart';
import 'package:sendra_pointage/screens/auth_screen.dart';

void main() {
  testWidgets('la connexion et l’inscription affichent les champs attendus', (
    tester,
  ) async {
    final controller = PointageController();
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(controller: controller)),
    );
    expect(find.text('Se connecter'), findsWidgets);
    expect(find.text('Téléphone'), findsOneWidget);
    await tester.tap(find.text('S’inscrire'));
    await tester.pumpAndSettle();
    expect(find.text('Vos informations'), findsOneWidget);
    expect(find.text('Prénom'), findsOneWidget);
    expect(find.text('Recevoir un code SMS'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('un compte existant peut récupérer son mot de passe', (
    tester,
  ) async {
    final controller = PointageController();
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(controller: controller)),
    );
    await tester.ensureVisible(find.text('Mot de passe oublié ?'));
    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pumpAndSettle();
    expect(find.text('Récupérer mon accès'), findsOneWidget);
    expect(find.text('Recevoir un code SMS'), findsOneWidget);
    expect(find.text('Enregistrer le mot de passe'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('un nouveau code annule la vérification précédente', (
    tester,
  ) async {
    var sent = 0;
    final api = PointageApi(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/check-phone')) {
          return http.Response('{"exists":true}', 200);
        }
        if (request.url.path.endsWith('/send-verification-code')) {
          sent++;
          return http.Response('{"success":true}', 200);
        }
        if (request.url.path.endsWith('/verify-code')) {
          return http.Response('{"success":true}', 200);
        }
        return http.Response('{}', 404);
      }),
    );
    final controller = PointageController(api: api);
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(controller: controller)),
    );
    await tester.ensureVisible(find.text('Mot de passe oublié ?'));
    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '771234567');
    await tester.pump();
    await tester.ensureVisible(find.text('Recevoir un code SMS'));
    await tester.tap(find.text('Recevoir un code SMS'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Code à 6 chiffres'),
      '123456',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Vérifier'));
    await tester.tap(find.text('Vérifier'));
    await tester.pumpAndSettle();
    expect(find.text('Vérifié'), findsOneWidget);
    await tester.ensureVisible(find.text('Renvoyer le code'));
    await tester.tap(find.text('Renvoyer le code'));
    await tester.pumpAndSettle();
    expect(sent, 2);
    expect(find.text('Vérifié'), findsNothing);
    expect(find.text('Vérifier'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('la récupération refuse un numéro sans compte avant le SMS', (
    tester,
  ) async {
    var sent = false;
    final api = PointageApi(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/check-phone')) {
          return http.Response('{"exists":false}', 200);
        }
        sent = true;
        return http.Response('{"success":true}', 200);
      }),
    );
    final controller = PointageController(api: api);
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(controller: controller)),
    );
    await tester.ensureVisible(find.text('Mot de passe oublié ?'));
    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '771234567');
    await tester.pump();
    await tester.ensureVisible(find.text('Recevoir un code SMS'));
    await tester.tap(find.text('Recevoir un code SMS'));
    await tester.pumpAndSettle();
    expect(sent, isFalse);
    expect(find.textContaining('Aucun compte associé'), findsOneWidget);
    controller.dispose();
  });
}
