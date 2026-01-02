import 'package:google_maps_flutter/google_maps_flutter.dart';

class SavedPlace {
  final String? id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final String? description;
  final List<String> children; // IDs of children, empty means all
  final DateTime? savedAt;

  SavedPlace({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.description,
    this.children = const [],
    this.savedAt,
  });

  LatLng get location => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': {
        'latitude': latitude,
        'longitude': longitude,
        'place': address,
        'description': description ?? name,
      },
      'children': children,
    };
  }

  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    final addressData = json['address'] as Map<String, dynamic>? ?? {};
    return SavedPlace(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      latitude: (addressData['latitude'] ?? 0).toDouble(),
      longitude: (addressData['longitude'] ?? 0).toDouble(),
      address: addressData['place'] ?? '',
      description: addressData['description'],
      children:
          (json['children'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      savedAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
