import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/services/ticket_service.dart';
import 'package:mobile_app/services/location_service.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/models/location.dart';
import 'package:mobile_app/models/user.dart';
import 'package:intl/intl.dart';

class TicketFormScreen extends StatefulWidget {
  final String? initialLocationId;
  final String? initialDescription;
  final String? initialTitle;
  final String? initialPriority;

  const TicketFormScreen({
    super.key, 
    this.initialLocationId, 
    this.initialDescription,
    this.initialTitle,
    this.initialPriority,
  });

  @override
  State<TicketFormScreen> createState() => _TicketFormScreenState();
}

class _TicketFormScreenState extends State<TicketFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  String? _selectedLocationId;
  String _priority = 'medium';
  String _status = 'open';
  String? _assignedToId;
  DateTime? _scheduledDate;
  
  bool _isLoading = false;
  
  List<Location> _locations = [];
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialLocationId != null) _selectedLocationId = widget.initialLocationId;
    if (widget.initialDescription != null) _descController.text = widget.initialDescription ?? '';
    if (widget.initialTitle != null) _titleController.text = widget.initialTitle ?? '';
    if (widget.initialPriority != null) _priority = widget.initialPriority!;
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final locService = Provider.of<LocationService>(context, listen: false);
      final userService = Provider.of<UserService>(context, listen: false);
      
      final locs = await locService.getLocations();
      final users = await userService.getUsers();
      
      if (mounted) {
        setState(() {
          _locations = locs;
          _users = users;
        });
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked == null || !mounted) return;

    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    
    if (!mounted) return;

    if (time != null) {
       setState(() {
         _scheduledDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
       });
    } else {
       setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a location')));
      return;
    }

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    try {
      final data = {
        'title': _titleController.text,
        'description': _descController.text,
        'priority': _priority,
        'status': _status,
        'location': _selectedLocationId,
        'assignedTo': _assignedToId,
        if (_scheduledDate != null) 'scheduledDate': _scheduledDate!.toIso8601String(),
      };
      
      await Provider.of<TicketService>(context, listen: false).createTicket(data);
      
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Ticket created successfully')));
        navigator.pop(true);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter users for supervisors or show all? Web filtered for 'supervisor'
    final supervisors = _users.where((u) => u.role == 'supervisor').toList();
    // If no supervisors found, maybe show all or just empty? 
    // Web logic: users.filter(u => u.role === 'supervisor')
    final assignableUsers = supervisors.isEmpty ? _users : supervisors; // Fallback if no supervisors? sticking to web parity logic implies only supervisors.
    final displayUsers = supervisors;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Ticket')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedLocationId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
                items: _locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) => setState(() => _selectedLocationId = val),
                validator: (val) => val == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(value: 'critical', child: Text('Critical')), // Matched "urgent" -> "critical" based on web form
                      ],
                      onChanged: (val) => setState(() => _priority = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'open', child: Text('Open')),
                        DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                        DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                      ],
                      onChanged: (val) => setState(() => _status = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ListTile(
                 contentPadding: EdgeInsets.zero,
                 title: Text(_scheduledDate == null ? 'Scheduled Date (Optional)' : 'Scheduled: ${DateFormat('MMM d, y HH:mm').format(_scheduledDate!)}'),
                 trailing: const Icon(Icons.calendar_today),
                 onTap: _selectDate,
                 shape: const Border(bottom: BorderSide(color: Colors.grey)),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _assignedToId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Assign To (Optional)', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('Unassigned')),
                  ...displayUsers.map((u) => DropdownMenuItem(value: u.id, child: Text('${u.name} (${u.role})', overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (val) => setState(() => _assignedToId = val),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), alignLabelWithHint: true),
                maxLines: 5,
                validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: const Icon(Icons.save),
                  label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Ticket'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
