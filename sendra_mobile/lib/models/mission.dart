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
      {this.brand, this.registration, this.driverName, this.seats});
  final String? brand;
  final String? registration;
  final String? driverName;
  final int? seats;

  factory MissionTruck.fromJson(Map<String, dynamic> json) => MissionTruck(
        brand: json['trailer_brand']?.toString(),
        registration: json['registration']?.toString(),
        driverName: json['driver_name']?.toString(),
        seats: int.tryParse('${json['seats'] ?? ''}'),
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
