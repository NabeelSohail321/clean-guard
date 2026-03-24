import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/models/work_stats.dart';
import 'package:mobile_app/services/work_stats_service.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class WorkStatsScreen extends StatefulWidget {
  const WorkStatsScreen({super.key});

  @override
  State<WorkStatsScreen> createState() => _WorkStatsScreenState();
}

class _WorkStatsScreenState extends State<WorkStatsScreen> {
  bool _isLoading = true;
  WorkStatsResponse? _statsData;
  User? _currentUser;
  
  String _selectedUserId = 'all';
  String _activeDateFilter = 'last_30_days';
  String _activityFilter = 'all';
  
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    _setDateRangeFilter(_activeDateFilter);
    _fetchStats();
  }

  bool get _isAdmin => _currentUser?.role == 'admin' || _currentUser?.role == 'sub_admin';

  void _setDateRangeFilter(String filterType) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    DateTime start;
    DateTime end = DateTime(today.year, today.month, today.day, 23, 59, 59);

    switch (filterType) {
      case 'today':
        start = todayStart;
        break;
      case 'this_week':
        int diff = today.weekday - 1; // 1 = Monday
        start = todayStart.subtract(Duration(days: diff));
        break;
      case 'this_month':
        start = DateTime(today.year, today.month, 1);
        break;
      case 'last_30_days':
        start = todayStart.subtract(const Duration(days: 30));
        break;
      case 'last_60_days':
        start = todayStart.subtract(const Duration(days: 60));
        break;
      default:
        start = todayStart.subtract(const Duration(days: 30));
    }

    setState(() {
      _startDate = start;
      _endDate = end;
      _activeDateFilter = filterType;
    });
    
    if (!_isLoading) _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final service = Provider.of<WorkStatsService>(context, listen: false);
      final data = await service.getWorkStats(
        startDate: _startDate,
        endDate: _endDate,
        userId: _isAdmin ? _selectedUserId : null,
      );
      if (mounted) {
        setState(() {
          _statsData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load work stats')));
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatHours(double? hours) {
    if (hours == null) return '—';
    if (hours < 1) return '${(hours * 60).round()}m';
    if (hours < 24) return '${hours.toStringAsFixed(1)}h';
    final days = (hours / 24).floor();
    final remaining = (hours % 24).round();
    return remaining > 0 ? '${days}d ${remaining}h' : '${days}d';
  }



  Widget _buildSummaryCard(String title, String value, String? subValue, IconData icon, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width / 2) - 24,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (subValue != null)
                      Text(' / $subValue', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildUserBreakdownTile(UserStats u) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: const Border(),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   Text(u.role.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text('${u.tickets.resolved} tickets', style: TextStyle(color: Colors.blue.shade800, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                child: Text('${u.inspections.completed} inspections', style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
               border: Border(top: BorderSide(color: Colors.grey.shade200))
            ),
            child: Wrap(
               spacing: 16,
               runSpacing: 16,
               children: [
                  _buildDetailItem('Tickets Assigned', u.tickets.assigned.toString()),
                  _buildDetailItem('Tickets Started', u.tickets.started.toString()),
                  _buildDetailItem('Tickets Resolved', u.tickets.resolved.toString()),
                  _buildDetailItem('Avg Resolution', _formatHours(u.tickets.avgResolutionHours)),
                  _buildDetailItem('Inspections Assigned', u.inspections.assigned.toString()),
                  _buildDetailItem('Inspections Completed', u.inspections.completed.toString()),
                  _buildDetailItem('Avg Score', '${u.inspections.avgScore.toStringAsFixed(1)}%'),
                  _buildDetailItem('Avg Completion', _formatHours(u.inspections.avgCompletionHours)),
               ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
     return SizedBox(
        width: (MediaQuery.of(context).size.width / 2) - 48,
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
           ],
        ),
     );
  }

  Widget _buildActivityCard(WorkActivity a) {
    final isTicket = a.type == 'ticket';
    final badgeColor = isTicket ? Colors.red.shade50 : Colors.blue.shade50;
    final badgeText = isTicket ? Colors.red.shade800 : Colors.blue.shade800;
    final statusColor = a.status == 'resolved' || a.status == 'completed' ? Colors.green 
                     : a.status == 'in_progress' ? Colors.blue 
                     : a.status == 'open' ? Colors.red : Colors.orange;

    return Card(
       margin: const EdgeInsets.only(bottom: 12),
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
       child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                         decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(4)),
                         child: Text(isTicket ? 'TICKET' : 'INSPECTION', style: TextStyle(color: badgeText, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      Text(a.person, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                   ],
                ),
                const SizedBox(height: 12),
                Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                if (a.locationName.isNotEmpty) ...[
                   const SizedBox(height: 4),
                   Row(
                      children: [
                         const Icon(Icons.location_on, size: 12, color: Colors.grey),
                         const SizedBox(width: 4),
                         Expanded(child: Text(a.locationName, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                      ],
                   )
                ],
                const Divider(height: 24),
                Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            const Text('STATUS', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text((a.status ?? 'Unknown').replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                         ],
                      ),
                      Column(
                         crossAxisAlignment: CrossAxisAlignment.end,
                         children: [
                            const Text('TIME TAKEN', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            a.timeTakenHours != null 
                              ? Text(_formatHours(a.timeTakenHours), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade800))
                              : const Text('In progress', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                         ],
                      )
                   ],
                )
             ],
          ),
       ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _statsData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final summary = _statsData?.summary;
    final filteredActivity = _statsData?.activity.where((a) => _activityFilter == 'all' || a.type == _activityFilter).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Stats'),
        actions: [
           IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchStats)
        ],
      ),
      body: CustomScrollView(
        slivers: [
           SliverToBoxAdapter(
              child: Container(
                 padding: const EdgeInsets.all(16),
                 child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       const Text('Track work activity, completion times, and performance', style: TextStyle(color: Colors.grey)),
                       const SizedBox(height: 12),
                       Row(
                          children: [
                             const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                             const SizedBox(width: 8),
                             Text("${DateFormat('MMM d, y').format(_startDate)} — ${DateFormat('MMM d, y').format(_endDate)}", style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                       ),
                       const SizedBox(height: 24),
                       
                       const Text('PERIOD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                       const SizedBox(height: 8),
                       SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                             children: [
                                'today', 'this_week', 'this_month', 'last_30_days', 'last_60_days'
                             ].map((f) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                   label: Text(f.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 12)),
                                   selected: _activeDateFilter == f,
                                   onSelected: (selected) {
                                      if (selected) _setDateRangeFilter(f);
                                   },
                                ),
                             )).toList(),
                          ),
                       ),
                       
                       if (_isAdmin && _statsData != null && _statsData!.supervisors.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('PERSON', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Container(
                             padding: const EdgeInsets.symmetric(horizontal: 12),
                             decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8)
                             ),
                             child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                   isExpanded: true,
                                   value: _selectedUserId,
                                   items: [
                                      const DropdownMenuItem(value: 'all', child: Text('All Users')),
                                      ..._statsData!.supervisors.map((s) => DropdownMenuItem(value: s.id, child: Text("${s.name} (${s.role.replaceAll('_', ' ')})")))
                                   ],
                                   onChanged: (val) {
                                      setState(() => _selectedUserId = val ?? 'all');
                                      _fetchStats();
                                   },
                                ),
                             ),
                          )
                       ],
                       
                       const SizedBox(height: 24),
                       if (summary != null) Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                             _buildSummaryCard('Total Tickets', summary.totalTickets.toString(), null, Icons.error_outline, Colors.blue),
                             _buildSummaryCard('Resolved', summary.totalTicketsResolved.toString(), null, Icons.check_circle_outline, Colors.green),
                             _buildSummaryCard('Avg Resolution', _formatHours(summary.avgTicketResolutionHours), null, Icons.access_time, Colors.orange),
                             _buildSummaryCard('Inspections', summary.totalInspectionsCompleted.toString(), summary.totalInspections.toString(), Icons.assignment_turned_in, Colors.purple),
                             _buildSummaryCard('Avg Score', "${summary.avgInspectionScore?.toStringAsFixed(1) ?? '0.0'}%", null, Icons.analytics, Colors.teal),
                          ],
                       ),

                       if (_isAdmin && _statsData != null && _statsData!.userStats.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          const Row(
                             children: [
                                Icon(Icons.people, size: 18),
                                SizedBox(width: 8),
                                Text('Per-Person Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                             ],
                          ),
                          const SizedBox(height: 16),
                          ..._statsData!.userStats.map((u) => _buildUserBreakdownTile(u))
                       ],

                       const SizedBox(height: 32),
                       const Row(
                          children: [
                             Icon(Icons.timeline, size: 18),
                             SizedBox(width: 8),
                             Text('Activity Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                       ),
                       const SizedBox(height: 12),
                       Row(
                          children: [
                             ChoiceChip(label: const Text('All'), selected: _activityFilter == 'all', onSelected: (v) => v ? setState(() => _activityFilter = 'all') : null),
                             const SizedBox(width: 8),
                             ChoiceChip(label: const Text('Tickets'), selected: _activityFilter == 'ticket', onSelected: (v) => v ? setState(() => _activityFilter = 'ticket') : null),
                             const SizedBox(width: 8),
                             ChoiceChip(label: const Text('Inspections'), selected: _activityFilter == 'inspection', onSelected: (v) => v ? setState(() => _activityFilter = 'inspection') : null),
                          ],
                       ),
                       const SizedBox(height: 16),
                       if (filteredActivity.isEmpty)
                         const Center(child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No activity found for this period.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                         ))
                       else 
                         ...filteredActivity.map((a) => _buildActivityCard(a)),
                       const SizedBox(height: 32),
                    ],
                 ),
              )
           )
        ],
      )
    );
  }
}
