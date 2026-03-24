import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/models/ticket.dart';
import 'package:mobile_app/services/ticket_service.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class TicketDetailsScreen extends StatefulWidget {
  final Ticket ticket;

  const TicketDetailsScreen({super.key, required this.ticket});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  late Ticket _ticket;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
  }

  Future<void> _refreshTicket() async {
    // In a real app, you might fetch a single ticket here.
    // For now, we'll just return true to the list screen to trigger a refresh there.
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final userRole = Provider.of<AuthProvider>(context, listen: false).user?.role;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildInfoCard(),
                  const SizedBox(height: 20),
                  _buildDescriptionSection(),
                  const SizedBox(height: 20),
                  if (_ticket.resolutionNotes != null) _buildResolutionSection(),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomActions(userRole),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPriorityBadge(_ticket.priority),
            _buildStatusBadge(_ticket.status),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _ticket.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              _ticket.location?.name ?? 'Unknown Location',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.person, 'Assigned To', _ticket.assignedTo?.name ?? 'Unassigned'),
            const Divider(),
            _buildInfoRow(Icons.person_outline, 'Created By', _ticket.createdBy?.name ?? 'Unknown'),
            const Divider(),
            _buildInfoRow(Icons.calendar_today, 'Created', DateFormat('MMM d, y h:mm a').format(_ticket.createdAt)),
            if (_ticket.scheduledDate != null) ...[
              const Divider(),
              _buildInfoRow(Icons.event, 'Scheduled', DateFormat('MMM d, y h:mm a').format(_ticket.scheduledDate!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        )
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          _ticket.description,
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildResolutionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resolution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          color: Colors.green[50],
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ticket.resolutionNotes ?? '',
                  style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                ),
                if (_ticket.resolvedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Text(
                      'Resolved on ${DateFormat('MMM d, y').format(_ticket.resolvedAt!)}',
                      style: TextStyle(fontSize: 12, color: Colors.green[800], fontStyle: FontStyle.italic),
                    ),
                  ),
                if (_ticket.resolutionImages != null && _ticket.resolutionImages!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Attached Images:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _ticket.resolutionImages!.map((img) {
                      try {
                        // Handle base64 string
                        final base64String = img.split(',').last;
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(base64String),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 40, color: Colors.grey),
                            ),
                          ),
                        );
                      } catch (e) {
                         return SizedBox();
                      }
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomActions(String? userRole) {
    if (userRole == 'admin' || userRole == 'sub_admin') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.person_add),
                label: Text('Reassign'),
                onPressed: _showAssignDialog,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(Icons.calendar_month),
                label: Text('Schedule'),
                onPressed: _showScheduleDialog,
              ),
            ),
          ],
        ),
      );
    } else if (userRole == 'supervisor') {
      if (_ticket.status == 'open') {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () => _updateStatus('in_progress'),
            child: const Text('Start Work'),
          ),
        );
      } else if (_ticket.status == 'in_progress') {
         return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: _showResolveDialog,
            child: const Text('Resolve Ticket'),
          ),
        );
      }
    }
    return null;
  }

  void _showAssignDialog() {
    showDialog(
      context: context,
      builder: (context) => AssignTicketDialog(
        ticketId: _ticket.id,
        onSuccess: () {
          Navigator.pop(context, true); // Return true to refresh list
        }
      ),
    ).then((val) {
      if (val == true) Navigator.pop(context, true);
    });
  }

  void _showScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => ScheduleTicketDialog(
        ticketId: _ticket.id,
        onSuccess: () {
           Navigator.pop(context, true);
        }
      ),
    ).then((val) {
      if (val == true) Navigator.pop(context, true);
    });
  }

  void _showResolveDialog() {
     showDialog(
      context: context,
      builder: (context) => ResolveTicketDialog(
        ticketId: _ticket.id,
        onSuccess: () {
           Navigator.pop(context, true);
        }
      ),
    ).then((val) {
      if (val == true) Navigator.pop(context, true);
    });
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<TicketService>(context, listen: false).updateTicket(
        _ticket.id, 
        {'status': status}
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      setState(() => _isLoading = false);
    }
  }

  // --- Helpers for Badges (Copied from List Screen for consistency) ---
  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    Color bg = Colors.grey.shade100;
    
    switch(status) {
      case 'open': color = Colors.red; bg = Colors.red.shade50; break;
      case 'in_progress': color = Colors.blue; bg = Colors.blue.shade50; break;
      case 'resolved': color = Colors.green; bg = Colors.green.shade50; break;
      case 'closed': color = Colors.black54; bg = Colors.grey.shade200; break;
      case 'verified': color = Colors.purple; bg = Colors.purple.shade50; break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color = Colors.grey;
    Color bg = Colors.grey.shade100;

    switch(priority) {
      case 'urgent': color = Colors.red; bg = Colors.red.shade100; break;
      case 'high': color = Colors.orange; bg = Colors.orange.shade100; break;
      case 'medium': color = Colors.amber.shade800; bg = Colors.amber.shade100; break;
      case 'low': color = Colors.green; bg = Colors.green.shade100; break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(priority.toUpperCase(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

// --- Dialogs (Inline for simplicity, can move to separate files) ---

class AssignTicketDialog extends StatefulWidget {
  final String ticketId;
  final VoidCallback onSuccess;

  const AssignTicketDialog({super.key, required this.ticketId, required this.onSuccess});

  @override
  State<AssignTicketDialog> createState() => _AssignTicketDialogState();
}

class _AssignTicketDialogState extends State<AssignTicketDialog> {
  String? _selectedUserId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Assign Ticket'),
      content: FutureBuilder<List<User>>(
        future: Provider.of<UserService>(context, listen: false).getUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
          // Filter supervisors
          final supervisors = snapshot.data!.where((u) => u.role == 'supervisor').toList();
          
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: 'Select Supervisor'),
            items: supervisors.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
            onChanged: (val) => setState(() => _selectedUserId = val),
          );
        }
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: (_selectedUserId == null || _isLoading) ? null : () async {
            setState(() => _isLoading = true);
            try {
              await Provider.of<TicketService>(context, listen: false).assignTicket(widget.ticketId, _selectedUserId!);
              widget.onSuccess();
            } catch (e) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
               setState(() => _isLoading = false);
            }
          },
          child: _isLoading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text('Assign'),
        )
      ],
    );
  }
}

