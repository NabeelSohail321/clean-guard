class Template {
  final String id;
  final String name;
  final String? description;
  final List<TemplateSection> sections;

  Template({
    required this.id,
    required this.name,
    this.description,
    required this.sections,
  });

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      sections: (json['sections'] as List?)
          ?.map((e) => TemplateSection.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'name': name,
      'description': description,
      'sections': sections.map((e) => e.toJson()).toList(),
    };
  }
}

class TemplateSectionPrompt {
  String label;
  String? placeholder;
  bool required;

  TemplateSectionPrompt({
    required this.label,
    this.placeholder,
    this.required = false,
  });

  factory TemplateSectionPrompt.fromJson(Map<String, dynamic> json) {
    return TemplateSectionPrompt(
      label: json['label'] ?? '',
      placeholder: json['placeholder'],
      required: json['required'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'placeholder': placeholder,
      'required': required,
    };
  }
}

class TemplateSection {
  String id;
  String title;
  List<TemplateItem> items;
  TemplateSectionPrompt? sectionPrompt;
  List<TemplateSection>? subsections;
  int? parentItemIndex;

  TemplateSection({
    this.id = '',
    required this.title,
    required this.items,
    this.sectionPrompt,
    this.subsections,
    this.parentItemIndex,
  });

  factory TemplateSection.fromJson(Map<String, dynamic> json) {
    return TemplateSection(
      id: json['_id'] ?? '',
      title: json['name'] ?? json['title'] ?? '',
      items: (json['items'] as List?)
          ?.map((e) => TemplateItem.fromJson(e))
          .toList() ?? [],
      sectionPrompt: json['sectionPrompt'] != null 
          ? TemplateSectionPrompt.fromJson(json['sectionPrompt']) 
          : null,
      subsections: (json['subsections'] as List?)
          ?.map((e) => TemplateSection.fromJson(e))
          .toList(),
      parentItemIndex: json['parentItemIndex'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'title': title, // or 'name': title if we want to align back
      'name': title,
      'items': items.map((e) => e.toJson()).toList(),
      if (sectionPrompt != null) 'sectionPrompt': sectionPrompt!.toJson(),
      if (subsections != null) 'subsections': subsections!.map((e) => e.toJson()).toList(),
      if (parentItemIndex != null) 'parentItemIndex': parentItemIndex,
    };
  }
}

class TemplateItem {
  String id;
  String label;
  String type; // text, yes_no, pass_fail, rating, photo
  bool required;
  int weight;

  TemplateItem({
    this.id = '',
    required this.label,
    required this.type,
    this.required = false,
    this.weight = 1,
  });

  factory TemplateItem.fromJson(Map<String, dynamic> json) {
    return TemplateItem(
      id: json['_id'] ?? '',
      label: json['name'] ?? json['label'] ?? '',
      type: json['type'] ?? 'text',
      required: json['required'] ?? false,
      weight: json['weight'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'label': label,
      'name': label,
      'type': type,
      'required': required,
      'weight': weight,
    };
  }
}
