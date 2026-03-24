import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/models/template.dart';
import 'package:mobile_app/services/template_service.dart';

class TemplateFormScreen extends StatefulWidget {
  final Template? template;

  const TemplateFormScreen({super.key, this.template});

  @override
  State<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends State<TemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  List<TemplateSection> _sections = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _descriptionController = TextEditingController(text: widget.template?.description ?? '');
    
    if (widget.template != null) {
      // Deep copy to prevent modifying the argument directly
      _sections = widget.template!.sections.map((s) => _copySection(s)).toList();
    } else {
      _sections = [
        TemplateSection(
          title: '', 
          items: [_createEmptyItem()]
        )
      ];
    }
  }

  TemplateItem _createEmptyItem() => TemplateItem(label: '', type: 'pass_fail', weight: 1);
  
  TemplateSection _createEmptySubsection({int? parentItemIndex}) => TemplateSection(
    title: '', 
    items: [_createEmptyItem()], 
    parentItemIndex: parentItemIndex
  );

  TemplateSection _copySection(TemplateSection s) {
    return TemplateSection(
      id: s.id,
      title: s.title,
      sectionPrompt: s.sectionPrompt != null ? TemplateSectionPrompt(
        label: s.sectionPrompt!.label,
        placeholder: s.sectionPrompt!.placeholder,
        required: s.sectionPrompt!.required,
      ) : null,
      items: s.items.map((i) => TemplateItem(
        id: i.id,
        label: i.label,
        type: i.type,
        required: i.required,
        weight: i.weight,
      )).toList(),
      subsections: s.subsections?.map((ss) => _copySection(ss)).toList(),
      parentItemIndex: s.parentItemIndex,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template name is required')));
      return;
    }

    if (_sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least one section is required')));
      return;
    }
    
    for (var i = 0; i < _sections.length; i++) {
       final s = _sections[i];
       if (s.title.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Section \${i+1} title is required')));
          return;
       }
       if (s.items.isEmpty && (s.subsections == null || s.subsections!.isEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"\${s.title}" must have at least one item or sub-area')));
          return;
       }
       for (var j = 0; j < s.items.length; j++) {
          if (s.items[j].label.trim().isEmpty) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item \${j+1} in "\${s.title}" needs a name')));
             return;
          }
       }
       if (s.subsections != null) {
          for (var k = 0; k < s.subsections!.length; k++) {
              final ss = s.subsections![k];
              if (ss.title.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sub-area \${k+1} in "\${s.title}" needs a name')));
                  return;
              }
              if (ss.items.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"\${ss.title}" must have at least one item')));
                  return;
              }
              for (var l = 0; l < ss.items.length; l++) {
                  if (ss.items[l].label.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item \${l+1} in "\${ss.title}" needs a name')));
                      return;
                  }
              }
          }
       }
    }

    setState(() => _isLoading = true);
    try {
      final service = Provider.of<TemplateService>(context, listen: false);
      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'sections': _sections.map((s) => s.toJson()).toList(),
      };

      if (widget.template != null) {
        await service.updateTemplate(widget.template!.id, data);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template updated successfully')));
      } else {
        await service.createTemplate(data);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template created successfully')));
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addSection() {
    setState(() => _sections.add(TemplateSection(title: '', items: [_createEmptyItem()])));
  }

  void _removeSection(int sIdx) {
    if (_sections.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least one section is required')));
      return;
    }
    setState(() => _sections.removeAt(sIdx));
  }

  void _addItem(int sIdx) {
    setState(() => _sections[sIdx].items.add(_createEmptyItem()));
  }

  void _removeItem(int sIdx, int iIdx) {
    setState(() {
      _sections[sIdx].items.removeAt(iIdx);
      // Adjust parent references for sub-areas
      if (_sections[sIdx].subsections != null) {
         final subs = _sections[sIdx].subsections!;
         subs.removeWhere((ss) => ss.parentItemIndex == iIdx);
         for (var ss in subs) {
            if (ss.parentItemIndex != null && ss.parentItemIndex! > iIdx) {
               ss.parentItemIndex = ss.parentItemIndex! - 1;
            }
         }
      }
    });
  }

  void _addSubsection(int sIdx, {int? parentItemIndex}) {
     setState(() {
        _sections[sIdx].subsections ??= [];
        _sections[sIdx].subsections!.add(_createEmptySubsection(parentItemIndex: parentItemIndex));
     });
  }

  void _removeSubsection(int sIdx, int ssIdx) {
     setState(() {
        _sections[sIdx].subsections!.removeAt(ssIdx);
     });
  }

  Widget _buildSectionPrompt(TemplateSection section) {
     return Container(
       margin: const EdgeInsets.only(bottom: 14),
       padding: const EdgeInsets.all(10),
       decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400, style: BorderStyle.none),
          borderRadius: BorderRadius.circular(8),
       ),
       child: CustomPaint(
          painter: DashedBorderPainter(color: Colors.grey.shade400),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                   children: [
                      Expanded(
                        child: TextFormField(
                           initialValue: section.sectionPrompt?.label ?? '',
                           decoration: const InputDecoration(labelText: 'Section Prompt Label (e.g. Location)', isDense: true),
                           onChanged: (val) {
                              section.sectionPrompt ??= TemplateSectionPrompt(label: '');
                              section.sectionPrompt!.label = val;
                              if (val.trim().isEmpty && (section.sectionPrompt?.placeholder == null || section.sectionPrompt!.placeholder!.isEmpty)) {
                                 section.sectionPrompt = null;
                              }
                           },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                           initialValue: section.sectionPrompt?.placeholder ?? '',
                           decoration: const InputDecoration(labelText: 'Placeholder', isDense: true),
                           onChanged: (val) {
                              section.sectionPrompt ??= TemplateSectionPrompt(label: '');
                              section.sectionPrompt!.placeholder = val;
                           },
                        ),
                      ),
                   ],
                ),
                Row(
                   children: [
                      Checkbox(
                         value: section.sectionPrompt?.required ?? false,
                         onChanged: (val) {
                            setState(() {
                               section.sectionPrompt ??= TemplateSectionPrompt(label: '');
                               section.sectionPrompt!.required = val ?? false;
                            });
                         }
                      ),
                      const Text('Required', style: TextStyle(fontSize: 13, color: Colors.black54)),
                   ],
                )
              ],
            ),
          ),
       ),
     );
  }

  Widget _buildItemRow(TemplateItem item, VoidCallback onRemove, {VoidCallback? onAddSubarea}) {
     return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
           border: Border.all(color: Colors.grey.shade300),
           borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
           children: [
              Row(
                 children: [
                    Expanded(
                       flex: 2,
                       child: TextFormField(
                          initialValue: item.label,
                          decoration: const InputDecoration(labelText: 'Item name', isDense: true),
                          onChanged: (val) => item.label = val,
                       )
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                       child: DropdownButtonFormField<String>(
                          initialValue: item.type,
                          decoration: const InputDecoration(labelText: 'Type', isDense: true),
                          items: const [
                             DropdownMenuItem(value: 'pass_fail', child: Text('Pass/Fail')),
                             DropdownMenuItem(value: 'rating_1_5', child: Text('Rating (1-5)')),
                             DropdownMenuItem(value: 'yes_no', child: Text('Yes/No')),
                          ],
                          onChanged: (val) => setState(() => item.type = val ?? 'pass_fail'),
                       )
                    ),
                 ],
              ),
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    Row(
                       children: [
                          Checkbox(
                             value: item.required,
                             visualDensity: VisualDensity.compact,
                             onChanged: (val) => setState(() => item.required = val ?? false)
                          ),
                          const Text('Req', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                          SizedBox(
                             width: 60,
                             child: TextFormField(
                                initialValue: item.weight.toString(),
                                decoration: const InputDecoration(labelText: 'Weight', isDense: true),
                                keyboardType: TextInputType.number,
                                onChanged: (val) => item.weight = int.tryParse(val) ?? 1,
                             ),
                          ),
                       ],
                    ),
                    Row(
                       children: [
                          if (onAddSubarea != null) 
                             TextButton.icon(
                                onPressed: onAddSubarea, 
                                icon: const Icon(Icons.add, size: 14), 
                                label: const Text('Sub-area', style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                             ),
                          IconButton(
                             icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                             onPressed: onRemove,
                             constraints: const BoxConstraints(),
                             padding: const EdgeInsets.all(4),
                          )
                       ],
                    )
                 ],
              )
           ],
        ),
     );
  }

  Widget _buildSubsection(int sIdx, int ssIdx, TemplateSection subsection) {
     return Container(
        margin: const EdgeInsets.only(top: 8, bottom: 12, left: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
           color: Colors.blue.shade50.withValues(alpha: 0.5),
           border: Border.all(color: Colors.blue.shade100),
           borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Row(
                 children: [
                    Expanded(
                       child: TextFormField(
                          initialValue: subsection.title,
                          decoration: InputDecoration(
                             labelText: 'Sub-area \${ssIdx + 1} Name',
                             filled: true,
                             fillColor: Colors.white,
                             isDense: true,
                          ),
                          onChanged: (val) => subsection.title = val,
                       ),
                    ),
                    IconButton(
                       icon: const Icon(Icons.delete, color: Colors.red),
                       onPressed: () => _removeSubsection(sIdx, ssIdx),
                    )
                 ],
              ),
              const SizedBox(height: 12),
              ...subsection.items.asMap().entries.map((itemEntry) => _buildItemRow(
                 itemEntry.value, 
                 () => setState(() => subsection.items.removeAt(itemEntry.key))
              )),
              TextButton.icon(
                 onPressed: () => setState(() => subsection.items.add(_createEmptyItem())),
                 icon: const Icon(Icons.add, size: 16),
                 label: const Text('Add Item'),
                 style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              )
           ],
        ),
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template != null ? 'Edit Template' : 'Create Template'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _save,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Template Name', border: OutlineInputBorder()),
                validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sections', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  OutlinedButton.icon(
                    onPressed: _addSection,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Section'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ..._sections.asMap().entries.map((entry) {
                 final sIdx = entry.key;
                 final section = entry.value;
                 
                 final sectionLevelSubsections = (section.subsections ?? [])
                      .asMap().entries.where((e) => e.value.parentItemIndex == null);

                 return Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    color: Colors.grey.shade50,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
                    child: Padding(
                       padding: const EdgeInsets.all(16),
                       child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Row(
                                children: [
                                   const Icon(Icons.drag_indicator, color: Colors.grey),
                                   const SizedBox(width: 8),
                                   Expanded(
                                      child: TextFormField(
                                         initialValue: section.title,
                                         style: const TextStyle(fontWeight: FontWeight.bold),
                                         decoration: InputDecoration(
                                            labelText: 'Section \${sIdx + 1} Name',
                                            filled: true,
                                            fillColor: Colors.white,
                                            isDense: true,
                                         ),
                                         onChanged: (val) => section.title = val,
                                      ),
                                   ),
                                   IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeSection(sIdx),
                                   )
                                ],
                             ),
                             const SizedBox(height: 16),
                             _buildSectionPrompt(section),
                             
                             ...section.items.asMap().entries.map((itemEntry) {
                                final iIdx = itemEntry.key;
                                final item = itemEntry.value;
                                final itemSubsections = (section.subsections ?? [])
                                      .asMap().entries.where((e) => e.value.parentItemIndex == iIdx);
                                      
                                return Column(
                                   children: [
                                      _buildItemRow(
                                         item, 
                                         () => _removeItem(sIdx, iIdx),
                                         onAddSubarea: () => _addSubsection(sIdx, parentItemIndex: iIdx)
                                      ),
                                      ...itemSubsections.map((ssEntry) => _buildSubsection(sIdx, ssEntry.key, ssEntry.value)),
                                   ],
                                );
                             }),

                             const SizedBox(height: 8),
                             Wrap(
                                spacing: 8,
                                children: [
                                   TextButton.icon(
                                      onPressed: () => _addItem(sIdx),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Add Item'),
                                   ),
                                   TextButton.icon(
                                      onPressed: () => _addSubsection(sIdx),
                                      icon: const Icon(Icons.add_box, size: 16),
                                      label: const Text('Add Sub-area (Section)'),
                                   ),
                                ],
                             ),
                             
                             if (sectionLevelSubsections.isNotEmpty) const Divider(height: 24),
                             ...sectionLevelSubsections.map((ssEntry) => _buildSubsection(sIdx, ssEntry.key, ssEntry.value)),
                          ],
                       ),
                    ),
                 );
              }),
              
              const SizedBox(height: 16),
              ElevatedButton.icon(
                 onPressed: _isLoading ? null : _save,
                 icon: const Icon(Icons.save),
                 label: Text(widget.template != null ? 'Update Template' : 'Create Template'),
                 style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                 ),
              )
            ],
          ),
        ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  DashedBorderPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    var path = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)));

    // A simple approach is just to draw the bounded rect if dashes are complex,
    // or let's just make it a normal grey outline instead of complex dashed path manually.
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
