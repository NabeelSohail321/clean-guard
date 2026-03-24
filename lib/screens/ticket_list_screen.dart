import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/services/ticket_service.dart';
import 'package:mobile_app/models/ticket.dart';
import 'package:mobile_app/widgets/app_drawer.dart';
import 'package:mobile_app/screens/ticket_details_screen.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:intl/intl.dart';

import '../models/location.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> with SingleTickerProviderStateMixin {
  late Future<List<Ticket>> _ticketsFuture;
  late TabController _tabController;
  
  String _filterStatus = 'all';
  String _filterPriority = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshTickets() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final isSupervisor = user?.role == 'supervisor' || user?.role == 'inspector';

    setState(() {
      _ticketsFuture = Provider.of<TicketService>(context, listen: false).getTickets(assignedTo: isSupervisor ? user?.id : null);
    });
  }

  List<Ticket> _filterTickets(List<Ticket> tickets) {
    return tickets.where((t) {
      // Tab Filter
      if (_tabController.index == 0) { // Inbox
         if (['resolved', 'closed', 'verified'].contains(t.status)) return false;
      } else if (_tabController.index == 1) { // Scheduled
         if (t.scheduledDate == null) return false;
      }
      // Index 2 is All, no filter

      // Status Filter
      if (_filterStatus != 'all' && t.status != _filterStatus) return false;

      // Priority Filter
      if (_filterPriority != 'all' && t.priority != _filterPriority) return false;

      // Search Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = t.title.toLowerCase().contains(query);
        final matchesId = t.id.toLowerCase().contains(query);
        if (!matchesTitle && !matchesId) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issues & Tickets'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Inbox'),
            Tab(text: 'Scheduled'),
            Tab(text: 'All'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Filters & Search
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by ID or Title',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDropdownFilter(
                        value: _filterStatus,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                          DropdownMenuItem(value: 'open', child: Text('Open')),
                          DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                          DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                           DropdownMenuItem(value: 'verified', child: Text('Verified')),
                           DropdownMenuItem(value: 'closed', child: Text('Closed')),
                        ],
                        onChanged: (val) => setState(() => _filterStatus = val!),
                      ),
                      const SizedBox(width: 8),
                      _buildDropdownFilter(
                        value: _filterPriority,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Priorities')),
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                          DropdownMenuItem(value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                          DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                        ],
                        onChanged: (val) => setState(() => _filterPriority = val!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: FutureBuilder<List<Ticket>>(
              future: _ticketsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allTickets = snapshot.data ?? [];
                
                // Filter for Client Role
                final user = Provider.of<AuthProvider>(context, listen: false).user;
                var displayTickets = allTickets;
                
                if (user?.role == 'client') {
                   if (user?.assignedLocations != null && user!.assignedLocations!.isNotEmpty) {
                       final clientLocIds = user.assignedLocations!.map((l) => l is String ? l : (l as Location).id).toSet();
                       displayTickets = allTickets.where((t) => clientLocIds.contains(t.location)).toList();
                   } else {
                       // Fallback if no locations assigned or loaded differently, assume empty or all?
                       // Safer to show empty or rely on backend.
                       // displayTickets = []; 
                   }
                }

                final tickets = _filterTickets(displayTickets);

                if (tickets.isEmpty) {
                  return const Center(child: Text('No tickets found'));
                }

                return ListView.builder(
                  itemCount: tickets.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return Card(
                      // ... (Card content remains same)
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: InkWell(
                        onTap: () async {
                           final refresh = await Navigator.push(
                             context,
                             MaterialPageRoute(builder: (_) => TicketDetailsScreen(ticket: ticket)),
                           );
                           if (refresh == true) {
                             _refreshTickets();
                           }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                       _buildPriorityBadge(ticket.priority),
                                       const SizedBox(width: 8),
                                       Text('#${ticket.id.substring(ticket.id.length - 6)}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                    ],
                                  ),
                                  Text(
                                    DateFormat('MMM d, y').format(ticket.createdAt),
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(ticket.location?.name ?? 'Unknown Location', style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(ticket.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87)),
                              const SizedBox(height: 12),
                              if (ticket.scheduledDate != null)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text('Scheduled: ${DateFormat('MMM d').format(ticket.scheduledDate!)}', style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatusBadge(ticket.status),
                                  // Add action buttons here if needed
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: (Provider.of<AuthProvider>(context).user?.role == 'admin' || 
                             Provider.of<AuthProvider>(context).user?.role == 'sub_admin' || 
                             Provider.of<AuthProvider>(context).user?.role == 'client') 
      ? FloatingActionButton(
        onPressed: () async {
          final refresh = await Navigator.pushNamed(context, '/tickets/new');
          if (refresh == true) {
            _refreshTickets();
          }
        },
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildDropdownFilter({required String value, required List<DropdownMenuItem<String>> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          isDense: true,
        ),
      ),
    );
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(priority.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
