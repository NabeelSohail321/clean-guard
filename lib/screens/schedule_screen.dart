import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mobile_app/services/ticket_service.dart';
import 'package:mobile_app/services/inspection_service.dart';
import 'package:mobile_app/models/ticket.dart';
import 'package:mobile_app/models/inspection.dart';
import 'package:mobile_app/widgets/app_drawer.dart';
import 'package:intl/intl.dart';

import '../models/location.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = true;
  String _filterType = 'all'; // all, inspection, ticket
  bool _showMySchedule = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchScheduleData();
  }

  Future<void> _fetchScheduleData() async {
    setState(() => _isLoading = true);
    try {
      final ticketService = Provider.of<TicketService>(context, listen: false);
      final inspectionService = Provider.of<InspectionService>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      String? assignedToId;
      String? inspectorId;

      final isSupervisor = authProvider.user?.role == 'supervisor' || authProvider.user?.role == 'inspector';
      final isClient = authProvider.user?.role == 'client';

      if ((_showMySchedule && userId != null) || isSupervisor) {
        assignedToId = userId;
        inspectorId = userId;
      }

      final results = await Future.wait([
        ticketService.getTickets(assignedTo: assignedToId),
        inspectionService.getInspections(inspectorId: inspectorId),
      ]);

      var tickets = results[0] as List<Ticket>;
      var inspections = results[1] as List<Inspection>;
      
      // Filter for Client Role
      if (isClient) {
          final user = authProvider.user;
          if (user?.assignedLocations != null && user!.assignedLocations!.isNotEmpty) {
               final clientLocIds = user.assignedLocations!.map((l) => l is String ? l : (l as Location).id).toSet();
               tickets = tickets.where((t) => clientLocIds.contains(t.location)).toList();
               inspections = inspections.where((i) => clientLocIds.contains(i.locationId)).toList();
          }
      }

      final Map<DateTime, List<dynamic>> events = {};

      for (var t in tickets) {
        if (t.scheduledDate != null) {
          final date = normalizeDate(t.scheduledDate!);
          if (events[date] == null) events[date] = [];
          events[date]!.add(t);
        }
      }

      for (var i in inspections) {
        if (i.scheduledDate != null) {
          final date = normalizeDate(i.scheduledDate!);
          if (events[date] == null) events[date] = [];
          events[date]!.add(i);
        }
      }

      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading schedule: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final date = normalizeDate(day);
    final events = _events[date] ?? [];
    
    if (_filterType == 'all') return events;
    return events.where((e) {
      if (_filterType == 'inspection') return e is Inspection;
      if (_filterType == 'ticket') return e is Ticket;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      drawer: const AppDrawer(),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
            children: [
              _buildFilters(),
              TableCalendar(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: _getEventsForDay,
                calendarStyle: const CalendarStyle(
                  markerDecoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                ),
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Events for ${DateFormat('MMM d, y').format(_selectedDay!)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ..._getEventsForDay(_selectedDay!).map((event) {
                      if (event is Ticket) return _buildTicketCard(event);
                      if (event is Inspection) return _buildInspectionCard(event);
                      return const SizedBox();
                    }),
                     if (_getEventsForDay(_selectedDay!).isEmpty)
                       const Padding(
                         padding: EdgeInsets.only(top: 20),
                         child: Center(child: Text('No events scheduled for this day', style: TextStyle(color: Colors.grey))),
                       )
                  ],
                ),
              )
            ],
          ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Inspections', 'inspection'),
          const SizedBox(width: 8),
          _buildFilterChip('Tickets', 'ticket'),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('My Schedule'),
            selected: _showMySchedule,
            onSelected: (val) {
               setState(() => _showMySchedule = val);
               _fetchScheduleData();
            },
            selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
            checkmarkColor: Theme.of(context).primaryColor,
            labelStyle: TextStyle(
              color: _showMySchedule ? Theme.of(context).primaryColor : Colors.black87,
              fontWeight: _showMySchedule ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() => _filterType = value),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.confirmation_number, color: Colors.white, size: 20)),
        title: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Ticket • ${ticket.status} • ${ticket.location?.name ?? 'No Location'}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // View ticket details
        },
      ),
    );
  }

  Widget _buildInspectionCard(Inspection inspection) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.assignment, color: Colors.white, size: 20)),
        title: Text(inspection.template?.name ?? 'Inspection', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Inspection • ${inspection.status} • ${inspection.location?.name ?? 'No Location'}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // View inspection details
        },
      ),
    );
  }
}
