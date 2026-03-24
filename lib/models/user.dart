class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? token;
  final List<String>? assignedLocations;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
    this.assignedLocations,
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
    };
  }
}
