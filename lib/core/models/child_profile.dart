import 'dart:convert';

class ChildProfile {
  final String childId;
  final String childName;
  final String authToken;
  final String? avatar;
  final DateTime lastActiveAt;
  final String childCode;
  final int? age;

  ChildProfile({
    required this.childId,
    required this.childCode,
    required this.childName,
    required this.authToken,
    this.avatar,
    required this.lastActiveAt,
    this.age,
  });

  Map<String, dynamic> toMap() {
    return {
      'child_id': childId,
      'child_name': childName,
      'child_code': childCode,
      'auth_token': authToken,
      'avatar': avatar,
      'last_active_at': lastActiveAt.toIso8601String(),
      'age': age,
    };
  }

  factory ChildProfile.fromMap(Map<String, dynamic> map) {
    return ChildProfile(
      childCode: map['child_code'] ?? '',
      childId: map['child_id'] ?? '',
      childName: map['child_name'] ?? '',
      authToken: map['auth_token'] ?? '',
      avatar: map['avatar'],
      lastActiveAt: DateTime.parse(
        map['last_active_at'] ?? DateTime.now().toIso8601String(),
      ),
      age: map['age'] != null ? int.tryParse(map['age'].toString()) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChildProfile.fromJson(String source) =>
      ChildProfile.fromMap(json.decode(source));

  ChildProfile copyWith({
    String? childId,
    String? childName,
    String? authToken,
    String? avatar,
    String? childCode,
    DateTime? lastActiveAt,
    int? age,
  }) {
    return ChildProfile(
      childCode: childCode ?? this.childCode,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      authToken: authToken ?? this.authToken,
      avatar: avatar ?? this.avatar,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      age: age ?? this.age,
    );
  }
}
