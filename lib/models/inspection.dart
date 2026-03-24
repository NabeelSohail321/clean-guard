import 'package:mobile_app/models/location.dart';
import 'package:mobile_app/models/template.dart';
import 'package:mobile_app/models/user.dart';

class Inspection {
  final String id;
  final String? templateId;
  final String? locationId;
  final String? inspectorId;
  final Location? location;
  final User? inspector;
  final Template? template;
  final DateTime? scheduledDate;
  final DateTime? completedDate;
  final String status;
  final double score;
  final double totalScore;
  final bool isDeficient;
  final bool isFlagged;
  final bool isPrivate;
  final String? summaryComment;
  final List<InspectionItem> items;
  final List<InspectionSection>? sections;

  Inspection({
    required this.id,
    this.templateId,
    this.locationId,
    this.inspectorId,
    this.location,
    this.inspector,
    this.template,
    this.scheduledDate,
    this.completedDate,
    required this.status,
    required this.score,
    required this.totalScore,
    this.isDeficient = false,
    this.isFlagged = false,
    this.isPrivate = false,
    this.summaryComment,
    required this.items,
    this.sections,
  });

  factory Inspection.fromJson(Map<String, dynamic> json) {
    return Inspection(
      id: json['_id'] ?? '',
      templateId: json['template'] is String ? json['template'] : json['template']?['_id'],
      locationId: json['location'] is String ? json['location'] : json['location']?['_id'],
      inspectorId: json['inspector'] is String ? json['inspector'] : json['inspector']?['_id'],
      location: json['location'] is Map ? Location.fromJson(json['location']) : null,
      inspector: json['inspector'] is Map ? User.fromJson(json['inspector']) : null,
      template: json['template'] is Map ? Template.fromJson(json['template']) : null,
      scheduledDate: json['scheduledDate'] != null ? DateTime.parse(json['scheduledDate']).toLocal() : null,
      completedDate: json['completedDate'] != null ? DateTime.parse(json['completedDate']).toLocal() : null,
      status: json['status'] ?? 'pending',
      score: (json['score'] ?? 0).toDouble(),
      totalScore: (json['totalScore'] ?? 0).toDouble(),
      isDeficient: json['isDeficient'] ?? false,
      isFlagged: json['isFlagged'] ?? false,
      isPrivate: json['isPrivate'] ?? false,
      summaryComment: json['summaryComment'],
      items: (json['items'] as List?)?.map((e) => InspectionItem.fromJson(e)).toList() ?? [],
      sections: (json['sections'] as List?)?.map((e) => InspectionSection.fromJson(e)).toList(),
    );
  }
}

class InspectionItem {
  final String? templateItemId;
  final String? label;
  final String? type;
  final String status; // pass, fail, N/A
  final int? rating;
  final String? comment;
  final List<String>? photos;
  final double score;

  InspectionItem({
    this.templateItemId,
    this.label,
    this.type,
    required this.status,
    this.rating,
    this.comment,
    this.photos,
    required this.score,
  });

  factory InspectionItem.fromJson(Map<String, dynamic> json) {
    return InspectionItem(
      templateItemId: json['itemId']?.toString() ?? 
                      (json['templateItem'] is String ? json['templateItem'] : json['templateItem']?['_id']?.toString()),
      label: json['name'] ?? json['label'] ?? json['templateItem']?['label'] ?? '',
      type: json['type'],
      status: json['status'] ?? 'N/A',
      rating: json['rating'],
      comment: json['comment'],
      photos: (json['photos'] as List?)?.map((e) => e.toString()).toList(),
      score: (json['score'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'templateItem': templateItemId,
      'label': label,
      'name': label,
      'type': type,
      'status': status,
      'rating': rating,
      'comment': comment,
      'photos': photos,
      'score': score,
    };
  }
}

class InspectionSectionPrompt {
  final String label;
  final String? placeholder;
  final bool required;
  final String? value;

  InspectionSectionPrompt({
    required this.label,
    this.placeholder,
    this.required = false,
    this.value,
  });

  factory InspectionSectionPrompt.fromJson(Map<String, dynamic> json) {
    return InspectionSectionPrompt(
      label: json['label'] ?? '',
      placeholder: json['placeholder'],
      required: json['required'] ?? false,
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'placeholder': placeholder,
      'required': required,
      'value': value,
    };
  }
}

class InspectionSubsection {
  final String? subsectionId;
  final String name;
  final String? parentItemId;
  final int? parentItemIndex;
  final List<InspectionItem> items;

  InspectionSubsection({
    this.subsectionId,
    required this.name,
    this.parentItemId,
    this.parentItemIndex,
    required this.items,
  });

  factory InspectionSubsection.fromJson(Map<String, dynamic> json) {
    return InspectionSubsection(
      subsectionId: json['subsectionId'] ?? json['_id'],
      name: json['name'] ?? '',
      parentItemId: json['parentItemId'],
      parentItemIndex: json['parentItemIndex'],
      items: (json['items'] as List?)?.map((e) => InspectionItem.fromJson(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (subsectionId != null) 'subsectionId': subsectionId,
      'name': name,
      if (parentItemId != null) 'parentItemId': parentItemId,
      if (parentItemIndex != null) 'parentItemIndex': parentItemIndex,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class InspectionSection {
  final String? sectionId;
  final String name;
  final List<InspectionItem> items;
  final InspectionSectionPrompt? sectionPrompt;
  final List<InspectionSubsection>? subsections;

  InspectionSection({
    this.sectionId,
    required this.name,
    required this.items,
    this.sectionPrompt,
    this.subsections,
  });

  factory InspectionSection.fromJson(Map<String, dynamic> json) {
    return InspectionSection(
      sectionId: json['sectionId'] ?? json['_id'],
      name: json['name'] ?? 'Untitled Section',
      items: (json['items'] as List?)?.map((e) => InspectionItem.fromJson(e)).toList() ?? [],
      sectionPrompt: json['sectionPrompt'] != null ? InspectionSectionPrompt.fromJson(json['sectionPrompt']) : null,
      subsections: (json['subsections'] as List?)?.map((e) => InspectionSubsection.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (sectionId != null) 'sectionId': sectionId,
      'name': name,
      'items': items.map((e) => e.toJson()).toList(),
      if (sectionPrompt != null) 'sectionPrompt': sectionPrompt!.toJson(),
      if (subsections != null) 'subsections': subsections!.map((e) => e.toJson()).toList(),
    };
  }
}
