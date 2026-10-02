class Mission {
  const Mission({
    required this.id,
    required this.code,
    required this.title,
    required this.type,
    required this.status,
    required this.scheduledAt,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.checkInRadiusMeters,
    required this.checkedIn,
    required this.vehicles,
    required this.pounds,
    required this.trucks,
    required this.removals,
    required this.dispatches,
    required this.isReceiver,
    required this.receptionCheckedIn,
    required this.removalValidated,
    required this.completed,
    this.receptionPoundName,
    this.providerName,
    this.trailerBrand,
    this.trailerPlate,
  });

  final int id;
  final String code;
  final String title;
  final String type;
  final String status;
  final DateTime? scheduledAt;
  final String address;
  final double latitude;
  final double longitude;
  final double checkInRadiusMeters;
  final bool checkedIn;
  final List<MissionVehicle> vehicles;
  final List<String> pounds;
  final List<MissionTruck> trucks;
  final List<MissionRemoval> removals;
  final List<MissionDispatch> dispatches;
  final bool isReceiver;
  final bool receptionCheckedIn;
  final bool removalValidated;
  final bool completed;
  final String? receptionPoundName;
  final String? providerName;
  final String? trailerBrand;
  final String? trailerPlate;

  bool get isProgrammed =>
      type.toLowerCase() == 'programmee' || type.toLowerCase() == 'programmée';

  factory Mission.fromJson(Map<String, dynamic> json) {
    final rawVehicles = json['vehicles'] ?? json['vehicules'];
    return Mission(
      id: int.tryParse('${json['id']}') ?? 0,
      code: '${json['code'] ?? ''}',
      title: '${json['title'] ?? json['titre'] ?? 'Mission'}',
      type: '${json['type'] ?? 'brute'}',
      status: '${json['status'] ?? json['statut'] ?? 'planifiee'}',
      scheduledAt: DateTime.tryParse(
          '${json['scheduled_at'] ?? json['date_mission'] ?? ''}'),
      address: '${json['address'] ?? json['lieu'] ?? ''}',
      latitude: double.tryParse('${json['latitude'] ?? ''}') ?? 0,
      longitude: double.tryParse('${json['longitude'] ?? ''}') ?? 0,
      checkInRadiusMeters:
          double.tryParse('${json['check_in_radius_meters'] ?? 150}') ?? 150,
      checkedIn: json['checked_in'] == true || json['a_pointe'] == true,
      pounds: json['pounds'] is List
          ? (json['pounds'] as List).map((value) => value.toString()).toList()
          : const [],
      trucks: json['trucks'] is List
          ? (json['trucks'] as List)
              .whereType<Map>()
              .map((item) =>
                  MissionTruck.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      removals: json['removals'] is List
          ? (json['removals'] as List)
              .whereType<Map>()
              .map((item) =>
                  MissionRemoval.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      dispatches: json['dispatches'] is List
          ? (json['dispatches'] as List)
              .whereType<Map>()
              .map((item) =>
                  MissionDispatch.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      isReceiver: json['is_receiver'] == true,
      receptionCheckedIn: json['reception_checked_in'] == true,
      removalValidated: json['removal_validated'] == true,
      completed: json['completed'] == true,
      receptionPoundName: json['reception_pound_name']?.toString(),
      providerName: json['provider_name']?.toString(),
      trailerBrand: json['trailer_brand']?.toString() ??
          json['remorque_marque']?.toString(),
      trailerPlate: json['trailer_plate']?.toString() ??
          json['remorque_immatriculation']?.toString(),
      vehicles: rawVehicles is List
          ? rawVehicles
              .whereType<Map>()
              .map((item) =>
                  MissionVehicle.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }
}

class MissionTruck {
  const MissionTruck(
      {required this.id,
      this.brand,
      this.registration,
      this.driverName,
      this.seats,
      this.destinationPoundName});
  final int id;
  final String? brand;
  final String? registration;
  final String? driverName;
  final int? seats;
  final String? destinationPoundName;

  factory MissionTruck.fromJson(Map<String, dynamic> json) => MissionTruck(
        id: int.tryParse('${json['id']}') ?? 0,
        brand: json['trailer_brand']?.toString(),
        registration: json['registration']?.toString(),
        driverName: json['driver_name']?.toString(),
        seats: int.tryParse('${json['seats'] ?? ''}'),
        destinationPoundName: json['destination_pound_name']?.toString(),
      );
}

class MissionRemoval {
  const MissionRemoval(
      {required this.id,
      this.carPositionId,
      this.truckId,
      this.dispatchId,
      required this.label,
      this.plate,
      this.poundName,
      this.sheetPhotoUrl,
      required this.received,
      required this.receptionPhotos,
      required this.photos});
  final int id;
  final int? carPositionId;
  final int? truckId;
  final int? dispatchId;
  final String label;
  final String? plate;
  final String? poundName;
  final String? sheetPhotoUrl;
  final bool received;
  final Map<String, String> receptionPhotos;
  final Map<String, String> photos;

  factory MissionRemoval.fromJson(Map<String, dynamic> json) => MissionRemoval(
        id: int.tryParse('${json['id']}') ?? 0,
        carPositionId: int.tryParse('${json['car_position_id'] ?? ''}'),
        truckId: int.tryParse('${json['mission_truck_id'] ?? ''}'),
        dispatchId: int.tryParse('${json['dispatch_id'] ?? ''}'),
        label: '${json['vehicle_label'] ?? 'Véhicule'}',
        plate: json['plate']?.toString(),
        poundName: json['pound_name']?.toString(),
        sheetPhotoUrl: json['sheet_photo_url']?.toString(),
        received: json['received'] == true,
        receptionPhotos: json['reception_photos'] is Map
            ? Map<String, String>.from((json['reception_photos'] as Map)
                .map((key, value) => MapEntry('$key', '$value')))
            : const {},
        photos: json['photos'] is Map
            ? Map<String, String>.from((json['photos'] as Map)
                .map((key, value) => MapEntry('$key', '$value')))
            : const {},
      );
}

class MissionDispatch {
  const MissionDispatch(
      {required this.id,
      required this.truckId,
      required this.poundName,
      this.departedAt,
      this.sheetPhotoUrl});
  final int id;
  final int truckId;
  final String poundName;
  final DateTime? departedAt;
  final String? sheetPhotoUrl;

  factory MissionDispatch.fromJson(Map<String, dynamic> json) =>
      MissionDispatch(
        id: int.tryParse('${json['id']}') ?? 0,
        truckId: int.tryParse('${json['mission_truck_id']}') ?? 0,
        poundName: '${json['pound_name'] ?? ''}',
        departedAt: DateTime.tryParse('${json['departed_at'] ?? ''}'),
        sheetPhotoUrl: json['sheet_photo_url']?.toString(),
      );
}

class MissionVehicle {
  const MissionVehicle({required this.id, required this.label, this.plate});
  final int id;
  final String label;
  final String? plate;

  factory MissionVehicle.fromJson(Map<String, dynamic> json) => MissionVehicle(
        id: int.tryParse('${json['id']}') ?? 0,
        label:
            '${json['label'] ?? json['marque'] ?? json['title'] ?? 'Véhicule'}',
        plate: json['plate']?.toString() ?? json['immatriculation']?.toString(),
      );
}
