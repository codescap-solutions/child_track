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
  final String? address;
  final bool? isLocked;
  final bool? isChildInside;
  final String? createdAt;
  final String? updatedAt;
  final int? version; // __v
  final int? totalSpentTime; // in seconds

  const Geofence({
    this.id,
    this.name,
    this.category,
    this.radius,
    this.childId,
    this.parentId,
    this.latitude,
    this.longitude,
    this.address,
    this.isLocked,
    this.isChildInside,
    this.createdAt,
    this.updatedAt,
    this.version,
    this.totalSpentTime,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) {
    final addressData = json['address'] as Map<String, dynamic>? ?? {};
    final childrenArray = json['children'] as List<dynamic>? ?? [];
    final firstChild = childrenArray.isNotEmpty
        ? childrenArray.first.toString()
        : null;

    return Geofence(
      id: json['_id'] as String?,
      name: json['name'] as String?,
      category: json['placeType'] as String?,
      radius: json['radius'] as int?,
      childId: firstChild,
      parentId: json['userId'] as String?,
      latitude: (addressData['latitude'] as num?)?.toDouble(),
      longitude: (addressData['longitude'] as num?)?.toDouble(),
      address: addressData['place'] as String?,
      isLocked: json['notifyOnArrival'] as bool? ?? json['isLocked'] as bool?,
      isChildInside: json['isChildInside'] as bool?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      version: json['__v'] as int?,
      totalSpentTime: json['totalSpentTime'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'category': category,
      'radius': radius,
      'childId': childId,
      'parentId': parentId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'isLocked': isLocked,
      'isChildInside': isChildInside,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': version,
      'totalSpentTime': totalSpentTime,
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
    String? address,
    bool? isLocked,
    bool? isChildInside,
    String? createdAt,
    String? updatedAt,
    int? version,
    int? totalSpentTime,
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
      address: address ?? this.address,
      isLocked: isLocked ?? this.isLocked,
      isChildInside: isChildInside ?? this.isChildInside,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      totalSpentTime: totalSpentTime ?? this.totalSpentTime,
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
    address,
    isLocked,
    isChildInside,
    createdAt,
    updatedAt,
    version,
    totalSpentTime,
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
      'placeType': category, // Replaced category with placeType
      'radius': radius,
      'children': [childId], // Passed childId inside children array
      'address': {'latitude': latitude, 'longitude': longitude},
      'isLocked': isLocked,
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
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (category != null) data['placeType'] = category;
    if (radius != null) data['radius'] = radius;
    if (latitude != null || longitude != null) {
      data['address'] = {};
      if (latitude != null) data['address']['latitude'] = latitude;
      if (longitude != null) data['address']['longitude'] = longitude;
    }
    return data;
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
