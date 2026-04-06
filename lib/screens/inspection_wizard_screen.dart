import 'package:flutter/material.dart';
import 'package:mobile_app/models/inspection.dart';
import 'package:mobile_app/models/location.dart';
import 'package:mobile_app/models/template.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/services/inspection_service.dart';
import 'package:mobile_app/services/location_service.dart';
import 'package:mobile_app/services/template_service.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/config/constants.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class InspectionWizardScreen extends StatefulWidget {
  final String? inspectionId; // Add this
  const InspectionWizardScreen({super.key, this.inspectionId});

  @override
  State<InspectionWizardScreen> createState() => _InspectionWizardScreenState();
}

class _InspectionWizardScreenState extends State<InspectionWizardScreen> {
  int _step = 1;
  bool _isLoading = true;
  
  List<Location> _locations = [];
  List<Template> _templates = [];
  List<User> _inspectors = [];
  
  String? _selectedLocationId;
  String? _selectedTemplateId;
  String? _selectedInspectorId;
  Template? _template;
  
  bool _performNow = true;
  
  // State for Wizard Execution
  int _currentSectionIndex = 0;
  // Key format: "$sectionIndex-item-$itemIndex" or "$sectionIndex-sub-$subIndex-item-$itemIndex"
  final Map<String, InspectionItem> _items = {}; 
  final Map<int, String> _sectionPromptValues = {};
  
  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final locService = Provider.of<LocationService>(context, listen: false);
      final tmplService = Provider.of<TemplateService>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final inspectionService = Provider.of<InspectionService>(context, listen: false);

      final futures = <Future<dynamic>>[
        locService.getLocations(),
        tmplService.getTemplates(),
      ];

      final isAdmin = authProvider.user?.role == 'admin' || authProvider.user?.role == 'sub_admin';
      if (isAdmin) {
        futures.add(Provider.of<UserService>(context, listen: false).getUsers());
      }
      
      final results = await Future.wait(futures);
      
