import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/models/location.dart';

class Ticket {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final Location? location;
  final User? assignedTo;
  final User? createdBy;
  final DateTime createdAt;
  final DateTime? scheduledDate;
  final DateTime? dueDate;

  final String? resolutionNotes;
  final List<String>? resolutionImages;
  final String? resolvedBy;
  final DateTime? resolvedAt;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.location,
    this.assignedTo,
    this.createdBy,
    required this.createdAt,
    this.scheduledDate,
    this.dueDate,
    this.resolutionNotes,
    this.resolutionImages,
    this.resolvedBy,
    this.resolvedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'open',
      priority: json['priority'] ?? 'medium',
      location: json['location'] != null ? Location.fromJson(json['location'] is Map ? json['location'] : {}) : null,
      assignedTo: json['assignedTo'] != null ? User.fromJson(json['assignedTo'] is Map ? json['assignedTo'] : {}) : null,
      createdBy: json['createdBy'] != null 
          ? (json['createdBy'] is Map 
              ? User.fromJson(json['createdBy']) 
              : User(id: json['createdBy'], name: 'Unknown', email: '', role: '')) 
          : null,
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
      scheduledDate: json['scheduledDate'] != null ? DateTime.parse(json['scheduledDate']).toLocal() : null,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']).toLocal() : null,
      resolutionNotes: json['resolutionNotes'],
      resolutionImages: json['resolutionImages'] != null ? List<String>.from(json['resolutionImages']) : null,
      resolvedBy: json['resolvedBy'] is Map ? json['resolvedBy']['_id'] : json['resolvedBy'],
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']).toLocal() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'location': location?.toJson(),
      'assignedTo': assignedTo?.toJson(),
      'createdBy': createdBy?.toJson() ?? createdBy?.id, // Handle full object or ID
      'createdAt': createdAt.toIso8601String(),
      'scheduledDate': scheduledDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'resolutionNotes': resolutionNotes,
      'resolutionImages': resolutionImages,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }
}
