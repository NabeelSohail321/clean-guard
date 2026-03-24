class Location {
  final String id;
  final String name;
  final String? address;
  final String? type;

  Location({
    required this.id,
    required this.name,
    this.address,
    this.type,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'address': address,
      'type': type,
    };
  }
}
