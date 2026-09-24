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

  test('les enlèvements, fiches et destinations des camions sont décodés', () {
    final mission = Mission.fromJson({
      'id': 20,
      'checked_in': true,
      'is_receiver': true,
      'reception_checked_in': true,
      'removal_validated': true,
      'reception_pound_name': 'Fourrière A',
      'trucks': [
        {
          'id': 7,
          'trailer_brand': 'MAN',
          'registration': 'DK-77-AA',
          'destination_pound_name': 'Fourrière A'
        }
      ],
      'removals': [
        {
          'id': 8,
          'vehicle_label': 'Peugeot 406',
          'mission_truck_id': 7,
          'pound_name': 'Fourrière A',
          'sheet_photo_url': 'https://example.test/fiche.jpg',
          'received': true,
          'reception_photos': {
            'sheet': 'https://example.test/reception-fiche.jpg'
          },
          'photos': {'front': 'https://example.test/front.jpg'}
        }
      ],
      'dispatches': [
        {'id': 9, 'mission_truck_id': 7, 'pound_name': 'Fourrière A'}
      ],
    });

    expect(mission.trucks.single.id, 7);
    expect(mission.isReceiver, isTrue);
    expect(mission.receptionCheckedIn, isTrue);
    expect(mission.trucks.single.destinationPoundName, 'Fourrière A');
    expect(mission.removals.single.photos['front'], contains('front.jpg'));
    expect(mission.removals.single.sheetPhotoUrl, contains('fiche.jpg'));
    expect(mission.removals.single.received, isTrue);
    expect(mission.dispatches.single.poundName, 'Fourrière A');
  });
}
