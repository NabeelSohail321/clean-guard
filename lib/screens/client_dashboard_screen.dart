import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/services/inspection_service.dart';
import 'package:mobile_app/services/ticket_service.dart';
import 'package:mobile_app/services/location_service.dart';
import 'package:mobile_app/models/inspection.dart';
import 'package:mobile_app/models/ticket.dart';
import 'package:mobile_app/models/location.dart';
import 'package:mobile_app/widgets/app_drawer.dart';


class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  bool _isLoading = true;
  int _activeInspectionsCount = 0;
  int _openTicketsCount = 0;
  List<Ticket> _recentTickets = [];
  List<Location> _locations = [];
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

      // Fetch data. Logic should handle filtering by client's locations on the backend 
      // or we filter here if the service fetches all (which it shouldn't for client role ideally).
      // However, typical mobile services might just fetch "all assigned".
      // For Client, "assigned" means "locations assigned".
      
      // Note: We might need to ensure backend/service returns correct data for client role.
      // Assuming getInspections() and getTickets() handle this or return all and we filter?
      // Implementation Plan says we will update List Screens to filter.
      // For Dashboard, let's assume getInspections/getTickets returns "relevant" items 
      // OR we might need to filter by location locally if the API returns everything (unlikely for client).
      
      final locations = await Provider.of<LocationService>(context, listen: false).getLocations();
      final inspections = await inspectionService.getInspections(); 
      final tickets = await ticketService.getTickets();

      if (mounted) {
        setState(() {
          // Web parity: Trust the API to return relevant data for the client.
          // Filtering by user.assignedLocations locally caused issues if that field is empty 
          // or if the API already filters.
          
          _locations = locations;
          
          // Client sees "Active" inspections (scheduled/in progress)
          _activeInspectionsCount = inspections.where((i) => i.status == 'scheduled' || i.status == 'in_progress').length;

          // Client sees "Open" tickets
          _openTicketsCount = tickets.where((t) => t.status == 'open' || t.status == 'in_progress').length;

          // Get recent tickets
          tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _recentTickets = tickets.take(3).toList();

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
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
        title: const Text('Dashboard'),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: const AppDrawer(), // Add Side Bar
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        user?.name.substring(0, 1).toUpperCase() ?? 'C',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                          ),
                          Text(
                            user?.name ?? 'Client',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Client', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Text(
                'Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),

              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Locations',
                      _locations.length.toString(),
                      Icons.business,
                      Colors.indigo,
                      () {}, 
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Inspections',
                      _activeInspectionsCount.toString(),
                      Icons.assignment_outlined,
                      Colors.blue,
                      () => Navigator.pushNamed(context, '/inspections'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Issues',
                      _openTicketsCount.toString(),
                      Icons.warning_amber_rounded,
                      Colors.orange,
                      () => Navigator.pushNamed(context, '/tickets'),
                    ),
                  ),
                 ],
               ),
              
              const SizedBox(height: 32),

              // My Locations Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Locations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              const SizedBox(height: 12),
              
              if (_locations.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.business_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('No locations assigned', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Assigned locations will appear here.', 
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                 SizedBox(
                   height: 140, // Height for horizontal list
                   child: ListView.builder(
                     scrollDirection: Axis.horizontal,
                     itemCount: _locations.length,
                     itemBuilder: (context, index) {
                       final loc = _locations[index];
                       return Container(
                         width: 200,
                         margin: const EdgeInsets.only(right: 12),
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: Colors.white,
                           borderRadius: BorderRadius.circular(16),
                           boxShadow: [
                             BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                           ],
                           border: Border.all(color: Colors.grey.shade100),
                         ),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Container(
                               padding: const EdgeInsets.all(8),
                               decoration: BoxDecoration(
                                 color: Colors.indigo.shade50,
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               child: const Icon(Icons.business, color: Colors.indigo, size: 20),
                             ),
                             const Spacer(),
                             Text(
                               loc.name,
                               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                             ),
                             const SizedBox(height: 4),
                             Text(
                               loc.address ?? '',
                               style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                               maxLines: 2,
                               overflow: TextOverflow.ellipsis,
                             ),
                           ],
                         ),
                       );
                     },
                   ),
                 ),

              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/tickets'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              if (_recentTickets.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('No recent activity', style: TextStyle(color: Colors.grey.shade400)),
                    ],
                  ),
                )
              else
                ..._recentTickets.map((t) => _buildTicketItem(t)).toList(),
                
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTicketItem(Ticket t) {
    final isResolved = t.status == 'resolved';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(context, '/ticket-details', arguments: t),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isResolved ? Colors.green.shade50 : Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isResolved ? Icons.check_circle_outline : Icons.schedule,
                    color: isResolved ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.location?.name ?? "Unknown"} • ${t.status.toUpperCase()}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade300),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
