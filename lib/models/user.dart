class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? token;
  final List<String>? assignedLocations;
  final Map<String, dynamic>? notifications;
  final String? fcmToken;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
    this.assignedLocations,
    this.notifications,
    this.fcmToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      token: json['token'],
      assignedLocations: json['assignedLocations'] != null 
          ? (json['assignedLocations'] as List).map((e) {
              if (e is String) return e;
              if (e is Map) return e['_id']?.toString() ?? e['id']?.toString() ?? '';
              return e.toString();
            }).where((e) => e.isNotEmpty).toList().cast<String>()
          : null,
      notifications: json['notifications'] as Map<String, dynamic>?,
      fcmToken: json['fcmToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'token': token,
      'assignedLocations': assignedLocations,
      'notifications': notifications,
      'fcmToken': fcmToken,
    };
  }
}
