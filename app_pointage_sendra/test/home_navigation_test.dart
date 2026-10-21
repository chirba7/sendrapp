import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sendra_pointage/pointage_controller.dart';
import 'package:sendra_pointage/screens/home_screen.dart';

void main() {
  testWidgets('le menu ouvre les statistiques des derniers pointages', (
    tester,
  ) async {
    final controller = PointageController()
      ..user = {
        'id': 1,
        'first_name': 'Awa',
        'last_name': 'Diop',
        'telephone': '770000000',
      }
      ..status = 'approved'
      ..assignment = {
        'site': {'name': 'Dépôt Dakar'},
      }
      ..history = [
        {
          'work_date': '2026-10-10',
          'arrived_at': '2026-10-10T08:00:00Z',
          'break_started_at': '2026-10-10T12:00:00Z',
          'break_ended_at': '2026-10-10T13:00:00Z',
          'departed_at': '2026-10-10T17:00:00Z',
        },
      ];
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(controller: controller)),
    );
    await tester.tap(find.byTooltip('Ouvrir le menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Confidentialité'), findsOneWidget);
    await tester.tap(find.text('Statistiques'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Vos pointages récents'), findsOneWidget);
    expect(find.text('10/10/2026'), findsOneWidget);
    controller.dispose();
  });
}
