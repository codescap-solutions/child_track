import 'dart:convert';

class ChildProfile {
  final String childId;
  final String childName;
  final String authToken;
  final String? avatar;
  final DateTime lastActiveAt;

  ChildProfile({
    required this.childId,
    required this.childName,
    required this.authToken,
    this.avatar,
    required this.lastActiveAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'child_id': childId,
      'child_name': childName,
      'auth_token': authToken,
      'avatar': avatar,
      'last_active_at': lastActiveAt.toIso8601String(),
    };
  }

  factory ChildProfile.fromMap(Map<String, dynamic> map) {
    return ChildProfile(
      childId: map['child_id'] ?? '',
      childName: map['child_name'] ?? '',
      authToken: map['auth_token'] ?? '',
      avatar: map['avatar'],
      lastActiveAt: DateTime.parse(
        map['last_active_at'] ?? DateTime.now().toIso8601String(),
      ),
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
    DateTime? lastActiveAt,
  }) {
    return ChildProfile(
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      authToken: authToken ?? this.authToken,
      avatar: avatar ?? this.avatar,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}
