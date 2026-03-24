import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/services/inspection_service.dart';
import 'package:mobile_app/services/ticket_service.dart';
import 'package:mobile_app/models/inspection.dart';
import 'package:mobile_app/models/ticket.dart';
import 'package:mobile_app/config/theme.dart';
import 'package:mobile_app/widgets/app_drawer.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() => _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  bool _isLoading = true;
  int _assignedInspectionsCount = 0;
  int _openTicketsCount = 0;
  List<Inspection> _recentInspections = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final inspectionService = Provider.of<InspectionService>(context, listen: false);
      final ticketService = Provider.of<TicketService>(context, listen: false);

      if (user == null) throw Exception("User not authenticated");

      // Fetch assigned inspections
      final inspections = await inspectionService.getInspections(inspectorId: user.id);
      
      // Fetch assigned data for tickets (or all open, depending on logic)
      // For supervisors, usually tickets assigned to them or their location.
      // Assuming 'assignedTo' filter works.
      final tickets = await ticketService.getTickets(assignedTo: user.id);

      if (mounted) {
        setState(() {
          _assignedInspectionsCount = inspections.where((i) => i.status == 'pending' || i.status == 'in_progress').length;
          _openTicketsCount = tickets.where((t) => t.status == 'open' || t.status == 'in_progress').length;
          
          // Get recent inspections (last 3)
          inspections.sort((a, b) => (b.completedDate ?? b.scheduledDate ?? DateTime(2000)).compareTo(a.completedDate ?? a.scheduledDate ?? DateTime(2000)));
          _recentInspections = inspections.take(3).toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    if (_isLoading) {
      return const Scaffold(
        drawer: AppDrawer(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        drawer: const AppDrawer(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
              ElevatedButton(onPressed: _fetchDashboardData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Dashboard'),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${user?.name ?? "Supervisor"}!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Here is your overview for today.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Assigned Inspections',
                  _assignedInspectionsCount.toString(),
                  Icons.assignment,
                  Colors.blue,
                  () => Navigator.pushNamed(context, '/inspections'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Open Tickets',
                  _openTicketsCount.toString(),
                  Icons.confirmation_number,
                  Colors.orange,
                  () => Navigator.pushNamed(context, '/tickets'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // Quick Actions Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildActionCard(
                'Start Work',
                Icons.play_circle_fill,
                Colors.green,
                () => Navigator.pushNamed(context, '/start-work'),
              ),
              _buildActionCard(
                'New Inspection',
                Icons.add_circle,
                Colors.purple,
                () => Navigator.pushNamed(context, '/inspection-wizard'),
              ),
              _buildActionCard(
                'Schedule',
                Icons.calendar_month,
                Colors.teal,
                () => Navigator.pushNamed(context, '/schedule'),
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Text('Recent Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          if (_recentInspections.isEmpty)
            const Text('No recent activity.', style: TextStyle(color: Colors.grey))
          else
            ..._recentInspections.map((i) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  Icons.assignment_turned_in, 
                  color: i.status == 'completed' ? Colors.green : Colors.orange
                ),
                title: Text(i.template?.name ?? 'Inspection'),
                subtitle: Text('${i.location?.name ?? "Unknown"} • ${i.status}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                   // Navigate to details?
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.05), // Very light tint
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
