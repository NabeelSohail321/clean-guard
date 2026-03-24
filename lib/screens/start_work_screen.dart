import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/models/inspection.dart';
import 'package:mobile_app/models/ticket.dart';
import 'package:mobile_app/services/inspection_service.dart';
import 'package:mobile_app/services/ticket_service.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/widgets/app_drawer.dart';
import 'package:mobile_app/config/theme.dart';
import 'package:mobile_app/screens/inspection_wizard_screen.dart';
import 'package:mobile_app/screens/ticket_details_screen.dart';

class StartWorkScreen extends StatefulWidget {
  const StartWorkScreen({super.key});

  @override
  State<StartWorkScreen> createState() => _StartWorkScreenState();
}

class _StartWorkScreenState extends State<StartWorkScreen> {
  bool _isLoading = true;
  List<Inspection> _scheduledInspections = [];
  List<Ticket> _assignedTickets = [];

  @override
  void initState() {
    super.initState();
    _fetchWorkData();
  }

  Future<void> _fetchWorkData() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.user?.id;
      final userRole = auth.user?.role;
      
      if (userId == null) return;

      final inspectionService = Provider.of<InspectionService>(context, listen: false);
      final ticketService = Provider.of<TicketService>(context, listen: false);

      // Fetch all (filtering is done on client side for now as backend filters might vary)
      // Ideally backend should support /my-schedule endpoint
      final allInspections = await inspectionService.getInspections(inspectorId: userId); 
      // Note: getTickets usually fetches all for admin, but filtered for others. 
      // We can use the assignedTo param if we are admin/sub-admin to simulate "my work"
      // or just fetch all and filter client side.
      final allTickets = await ticketService.getTickets(assignedTo: userId); // Using the param we added earlier

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final scheduled = allInspections.where((i) {
        // Filter by inspector
        final inspectorId = i.inspectorId ?? i.inspector?.id;
        if (inspectorId != userId) return false;

        // Filter by date (Today)
        if (i.scheduledDate == null) return false;
        final date = i.scheduledDate!;
        return date.isAfter(today.subtract(const Duration(seconds: 1))) && date.isBefore(tomorrow);
      }).toList();

      final assigned = allTickets.where((t) {
        final assigneeId = t.assignedTo?.id; // Ticket model has User object or ID?
        // The service logic for `getTickets` with `assignedTo` param should handle fetching correct ones.
        // But let's double check client side if needed. 
        // If we trust the API, we just filter status.
        return ['open', 'in_progress'].contains(t.status);
      }).toList();

      if (mounted) {
        setState(() {
          _scheduledInspections = scheduled;
          _assignedTickets = assigned;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching work data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    }
  }

  void _startInspection(Inspection inspection) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InspectionWizardScreen(inspectionId: inspection.id),
      ),
    );
     if (result == true) {
        _fetchWorkData();
     }
  }

  void _startTicket(Ticket ticket) async {
     final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailsScreen(ticket: ticket),
      ),
    );
    if (result == true) {
        _fetchWorkData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start Work')),
      drawer: const AppDrawer(),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchWorkData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Today\'s Scheduled Inspections', Icons.calendar_today, _scheduledInspections.length),
                    if (_scheduledInspections.isEmpty) 
                      _buildEmptyState('No inspections scheduled for today')
                    else
                      ..._scheduledInspections.map((i) => _buildInspectionCard(i)),

                    const SizedBox(height: 32),

                    _buildSectionHeader('Assigned Tickets', Icons.assignment_late, _assignedTickets.length),
                    if (_assignedTickets.isEmpty)
                      _buildEmptyState('No active tickets assigned to you')
                    else
                      ..._assignedTickets.map((t) => _buildTicketCard(t)),
                      
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
            child: Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildInspectionCard(Inspection inspection) {
    final isCompleted = ['completed', 'submitted'].contains(inspection.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        Text(inspection.location?.name ?? 'Unknown Location', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(inspection.template?.name ?? 'Inspection', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                     ],
                   ),
                 ),
                 if (inspection.scheduledDate != null)
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                        const Text('Scheduled', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(DateFormat('h:mm a').format(inspection.scheduledDate!), style: const TextStyle(fontWeight: FontWeight.bold)),
                     ],
                   )
               ],
             ),
             const SizedBox(height: 12),
             Row(
               children: [
                 _buildStatusBadge(inspection.status),
                 const Spacer(),
                 if (isCompleted)
                    ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check),
                      label: const Text('Completed'),
                      style: ElevatedButton.styleFrom(disabledBackgroundColor: Colors.green.shade50, disabledForegroundColor: Colors.green),
                    )
                 else
                    ElevatedButton.icon(
                      onPressed: () => _startInspection(inspection),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(inspection.status == 'in_progress' ? 'Continue' : 'Start'),
                    )
               ],
             )
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    final isResolved = ['resolved', 'closed', 'completed'].contains(ticket.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Expanded(
                   child: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                 ),
                 _buildPriorityBadge(ticket.priority),
               ],
             ),
             const SizedBox(height: 8),
             Text(ticket.location?.name ?? 'Unknown Location', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
             const SizedBox(height: 8),
             Text(ticket.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
             const SizedBox(height: 12),
             Row(
               children: [
                 _buildStatusBadge(ticket.status),
                 const Spacer(),
                 if (isResolved)
                    ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check),
                      label: const Text('Resolved'),
                      style: ElevatedButton.styleFrom(disabledBackgroundColor: Colors.grey.shade200, disabledForegroundColor: Colors.grey),
                    )
                 else
                    ElevatedButton.icon(
                      onPressed: () => _startTicket(ticket),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Work'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primary, side: const BorderSide(color: AppTheme.primary)),
                    )
               ],
             )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(), 
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade700)
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color = Colors.grey;
    if (priority == 'high' || priority == 'urgent') color = Colors.red;
    if (priority == 'medium') color = Colors.orange;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.toUpperCase(), 
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)
      ),
    );
  }
}
