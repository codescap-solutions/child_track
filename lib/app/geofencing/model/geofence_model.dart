import 'package:equatable/equatable.dart';

class Geofence extends Equatable {
  final String? id;
  final String? name;
  final String? category;
  final int? radius;
  final String? childId;
  final String? parentId;
  final double? latitude;
  final double? longitude;
  final bool? isLocked;
  final bool? isChildInside;
  final String? createdAt;
  final String? updatedAt;

  const Geofence({
    this.id,
    this.name,
    this.category,
    this.radius,
    this.childId,
    this.parentId,
    this.latitude,
    this.longitude,
    this.isLocked,
    this.isChildInside,
    this.createdAt,
    this.updatedAt,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) {
    return Geofence(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      radius: json['radius'] ?? 0,
      childId: json['child_id'],
      parentId: json['parent_id'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isLocked: json['is_locked'] ?? false,
      isChildInside: json['is_child_inside'] ?? false,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'radius': radius,
      'child_id': childId,
      'parent_id': parentId,
      'latitude': latitude,
      'longitude': longitude,
      'is_locked': isLocked,
      'is_child_inside': isChildInside,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Geofence copyWith({
    String? id,
    String? name,
    String? category,
    int? radius,
    String? childId,
    String? parentId,
    double? latitude,
    double? longitude,
    bool? isLocked,
    bool? isChildInside,
    String? createdAt,
    String? updatedAt,
  }) {
    return Geofence(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      radius: radius ?? this.radius,
      childId: childId ?? this.childId,
      parentId: parentId ?? this.parentId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLocked: isLocked ?? this.isLocked,
      isChildInside: isChildInside ?? this.isChildInside,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    radius,
    childId,
    parentId,
    latitude,
    longitude,
    isLocked,
    isChildInside,
    createdAt,
    updatedAt,
  ];
}

class CreateGeofenceRequest extends Equatable {
  final String name;
  final String category;
  final int radius;
  final String childId;
  final String parentId;
  final double latitude;
  final double longitude;
  final bool isLocked;

  const CreateGeofenceRequest({
    required this.name,
    required this.category,
    required this.radius,
    required this.childId,
    required this.parentId,
    required this.latitude,
    required this.longitude,
    this.isLocked = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'radius': radius,
      'child_id': childId,
      'parent_id': parentId,
      'latitude': latitude,
      'longitude': longitude,
      'is_locked': isLocked,
    };
  }

  @override
  List<Object?> get props => [
    name,
    category,
    radius,
    childId,
    parentId,
    latitude,
    longitude,
    isLocked,
  ];
}

class UpdateGeofenceRequest extends Equatable {
  final String? name;
  final String? category;
  final int? radius;
  final double? latitude;
  final double? longitude;

  const UpdateGeofenceRequest({
    this.name,
    this.category,
    this.radius,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (radius != null) 'radius': radius,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  @override
  List<Object?> get props => [name, category, radius, latitude, longitude];
}

class PlaceAutocompleteResult extends Equatable {
  final String? placeId;
  final String? mainText;
  final String? secondaryText;
  final String? description;

  const PlaceAutocompleteResult({
    this.placeId,
    this.mainText,
    this.secondaryText,
    this.description,
  });

  factory PlaceAutocompleteResult.fromJson(Map<String, dynamic> json) {
    return PlaceAutocompleteResult(
      placeId: json['place_id'],
      mainText: json['main_text'],
      secondaryText: json['secondary_text'],
      description: json['description'],
    );
  }

  @override
  List<Object?> get props => [placeId, mainText, secondaryText, description];
}
