class ShelterModel {
  final String id;
  final String name;
  final String nameJa;
  final double lat;
  final double lng;
  final String type;
  final int? capacity;
  final bool isVerified;
  final bool isOpen;

  const ShelterModel({
    required this.id,
    required this.name,
    required this.nameJa,
    required this.lat,
    required this.lng,
    required this.type,
    this.capacity,
    this.isVerified = true,
    this.isOpen = true,
  });

  factory ShelterModel.fromJson(Map<String, dynamic> json) {
    return ShelterModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameJa: json['nameJa'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      type: json['type'] as String,
      capacity: json['capacity'] as int?,
      isVerified: json['isVerified'] as bool? ?? true,
      isOpen: json['isOpen'] as bool? ?? true,
    );
  }
}
