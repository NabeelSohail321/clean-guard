import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/models/inspection.dart';

import 'package:mobile_app/services/inspection_service.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/services/ticket_service.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/screens/ticket_form_screen.dart';
import 'package:open_filex/open_filex.dart';
import 'package:mobile_app/screens/inspection_wizard_screen.dart';
import 'package:mobile_app/config/constants.dart';
import 'dart:convert';

class InspectionDetailsScreen extends StatefulWidget {
  final String inspectionId;
  const InspectionDetailsScreen({super.key, required this.inspectionId});

  @override
  State<InspectionDetailsScreen> createState() => _InspectionDetailsScreenState();
}

class _InspectionDetailsScreenState extends State<InspectionDetailsScreen> {
  Inspection? _inspection;
  bool _isLoading = true;
  String? _error;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _fetchInspection();
  }

  Future<void> _fetchInspection() async {
    try {
      final service = Provider.of<InspectionService>(context, listen: false);
      final inspection = await service.getInspection(widget.inspectionId);
      setState(() {
        _inspection = inspection;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadPdf() async {
    setState(() => _isDownloading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final service = Provider.of<InspectionService>(context, listen: false);
      final path = await service.downloadInspectionPdf(widget.inspectionId);
      
      if (path != null) {
        final result = await OpenFilex.open(path);
        if (result.type != ResultType.done) {
            if(mounted) messenger.showSnackBar(SnackBar(content: Text('Could not open file: ${result.message}')));
        }
      } else {
        if(mounted) messenger.showSnackBar(const SnackBar(content: Text('Failed to download PDF')));
      }
    } catch (e) {
      if(mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if(mounted) setState(() => _isDownloading = false);
    }
  }

  List<InspectionItem> _getAllFailedItems() {
    if (_inspection == null) return [];
    List<InspectionItem> failed = [];
    
    // Check nested sections
    if (_inspection!.sections != null) {
      for (var section in _inspection!.sections!) {
        for (var item in section.items) {
           if (item.status == 'fail' || (item.rating != null && item.rating! < 3)) {
             failed.add(item);
           }
        }
        if (section.subsections != null) {
          for (var subsection in section.subsections!) {
            for (var item in subsection.items) {
               if (item.status == 'fail' || (item.rating != null && item.rating! < 3)) {
                 failed.add(item);
               }
            }
          }
        }
      }
    } 
    // Check flat items if sections are empty (or in addition)
    else {
       for (var item in _inspection!.items) {
           if (item.status == 'fail' || (item.rating != null && item.rating! < 3)) {
             failed.add(item);
           }
       }
    }
    return failed;
  }

  void _showBulkTicketDialog() {
    final failedItems = _getAllFailedItems();
    if (failedItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Tickets'),
        content: Text('You have ${failedItems.length} failed items. How would you like to create tickets?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
               _createSeparateTickets(failedItems);
            },
            child: const Text('Separate Tickets'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _createCollectiveTicket(failedItems);
            },
            child: const Text('One Collective Ticket'),
          ),
        ],
      ),
    );
  }

  Future<void> _createSeparateTickets(List<InspectionItem> failedItems) async {
    if (_inspection == null) return;
    
    // Confirmation
    final confirm = await showDialog<bool>(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Bulk Creation'),
        content: Text('This will create ${failedItems.length} separate tickets. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      )
    );

    if (!mounted) return;
    if (confirm != true) return;

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final ticketService = Provider.of<TicketService>(context, listen: false);
      int successCount = 0;

      for (var item in failedItems) {
        final data = {
          'title': 'Issue: ${item.label ?? "Unknown Item"}',
          'description': item.comment ?? 'Failed inspection item: ${item.label ?? "Unknown Item"}',
          'priority': 'high',
          'location': _inspection!.locationId ?? _inspection!.location?.id,
          'status': 'open',
        };
        await ticketService.createTicket(data);
        successCount++;
      }

      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Created $successCount tickets successfully')));
      setState(() => _isLoading = false);

    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Error creating tickets: $e')));
      setState(() => _isLoading = false);
    }
  }

  void _createCollectiveTicket(List<InspectionItem> failedItems) {
    if (_inspection == null) return;
    
    final StringBuffer desc = StringBuffer();
    for (int i = 0; i < failedItems.length; i++) {
      final item = failedItems[i];
      desc.writeln('${i + 1}. ${item.label}: ${item.comment ?? "Failed"}');
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketFormScreen(
          initialLocationId: _inspection!.locationId ?? _inspection!.location?.id,
          initialTitle: 'Multiple Issues - ${_inspection!.location?.name ?? "Inspection"}',
          initialDescription: desc.toString(),
          initialPriority: 'high',
        ),
      ),
    );
  }

  void _createIndividualTicket(InspectionItem item) {
    if (_inspection == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketFormScreen(
          initialLocationId: _inspection!.locationId ?? _inspection!.location?.id,
          initialTitle: 'Issue: ${item.label}',
          initialDescription: item.comment ?? 'Failed inspection item: ${item.label}',
          initialPriority: 'high',
        ),
      ),
    );
  }

  void _showAssignDialog() async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final users = await userService.getUsers();
      final supervisors = users.where((u) => u.role == 'supervisor' || u.role == 'inspector').toList();
      
      if (!mounted) return;
      
      showDialog(
        context: context, 
        builder: (ctx) => AlertDialog(
          title: const Text('Assign Inspector'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: supervisors.length,
              itemBuilder: (context, index) {
                final user = supervisors[index];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text(user.role),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _assignInspector(user.id);
                  },
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
        )
      );
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching users: $e')));
    }
  }
  
  Future<void> _assignInspector(String userId) async {
    setState(() => _isLoading = true);
    try {
      final service = Provider.of<InspectionService>(context, listen: false);
      final updated = await service.assignInspection(widget.inspectionId, userId);
      if(mounted) {
         setState(() {
           _inspection = updated;
           _isLoading = false;
         });
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inspector assigned!')));
      }
    } catch (e) {
      if(mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Assignment failed: $e')));
      }
    }
  }

  void _showScheduleDialog() async {
    DateTime? selectedDate = _inspection?.scheduledDate ?? DateTime.now();
    TimeOfDay? selectedTime = _inspection?.scheduledDate != null 
        ? TimeOfDay.fromDateTime(_inspection!.scheduledDate!) 
        : TimeOfDay.now();

    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (time == null || !mounted) return;

    final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() => _isLoading = true);
    try {
      final service = Provider.of<InspectionService>(context, listen: false);
      final updated = await service.scheduleInspection(widget.inspectionId, dateTime);
      
      if (mounted) {
        setState(() {
          _inspection = updated;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inspection scheduled!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to schedule: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final isAdmin = user?.role == 'admin' || user?.role == 'sub_admin';

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $_error')));
    if (_inspection == null) return const Scaffold(body: Center(child: Text('Inspection not found')));

    final inspection = _inspection!;
    final theme = Theme.of(context);
    final failedItems = _getAllFailedItems();

    return Scaffold(
      appBar: AppBar(
        title: Text(inspection.location?.name ?? 'Inspection Details'),
        actions: [
          if (isAdmin && failedItems.length > 1)
             IconButton(
               icon: const Icon(Icons.assignment_late, color: Colors.orange),
               tooltip: 'Create Bulk Tickets',
               onPressed: _showBulkTicketDialog,
             ),
          if (_isDownloading)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))))
          else
            IconButton(icon: const Icon(Icons.download), onPressed: _downloadPdf),
        ],
      ),
      floatingActionButton: _buildResumeFab(context, inspection, user),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeader(context),
            const SizedBox(height: 16),

            // Summary Section
            if (inspection.summaryComment != null && inspection.summaryComment!.isNotEmpty) ...[
                Text('Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(inspection.summaryComment!),
                ),
                const SizedBox(height: 24),
            ],
            
            // Sections
            if (inspection.sections != null && inspection.sections!.isNotEmpty)
              ...inspection.sections!.map((section) => _buildSection(section, theme, isAdmin))
            else if (inspection.items.isNotEmpty)
               _buildSection(InspectionSection(name: 'Inspection Items', items: inspection.items), theme, isAdmin)
            else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No detailed items available.'),
              ),
          ],
        ),
      ),
    );
  }

  Widget? _buildResumeFab(BuildContext context, Inspection inspection, dynamic user) {
     // Check if user is assigned inspector and inspection is in progress
     final isAssigned = inspection.inspectorId == user?.id || inspection.inspector?.id == user?.id;
     final isInProgress = inspection.status == 'in_progress' || inspection.status == 'assigned' || inspection.status == 'pending';
     
     if (isAssigned && isInProgress) {
        // Date check
        if (inspection.scheduledDate != null && DateTime.now().isBefore(inspection.scheduledDate!)) {
           return FloatingActionButton.extended(
             onPressed: null,
             backgroundColor: Colors.grey,
             label: Text('Scheduled: ${DateFormat('MMM d, h:mm a').format(inspection.scheduledDate!)}'),
             icon: const Icon(Icons.access_time),
           );
        }

        return FloatingActionButton.extended(
          onPressed: () async {
             final result = await Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (context) => InspectionWizardScreen(inspectionId: inspection.id),
               ),
             );
             if (result == true) {
                _fetchInspection(); // Refresh details on return
             }
          },
          label: Text(inspection.status == 'pending' || inspection.status == 'assigned' ? 'Start Inspection' : 'Resume Inspection'),
          icon: const Icon(Icons.play_arrow),
        );
     }
     return null;
  }

  Widget _buildHeader(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = auth.user?.role == 'admin' || auth.user?.role == 'sub_admin';
    final inspection = _inspection!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFe2e8f0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left details
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildDetailText('ID:', inspection.id.substring(inspection.id.length - 8).toUpperCase()),
                   const SizedBox(height: 8),
                   _buildDetailText('Location:', inspection.location?.name ?? 'Unknown'),
                   const SizedBox(height: 8),
                   Row(
                     children: [
                       _buildDetailText('Inspector:', inspection.inspector?.name ?? 'Unassigned'),
                       if (isAdmin)
                         IconButton(
                           padding: const EdgeInsets.only(left: 4),
                           constraints: const BoxConstraints(),
                           icon: const Icon(Icons.edit, size: 14, color: Colors.blue),
                           onPressed: _showAssignDialog,
                         )
                     ],
                   ),
                   const SizedBox(height: 8),
                   Row(
                     children: [
                       _buildDetailText('Completed:', DateFormat('yyyy-MM-dd h:mma').format(inspection.completedDate ?? inspection.scheduledDate ?? DateTime.now())),
                       if (isAdmin && inspection.status != 'completed')
                         IconButton(
                           padding: const EdgeInsets.only(left: 4),
                           constraints: const BoxConstraints(),
                           icon: const Icon(Icons.edit_calendar, size: 14, color: Colors.blue),
                           onPressed: _showScheduleDialog,
                         )
                     ],
                   ),
                   const SizedBox(height: 8),
                   _buildDetailText('Privacy:', inspection.isPrivate ? 'Private' : 'Not Private'),
                ],
              ),
            ),
            // Right pie chart
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Overall Score:', style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: inspection.totalScore / 100,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey.shade200,
                          color: _getScoreColor(inspection.totalScore),
                        ),
                        Center(
                          child: Text(
                            '${inspection.totalScore.toInt()}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailText(String label, String value) {
     return RichText(
        text: TextSpan(
           style: const TextStyle(fontSize: 13, color: Colors.black87),
           children: [
              TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: value),
           ]
        ),
     );
  }



  Widget _buildSection(InspectionSection section, ThemeData theme, bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(section.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1e293b))),
        ),
        if (section.sectionPrompt?.label != null) 
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFf8fafc),
              border: Border.all(color: const Color(0xFFe2e8f0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.sectionPrompt!.label, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                const SizedBox(height: 4),
                Text(section.sectionPrompt!.value ?? '-', style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1e293b))),
              ],
            ),
          ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFe2e8f0)),
          ),
          child: Column(
            children: [
              ...section.items.map((item) => _buildItem(item, isAdmin)).toList(),
              
              if (section.subsections != null)
                ...section.subsections!.map((subsection) => Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 8.0, right: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(subsection.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF334155))),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFe2e8f0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: subsection.items.map((item) => _buildItem(item, isAdmin)).toList(),
                        ),
                      )
                    ],
                  ),
                )).toList(),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showImageDialog(String photoData) {
     Widget fullImage;
     if (photoData.length > 200) {
        try {
           final cleanBase64 = photoData.contains(',') ? photoData.split(',').last.replaceAll(RegExp(r'\s+'), '') : photoData.replaceAll(RegExp(r'\s+'), '');
           fullImage = Image.memory(base64Decode(cleanBase64), fit: BoxFit.contain);
        } catch (_) {
           fullImage = const Icon(Icons.broken_image, size: 100, color: Colors.white);
        }
     } else {
        final fullUrl = photoData.startsWith('http') ? photoData : '${AppConstants.apiBaseUrl.replaceAll('/api', '')}$photoData';
        fullImage = Image.network(fullUrl, fit: BoxFit.contain);
     }
     
     showDialog(
       context: context,
       builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            children: [
               Positioned.fill(
                 child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: InteractiveViewer(
                       child: fullImage,
                    )
                 ),
               ),
               Positioned(
                 top: 0, right: 0,
                 child: IconButton(
                   icon: const Icon(Icons.close, color: Colors.white, size: 30),
                   onPressed: () => Navigator.pop(ctx),
                 ),
               )
            ]
          )
       )
     );
  }

  Widget _buildItem(InspectionItem item, bool isAdmin) {
    Color statusColor = Colors.grey;
    if (item.status == 'pass') statusColor = const Color(0xFF10b981);
    if (item.status == 'fail') statusColor = const Color(0xFFef4444);
    
    final bool isFailed = item.status == 'fail' || (item.rating != null && item.rating! < 3);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFailed ? const Color(0xFFfee2e2) : Colors.transparent,
        border: const Border(bottom: BorderSide(color: Color(0xFFe2e8f0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Expanded(
                 child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(item.label ?? item.templateItemId ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1e293b), fontSize: 14)),
                       const SizedBox(height: 12),
                       Row(
                          children: [
                             Container(
                                width: 36, height: 6,
                                color: statusColor,
                             ),
                             const SizedBox(width: 12),
                             Text(item.status == 'fail' ? 'Requires Attention' : 'Clean', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                             if (item.score > 0) ...[
                                const SizedBox(width: 16),
                                Text('${item.score} / 5', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748b))),
                             ]
                          ],
                       ),
                    ]
                 ),
               ),
               Flexible(child: Text(item.comment != null && item.comment!.isNotEmpty ? item.comment! : 'No comment', style: const TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic), textAlign: TextAlign.right)),
            ],
          ),
          
          if (item.photos != null && item.photos!.isNotEmpty)
             Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SingleChildScrollView(
                   scrollDirection: Axis.horizontal,
                   child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: item.photos!.map((photoData) {
                        Widget imageWidget;
                        if (photoData.length > 200) {
                          try {
                            final cleanBase64 = photoData.contains(',') ? photoData.split(',').last.replaceAll(RegExp(r'\s+'), '') : photoData.replaceAll(RegExp(r'\s+'), '');
                            imageWidget = Image.memory(
                              base64Decode(cleanBase64),
                              width: 140, height: 180, fit: BoxFit.cover,
                              errorBuilder: (_,__,___) => Container(width: 140, height: 180, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey))
                            );
                          } catch (e) {
                            imageWidget = Container(width: 140, height: 180, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey));
                          }
                        } else {
                          final fullUrl = photoData.startsWith('http') ? photoData : '${AppConstants.apiBaseUrl.replaceAll('/api', '')}$photoData';
                          imageWidget = Image.network(
                              fullUrl, 
                              width: 140, height: 180, 
                              fit: BoxFit.cover,
                              errorBuilder: (_,__,___) => Container(width: 140, height: 180, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey))
                           );
                        }
                        
                        return Padding(
                           padding: const EdgeInsets.only(right: 12),
                           child: GestureDetector(
                             onTap: () => _showImageDialog(photoData),
                             child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                   ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageWidget,
                                   ),
                                   const SizedBox(height: 6),
                                   Row(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                         const Icon(Icons.camera_alt, size: 10, color: Colors.green),
                                         const SizedBox(width: 4),
                                         Text('In-app Photo ${DateFormat('MMM d, h:mm a').format(_inspection!.completedDate ?? DateTime.now())}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                                     ],
                                   )
                                ],
                             ),
                           )
                        );
                      }).toList(),
                   )
                )
             ),

          if (isAdmin && isFailed)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: OutlinedButton.icon(
                onPressed: () => _createIndividualTicket(item),
                icon: const Icon(Icons.add_alert, size: 16, color: Color(0xFFef4444)),
                label: const Text('Create Ticket', style: TextStyle(color: Color(0xFFef4444), fontSize: 13, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFef4444)),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
              ),
            )
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.orange;
    return Colors.red;
  }
}