class ScheduleTicketDialog extends StatefulWidget {
  final String ticketId;
  final VoidCallback onSuccess;

  const ScheduleTicketDialog({super.key, required this.ticketId, required this.onSuccess});

  @override
  State<ScheduleTicketDialog> createState() => _ScheduleTicketDialogState();
}

class _ScheduleTicketDialogState extends State<ScheduleTicketDialog> {
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Schedule Ticket'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(_selectedDate == null ? 'Select Date & Time' : DateFormat('MMM d, y h:mm a').format(_selectedDate!)),
            trailing: Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context, 
                initialDate: DateTime.now(), 
                firstDate: DateTime.now(), 
                lastDate: DateTime.now().add(Duration(days: 365))
              );
              if (date != null) {
                // ignore: use_build_context_synchronously
                final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (time != null) {
                  setState(() {
                    _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  });
                }
              }
            },
          )
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(
          onPressed: (_selectedDate == null || _isLoading) ? null : () async {
            setState(() => _isLoading = true);
            try {
              await Provider.of<TicketService>(context, listen: false).scheduleTicket(widget.ticketId, _selectedDate!);
              widget.onSuccess();
            } catch (e) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
               setState(() => _isLoading = false);
            }
          },
          child: _isLoading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text('Schedule'),
        )
      ],
    );
  }
}


class ResolveTicketDialog extends StatefulWidget {
  final String ticketId;
  final VoidCallback onSuccess;

  const ResolveTicketDialog({super.key, required this.ticketId, required this.onSuccess});

  @override
  State<ResolveTicketDialog> createState() => _ResolveTicketDialogState();
}

class _ResolveTicketDialogState extends State<ResolveTicketDialog> {
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 50);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<String> _convertImageToBase64(XFile image) async {
    final bytes = await image.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Resolve Ticket'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Resolution Notes',
                alignLabelWithHint: true,
                border: OutlineInputBorder()
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                TextButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedImages.map((image) {
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, right: 8),
                        child: Image.file(
                          File(image.path),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.remove(image);
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          onPressed: (_notesController.text.isEmpty || _isLoading) ? null : () async {
            setState(() => _isLoading = true);
            try {
              // Convert images to base64
              List<String> base64Images = [];
              for (var img in _selectedImages) {
                base64Images.add(await _convertImageToBase64(img));
              }

              await Provider.of<TicketService>(context, listen: false).resolveTicket(
                widget.ticketId, 
                _notesController.text, 
                base64Images
              );
              widget.onSuccess();
            } catch (e) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
               setState(() => _isLoading = false);
            }
          },
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Mark Resolved'),
        )
      ],
    );
  }
}