      if (mounted) {
        setState(() {
          _locations = results[0] as List<Location>;
          _templates = results[1] as List<Template>;
          
          if (isAdmin && results.length > 2) {
             final allUsers = results[2] as List<User>;
             _inspectors = allUsers.where((u) => u.role == 'supervisor' || u.role == 'inspector').toList();
             if (_inspectors.isEmpty) _inspectors = allUsers; 
          }
        });

      // Handle Resume/Edit existing inspection
        if (widget.inspectionId != null) {
           final inspection = await inspectionService.getInspection(widget.inspectionId!);
           _selectedLocationId = inspection.location?.id ?? inspection.locationId;
           _selectedTemplateId = inspection.template?.id ?? inspection.templateId;
           _selectedInspectorId = inspection.inspector?.id ?? inspection.inspectorId;
           
           if (_selectedTemplateId != null) {
              // Try to find the template in the list, or fetch it individually if not found
              Template? tmpl;
              try {
                tmpl = _templates.firstWhere((t) => t.id == _selectedTemplateId);
              } catch (e) {
                // If not found in list, maybe list is partial? For now, we rely on list. 
                // In a robust app, we should fetch the specific template.
                // Mobile app usually loads all templates or we should fetch this specific one.
                // Let's assume for now we might need to fetch it if missing.
                if (inspection.template != null && inspection.template!.sections.isNotEmpty) {
                   tmpl = inspection.template; 
                } else if (inspection.sections != null && inspection.sections!.isNotEmpty) {
                   // Fallback: Construct template from snapshot
                   tmpl = Template(
                     id: inspection.templateId ?? 'unknown',
                     name: inspection.template?.name ?? 'Inspection',
                     description: '',
                     sections: inspection.sections!.map((s) => TemplateSection(
                       id: s.sectionId ?? '',
                       title: s.name, // Map name to title
                       items: s.items.map((i) => TemplateItem(
                         id: i.templateItemId ?? '',
                         label: i.label ?? 'Item',
                         type: i.type ?? 'text',
                       )).toList(),
                       subsections: s.subsections?.map((ss) => TemplateSection(
                         id: ss.subsectionId ?? '',
                         title: ss.name,
                         items: ss.items.map((i) => TemplateItem(
                           id: i.templateItemId ?? '',
                           label: i.label ?? 'Item',
                           type: i.type ?? 'text',
                         )).toList()
                       )).toList()
                     )).toList(), 
                     // isActive: true,
                     // createdAt: DateTime.now(),
                     // updatedAt: DateTime.now()
                   );
                }
              }

              if (tmpl != null) {
                  _template = tmpl;
                  
                  // Pre-fill items
                  // Flatten sections to map
                  if (inspection.sections != null) {
                     for(var i=0; i<tmpl.sections.length; i++) {
                        final tmplSection = tmpl.sections[i];
                        final sec = inspection.sections!.firstWhere(
                           (s) => s.name == tmplSection.title,
                           orElse: () => InspectionSection(name: '', items: [])
                        );

                        if (sec.sectionPrompt?.value != null) {
                           _sectionPromptValues[i] = sec.sectionPrompt!.value!;
                        }

                        for(var j=0; j<tmplSection.items.length; j++) {
                            final tmplItem = tmplSection.items[j];
                            if (sec.items.isNotEmpty) {
                               final existing = sec.items.firstWhere(
                                 (it) => it.label == tmplItem.label, 
                                 orElse: () => InspectionItem(status: 'N/A', score: 0.0)
                               );
                               if (existing.label != null && existing.label!.isNotEmpty) {
                                  _items['$i-item-$j'] = existing;
                               }
                            }
                        }

                        if (tmplSection.subsections != null && sec.subsections != null) {
                           for (var k = 0; k < tmplSection.subsections!.length; k++) {
                              final tmplSub = tmplSection.subsections![k];
                              final sub = sec.subsections!.firstWhere(
                                (ss) => ss.name == tmplSub.title, 
                                orElse: () => InspectionSubsection(name: '', items: [])
                              );
                              
                              for (var l = 0; l < tmplSub.items.length; l++) {
                                 final tmplItem = tmplSub.items[l];
                                 if (sub.items.isNotEmpty) {
                                    final existing = sub.items.firstWhere(
                                      (it) => it.label == tmplItem.label, 
                                      orElse: () => InspectionItem(status: 'N/A', score: 0.0)
                                    );
                                    if (existing.label != null && existing.label!.isNotEmpty) {
                                       _items['$i-sub-$k-item-$l'] = existing;
                                    }
                                 }
                              }
                           }
                        }
                     }
                  }
                  
                  // Update status if pending
                  if (inspection.status == 'pending') {
                      try {
                        await inspectionService.updateInspection(widget.inspectionId!, {'status': 'in_progress'});
                      } catch (e) {
                        print('Failed to update status: $e');
                      }
                  }

                  _step = 2; // Jump to execution
              } else {
                 if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template details missing. Cannot start.')));
              }
           }
        }
        
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading wizard: $e')));
           setState(() => _isLoading = false);
      }
    }
  }

  void _startInspection() async {
    if (_selectedLocationId == null || _selectedTemplateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select location and template')));
      return;
    }
    
    final selectedTmpl = _templates.firstWhere((t) => t.id == _selectedTemplateId);
    
    // If this is an existing inspection in 'pending' status, update it to 'in_progress'
    if (widget.inspectionId != null) {
       try {
          final inspectionService = Provider.of<InspectionService>(context, listen: false);
          // We can't check status easily here without fetching again or storing it? 
          // We fetched it in init. We should store the full inspection object or status.
          // Let's assume we can blindly update if it's an edit, OR we should have stored the inspection.
          // _fetchInitialData fetched it but didn't store the full object in a class field, only populated form.
          // We should update `_fetchInitialData` to store the inspection status or object.
          
          // Re-fetching or just firing update. Firing update is safer.
          await inspectionService.updateInspection(widget.inspectionId!, {'status': 'in_progress'});
       } catch (e) {
          print('Error updating status: $e');
       }
    }

    setState(() {
      _template = selectedTmpl;
      _step = 2;
    });
  }

  void _submitInspection({bool isAssignment = false}) async {
    if (_template == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final service = Provider.of<InspectionService>(context, listen: false);
      
      // Calculate scores
      double totalScore = 0;
      double maxScore = 0;
      
      final List<Map<String, dynamic>> sectionsPayload = [];
      
      for(var i=0; i<_template!.sections.length; i++) {
        final section = _template!.sections[i];
        
        // Validate required sectionPrompt
        if (!isAssignment && section.sectionPrompt?.required == true) {
             final val = _sectionPromptValues[i];
             if (val == null || val.trim().isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${section.sectionPrompt!.label} is required.')));
                 setState(() => _isLoading = false);
                 return;
             }
        }

        Map<String, dynamic>? sectionPromptPayload;
        if (section.sectionPrompt != null) {
          sectionPromptPayload = {
             'label': section.sectionPrompt!.label,
             'placeholder': section.sectionPrompt!.placeholder ?? '',
             'required': section.sectionPrompt!.required,
             'value': _sectionPromptValues[i] ?? '',
          };
        }

        final List<Map<String, dynamic>> itemsPayload = [];
        for(var j=0; j<section.items.length; j++) {
           final key = '$i-item-$j';
           final tmplItem = section.items[j];
           final item = _items[key];
           
           if (!isAssignment && item != null) {
               itemsPayload.add({
                 'itemId': tmplItem.id,
                 'name': tmplItem.label,
                 'type': tmplItem.type,
                 'status': item.status,
                 'score': item.score,
                 'comment': item.comment ?? '',
                 'rating': item.rating,
                 if (item.photos != null && item.photos!.isNotEmpty) 'photos': item.photos,
               });
               
               if (item.status == 'pass' || (item.rating != null && item.rating! >= 3)) {
                 totalScore += tmplItem.weight;
               }
               maxScore += tmplItem.weight;
           } else {
              itemsPayload.add({
                 'itemId': tmplItem.id,
                 'name': tmplItem.label,
                 'type': ['pass_fail', 'rating_1_5', 'yes_no'].contains(tmplItem.type) ? tmplItem.type : 'pass_fail',
                 'status': 'pass',
                 'score': 0,
                 'comment': '',
               });
               maxScore += tmplItem.weight;
           }
        }

        final List<Map<String, dynamic>> subsectionsPayload = [];
        if (section.subsections != null) {
          for (var k = 0; k < section.subsections!.length; k++) {
             final subsection = section.subsections![k];
             final List<Map<String, dynamic>> subItemsPayload = [];
             
             for (var l = 0; l < subsection.items.length; l++) {
                 final key = '$i-sub-$k-item-$l';
                 final tmplItem = subsection.items[l];
                 final item = _items[key];

                 if (!isAssignment && item != null) {
                     subItemsPayload.add({
                       'itemId': tmplItem.id,
                       'name': tmplItem.label,
                       'type': tmplItem.type,
                       'status': item.status,
                       'score': item.score,
                       'comment': item.comment ?? '',
                       'rating': item.rating,
                       if (item.photos != null && item.photos!.isNotEmpty) 'photos': item.photos,
                     });
                     
                     if (item.status == 'pass' || (item.rating != null && item.rating! >= 3)) {
                       totalScore += tmplItem.weight;
                     }
                     maxScore += tmplItem.weight;
                 } else {
                    subItemsPayload.add({
                       'itemId': tmplItem.id,
                       'name': tmplItem.label,
                       'type': ['pass_fail', 'rating_1_5', 'yes_no'].contains(tmplItem.type) ? tmplItem.type : 'pass_fail',
                       'status': 'pass',
                       'score': 0,
                       'comment': '',
                     });
                     maxScore += tmplItem.weight;
                 }
             }

             subsectionsPayload.add({
                'subsectionId': subsection.id,
                'name': subsection.title,
                'items': subItemsPayload,
             });
          }
        }
        
        sectionsPayload.add({
           'sectionId': section.id,
           'name': section.title,
           if (sectionPromptPayload != null) 'sectionPrompt': sectionPromptPayload,
           'items': itemsPayload,
           'subsections': subsectionsPayload,
        });
      }
      
      final scorePercentage = maxScore > 0 ? (totalScore / maxScore) * 100 : 0;
      
      final data = {
        'template': _selectedTemplateId,
        'location': _selectedLocationId,
        'sections': sectionsPayload,
        'score': isAssignment ? 0.0 : scorePercentage.toDouble(),
        'totalScore': isAssignment ? 0.0 : scorePercentage.toDouble(), // Note: totalScore is % on web too
        'status': isAssignment ? 'pending' : 'completed',
        'completedDate': isAssignment ? null : DateTime.now().toIso8601String(),
        if (_selectedInspectorId != null) 'inspector': _selectedInspectorId,
      };
      
      if (widget.inspectionId != null) {
         await service.updateInspection(widget.inspectionId!, data);
      } else {
         await service.createInspection(data);
      }
      
      if(mounted) {
        Navigator.pop(context, true); // Return true to indicate success/refresh
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAssignment ? 'Inspection Assigned!' : 'Inspection Submitted!')));
      }
      
    } catch(e) {
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
         setState(() => _isLoading = false);
      }
    }
  }
  
  void _updateItem(String key, InspectionItem item) {
      setState(() {
        _items[key] = item;
      });
      // Check failure for ticket logic here
      if (item.status == 'fail' || (item.rating != null && item.rating! < 3)) {
         // Show Ticket prompt
         _showTicketPrompt(item.label ?? 'Item');
      }
  }
  
  void _showTicketPrompt(String itemLabel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Issue Detected'),
        content: Text('Item "$itemLabel" failed. Create a ticket?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          TextButton(
            onPressed: () {
               Navigator.pop(ctx);
               Navigator.pushNamed(context, '/tickets/new', arguments: {
                 'locationId': _selectedLocationId,
                 'description': 'Item "$itemLabel" failed inspection.',
               });
            }, 
            child: const Text('Create Ticket')
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_step == 1) return _buildSelectionStep();
    if (_step == 2 && _template != null) return _buildExecutionStep();
    
    return const Scaffold(body: Center(child: Text('Error State')));
  }

  Widget _buildSelectionStep() {
    return Scaffold(
      appBar: AppBar(title: const Text('Start New Inspection')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Select a location and template to begin', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 32),
            DropdownButtonFormField<String>(
              value: _selectedLocationId,
              decoration: const InputDecoration(labelText: 'Select Location', border: OutlineInputBorder()),
              items: _locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
              onChanged: (val) => setState(() => _selectedLocationId = val),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedTemplateId,
              decoration: const InputDecoration(labelText: 'Select Template', border: OutlineInputBorder()),
              items: _templates.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
              onChanged: (val) => setState(() => _selectedTemplateId = val),
            ),
            const SizedBox(height: 24),
            if (_inspectors.isNotEmpty) ...[
               DropdownButtonFormField<String>(
                value: _selectedInspectorId,
                decoration: const InputDecoration(labelText: 'Assign Inspector (Optional)', border: OutlineInputBorder()),
                items: [
                   const DropdownMenuItem<String>(value: null, child: Text('Myself')),
                   ..._inspectors.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))),
                ],
                onChanged: (val) => setState(() {
                   _selectedInspectorId = val;
                   if (val != null) _performNow = false;
                }),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Perform Inspection Now?'),
                subtitle: const Text('If disabled, inspection will be created as "In Progress" for the assignee.'),
                value: _performNow,
                onChanged: (val) => setState(() => _performNow = val),
              ),
              const SizedBox(height: 24),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                 if (_performNow) {
                   _startInspection();
                 } else {
                   if (_selectedLocationId == null || _selectedTemplateId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select location and template')));
                      return;
                   }
                   final selectedTmpl = _templates.firstWhere((t) => t.id == _selectedTemplateId);
                   setState(() => _template = selectedTmpl);
                   _submitInspection(isAssignment: true);
                 }
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(_performNow ? 'Continue' : 'Assign Inspection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutionStep() {
    final section = _template!.sections[_currentSectionIndex];
    final progress = (_currentSectionIndex + 1) / _template!.sections.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(section.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(value: progress),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (section.sectionPrompt != null) ...[
             Card(
               margin: const EdgeInsets.only(bottom: 16),
               child: Padding(
                 padding: const EdgeInsets.all(16),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       children: [
                         Expanded(child: Text(section.sectionPrompt!.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                         if (section.sectionPrompt!.required) const Chip(label: Text('Required', style: TextStyle(fontSize: 10)), padding: EdgeInsets.zero, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                       ]
                     ),
                     const SizedBox(height: 12),
                     TextField(
                       controller: TextEditingController(text: _sectionPromptValues[_currentSectionIndex]),
                       onChanged: (val) => _sectionPromptValues[_currentSectionIndex] = val,
                       decoration: InputDecoration(
                         border: const OutlineInputBorder(),
                         hintText: section.sectionPrompt!.placeholder ?? 'Add comment...',
                       ),
                       maxLines: 3,
                     )
                   ]
                 )
               )
             )
          ],
          
          ...section.items.asMap().entries.map((entry) {
             final index = entry.key;
             final item = entry.value;
             final key = '$_currentSectionIndex-item-$index';
             final savedItem = _items[key];
             return _buildWizardItemCard(item, savedItem, (newItem) => _updateItem(key, newItem));
          }),

          if (section.subsections != null)
             ...section.subsections!.asMap().entries.map((ssEntry) {
                final ssIndex = ssEntry.key;
                final subsection = ssEntry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Padding(
                       padding: const EdgeInsets.symmetric(vertical: 16),
                       child: Text(subsection.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                     ),
                     ...subsection.items.asMap().entries.map((itemEntry) {
                        final index = itemEntry.key;
                        final item = itemEntry.value;
                        final key = '$_currentSectionIndex-sub-$ssIndex-item-$index';
                        final savedItem = _items[key];
                        return _buildWizardItemCard(item, savedItem, (newItem) => _updateItem(key, newItem));
                     }),
                  ]
                );
             }),
        ]
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentSectionIndex > 0)
              ElevatedButton(
                onPressed: () => setState(() => _currentSectionIndex--),
                child: const Text('Previous'),
              )
            else
              TextButton(onPressed: () => setState(() => _step = 1), child: const Text('Cancel')),
            
            ElevatedButton(
              onPressed: () {
                if (_currentSectionIndex < _template!.sections.length - 1) {
                  setState(() => _currentSectionIndex++);
                } else {
                  _submitInspection();
                }
              },
              child: Text(_currentSectionIndex < _template!.sections.length - 1 ? 'Next' : 'Submit'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWizardItemCard(TemplateItem item, InspectionItem? savedItem, Function(InspectionItem) onChange) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               children: [
                 Expanded(child: Text(item.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                 if (item.required) 
                   const Chip(label: Text('Required', style: TextStyle(fontSize: 10)), padding: EdgeInsets.zero, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
               ],
             ),
             const SizedBox(height: 12),
             _buildInput(item, savedItem, onChange),
             const SizedBox(height: 4),
             _buildPhotoSection(item, savedItem, onChange),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(InspectionItem currentItem, ImageSource source, Function(InspectionItem) onChange) async {
    final picker = ImagePicker();
    final List<String> paths = [];
    
    if (source == ImageSource.gallery) {
      final pickedFiles = await picker.pickMultiImage(imageQuality: 50);
      for (var f in pickedFiles) {
        paths.add(f.path);
      }
    } else {
      final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
      if (pickedFile != null) paths.add(pickedFile.path);
    }
    
    if (paths.isEmpty) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final List<String> base64Images = [];
      for (var path in paths) {
         final bytes = await File(path).readAsBytes();
         base64Images.add(base64Encode(bytes));
      }
      
      if (mounted) {
        Navigator.pop(context); // close dialog
        final currentPhotos = List<String>.from(currentItem.photos ?? []);
        currentPhotos.addAll(base64Images);
        
        onChange(InspectionItem(
           label: currentItem.label,
           type: currentItem.type,
           status: currentItem.status,
           comment: currentItem.comment,
           score: currentItem.score,
           rating: currentItem.rating,
           photos: currentPhotos,
        ));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload images: $e')));
      }
    }
  }

  Widget _buildPhotoSection(TemplateItem tmplItem, InspectionItem? savedItem, Function(InspectionItem) onChange) {
    final currentItem = savedItem ?? InspectionItem(label: tmplItem.label, type: tmplItem.type, status: 'N/A', score: 0.0);
    final photos = currentItem.photos ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           children: [
             TextButton.icon(
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Camera'),
                onPressed: () => _pickAndUploadImage(currentItem, ImageSource.camera, onChange),
             ),
             TextButton.icon(
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('Gallery'),
                onPressed: () => _pickAndUploadImage(currentItem, ImageSource.gallery, onChange),
             ),
           ]
        ),
        if (photos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: photos.asMap().entries.map((entry) {
                final idx = entry.key;
                final photoData = entry.value;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: photoData.length > 200 
                         ? Image.memory(base64Decode(photoData), width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, size: 64))
                         : Image.network(photoData.startsWith('http') ? photoData : '${AppConstants.apiBaseUrl.replaceAll('/api', '')}$photoData', width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, size: 64)),
                    ),
                    Positioned(
                      right: -8,
                      top: -8,
                      child: InkWell(
                        onTap: () {
                           final newPhotos = List<String>.from(photos)..removeAt(idx);
                           onChange(InspectionItem(
                             label: currentItem.label,
                             type: currentItem.type,
                             status: currentItem.status,
                             comment: currentItem.comment,
                             score: currentItem.score,
                             rating: currentItem.rating,
                             photos: newPhotos.isEmpty ? null : newPhotos,
                           ));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    )
                  ]
                );
              }).toList(),
            ),
          )
      ]
    );
  }

  Widget _buildSelectionButton({required String label, required bool isSelected, required Color activeColor, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.1) : const Color(0xFFf8fafc),
            border: Border.all(color: isSelected ? activeColor : const Color(0xFFe2e8f0), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? activeColor : const Color(0xFF64748b),
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TemplateItem tmplItem, InspectionItem? savedItem, Function(InspectionItem) onChange) {
      if (tmplItem.type == 'pass_fail') {
          return Row(
            children: [
              _buildSelectionButton(
                label: 'Pass',
                isSelected: savedItem?.status == 'pass',
                activeColor: const Color(0xFF10b981),
                onTap: () => onChange(InspectionItem(
                     label: tmplItem.label, 
                     type: tmplItem.type, 
                     status: 'pass', 
                     score: 0.0,
                     comment: savedItem?.comment,
                     rating: savedItem?.rating,
                     photos: savedItem?.photos,
                  )),
              ),
              _buildSelectionButton(
                label: 'Fail',
                isSelected: savedItem?.status == 'fail',
                activeColor: const Color(0xFFef4444),
                onTap: () => onChange(InspectionItem(
                     label: tmplItem.label, 
                     type: tmplItem.type, 
                     status: 'fail', 
                     score: 0.0,
                     comment: savedItem?.comment,
                     rating: savedItem?.rating,
                     photos: savedItem?.photos,
                  )),
              ),
            ],
          );
      } else if (tmplItem.type == 'rating' || tmplItem.type == 'rating_1_5') {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
               final rating = i + 1;
               return IconButton(
                 iconSize: 36,
                 icon: Icon(
                    rating <= (savedItem?.rating ?? 0) ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                 ),
                 onPressed: () => onChange(InspectionItem(
                     label: tmplItem.label,
                     type: tmplItem.type,
                     status: rating >= 3 ? 'pass' : 'fail',
                     rating: rating,
                     score: 0.0,
                     comment: savedItem?.comment,
                     photos: savedItem?.photos,
                 )),
               );
            }),
          );
      } else if (tmplItem.type == 'yes_no') {
           return Row(
            children: [
              _buildSelectionButton(
                label: 'Yes',
                isSelected: savedItem?.status == 'pass',
                activeColor: const Color(0xFF10b981),
                onTap: () => onChange(InspectionItem(label: tmplItem.label, type: tmplItem.type, status: 'pass', score: 0.0, comment: savedItem?.comment, rating: savedItem?.rating, photos: savedItem?.photos)),
              ),
              _buildSelectionButton(
                label: 'No',
                isSelected: savedItem?.status == 'fail',
                activeColor: const Color(0xFFef4444),
                onTap: () => onChange(InspectionItem(label: tmplItem.label, type: tmplItem.type, status: 'fail', score: 0.0, comment: savedItem?.comment, rating: savedItem?.rating, photos: savedItem?.photos)),
              ),
            ],
          );
      }
      
      // Default / Text
      return TextField(
        controller: TextEditingController(text: savedItem?.comment),
        onChanged: (val) => onChange(InspectionItem(
           label: tmplItem.label,
           type: tmplItem.type,
           status: 'pass', 
           comment: val,
           score: 0.0,
           rating: savedItem?.rating,
           photos: savedItem?.photos,
        )),
        decoration: InputDecoration(
          labelText: 'Comments (Optional)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        maxLines: 2,
      );
  }
}
