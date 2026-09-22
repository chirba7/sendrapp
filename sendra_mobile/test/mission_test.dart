import 'package:flutter_test/flutter_test.dart';
import 'package:walletium/models/mission.dart';

void main() {
  test('une mission non pointée ne reçoit pas implicitement de véhicules', () {
    final mission = Mission.fromJson({
      'id': 12,
      'titre': 'Opération Plateau',
      'type': 'programmee',
      'lieu': 'Plateau, Dakar',
      'latitude': '14.6708',
      'longitude': '-17.4381',
      'checked_in': false,
    });

    expect(mission.isProgrammed, isTrue);
    expect(mission.checkedIn, isFalse);
    expect(mission.vehicles, isEmpty);
    expect(mission.checkInRadiusMeters, 150);
  });

  test('les véhicules renvoyés après pointage sont décodés', () {
    final mission = Mission.fromJson({
      'id': 12,
      'type': 'brute',
      'checked_in': true,
      'vehicles': [
        {'id': 4, 'marque': 'Renault', 'immatriculation': 'DK-1234-AA'}
      ],
    });

    expect(mission.checkedIn, isTrue);
    expect(mission.vehicles.single.label, 'Renault');
    expect(mission.vehicles.single.plate, 'DK-1234-AA');
  });
}
