import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/models/inspection.dart';
import 'package:mobile_app/models/location.dart';
import 'package:mobile_app/services/inspection_service.dart';
import 'package:mobile_app/services/location_service.dart';
import 'package:mobile_app/widgets/app_drawer.dart';
import 'package:mobile_app/config/theme.dart';
import 'package:mobile_app/screens/inspection_details_screen.dart';

import '../providers/auth_provider.dart';

class InspectionListScreen extends StatefulWidget {
  const InspectionListScreen({super.key});

  @override
  State<InspectionListScreen> createState() => _InspectionListScreenState();
}

class _InspectionListScreenState extends State<InspectionListScreen> {
  List<Inspection> _inspections = [];
  List<Location> _locations = [];
  bool _isLoading = true;

  // Filters
  String _searchQuery = '';
  String _scoreFilter = 'all';
  String _statusFilter = 'all';
  String _locationFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showMyInspections = false;

  @override
  void initState() {
    super.initState();
    // Default to showing logged-in user's inspections if they are not exclusively an admin?
    // Backend handles supervisor restriction. For admins, default to all is fine.
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();
    _fetchData();
  }
  
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      final isSupervisor = user?.role == 'supervisor' || user?.role == 'inspector';
      
      final inspectionService = Provider.of<InspectionService>(context, listen: false);
      final locationService = Provider.of<LocationService>(context, listen: false);

      final results = await Future.wait([
        inspectionService.getInspections(inspectorId: isSupervisor ? user?.id : null),
        locationService.getLocations(),
      ]);

      if (mounted) {
        setState(() {
          _inspections = results[0] as List<Inspection>;
          _locations = results[1] as List<Location>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  List<Inspection> get _filteredInspections {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    
    return _inspections.where((inspection) {
      // My Inspections Filter
      if (_showMyInspections && user != null) {
         if (inspection.inspectorId != user.id && inspection.inspector?.id != user.id) return false;
      }

      // Search
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final locName = inspection.location?.name.toLowerCase() ?? '';
        final tmplName = inspection.template?.name.toLowerCase() ?? '';
        final inspectorName = inspection.inspector?.name.toLowerCase() ?? '';
        final status = inspection.status.toLowerCase();
        
        if (!locName.contains(query) && 
            !tmplName.contains(query) && 
            !inspectorName.contains(query) && 
            !status.contains(query)) {
          return false;
        }
      }

      // Score Filter
      if (_scoreFilter == 'excellent' && inspection.totalScore < 90) return false;
      if (_scoreFilter == 'good' && (inspection.totalScore < 75 || inspection.totalScore >= 90)) return false;
      if (_scoreFilter == 'poor' && inspection.totalScore >= 75) return false;

      // Status Filter
      if (_statusFilter == 'in_progress' && inspection.status != 'in_progress') return false;
      if (_statusFilter == 'completed' && inspection.status != 'completed') return false;
      if (_statusFilter == 'pending' && inspection.status != 'pending') return false;
      
      // Flags
      if (_statusFilter == 'deficient' && !inspection.isDeficient) return false;
      if (_statusFilter == 'not_deficient' && inspection.isDeficient) return false;
      if (_statusFilter == 'flagged' && !inspection.isFlagged) return false;
      if (_statusFilter == 'not_flagged' && inspection.isFlagged) return false;
      if (_statusFilter == 'private' && !inspection.isPrivate) return false;
      if (_statusFilter == 'not_private' && inspection.isPrivate) return false;

      // Location Filter
      if (_locationFilter != 'all' && inspection.locationId != _locationFilter) return false;

      // Date Filter
      if (_startDate != null && _endDate != null) {
        final date = inspection.completedDate ?? inspection.scheduledDate;
        if (date != null) {
           if (date.isBefore(_startDate!) || date.isAfter(_endDate!.add(const Duration(days: 1)))) return false;
        }
      }

      return true;
    }).toList();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              SwitchListTile(
                 title: const Text('My Inspections Only'),
                 value: _showMyInspections,
                 onChanged: (val) => setModalState(() => _showMyInspections = val),
                 contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              
              const Text('Score', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _scoreFilter,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Scores')),
                  DropdownMenuItem(value: 'excellent', child: Text('Excellent (90%+)')),
                  DropdownMenuItem(value: 'good', child: Text('Good (75-89%)')),
                  DropdownMenuItem(value: 'poor', child: Text('Poor (<75%)')),
                ],
                onChanged: (val) => setModalState(() => _scoreFilter = val!),
              ),
              const SizedBox(height: 16),

              const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _statusFilter,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Inspections')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'deficient', child: Text('Deficient (Flag)')),
                  DropdownMenuItem(value: 'flagged', child: Text('Flagged (Flag)')),
                  DropdownMenuItem(value: 'private', child: Text('Private (Flag)')),
                ],
                onChanged: (val) => setModalState(() => _statusFilter = val!),
              ),
              const SizedBox(height: 16),

              const Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _locationFilter,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('All Locations')),
                  ..._locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))),
                ],
                onChanged: (val) => setModalState(() => _locationFilter = val!),
              ),
              const SizedBox(height: 16),
              
              const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      child: Text(_startDate == null ? 'From' : DateFormat('MMM d, y').format(_startDate!)),
                      onPressed: () async {
                         final d = await showDatePicker(context: context, initialDate: _startDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                         if(d != null) setModalState(() => _startDate = d);
                      },
                    ),
                  ),
                  const Text(' - '),
                  Expanded(
                    child: TextButton(
                      child: Text(_endDate == null ? 'To' : DateFormat('MMM d, y').format(_endDate!)),
                      onPressed: () async {
                         final d = await showDatePicker(context: context, initialDate: _endDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                         if(d != null) setModalState(() => _endDate = d);
                      },
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                   setState(() {}); // specific setState for the parent widget
                   Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isClient = user?.role == 'client';

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
             Icon(Icons.assignment, size: 24), 
             SizedBox(width: 8), 
             Text('Inspections')
          ], 
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: isClient ? null : FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/inspection-wizard'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterSheet,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _filteredInspections.isEmpty 
                  ? const Center(child: Text('No inspections found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredInspections.length,
                      itemBuilder: (context, index) => _buildInspectionCard(_filteredInspections[index]),
                    ),
          ),
        ],
      ),
    );
  }

  void _scheduleInspection(Inspection inspection) async {
    DateTime? selectedDate = inspection.scheduledDate ?? DateTime.now();
    TimeOfDay? selectedTime = inspection.scheduledDate != null 
        ? TimeOfDay.fromDateTime(inspection.scheduledDate!) 
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
      await service.scheduleInspection(inspection.id, dateTime);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inspection scheduled!')));
        _fetchData(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to schedule: $e')));
      }
    }
  }

  Widget _buildInspectionCard(Inspection inspection) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final isAdmin = user?.role == 'admin' || user?.role == 'sub_admin';

    // Score Colors
    Color scoreColor;
    List<Color> scoreGradient;
    if (inspection.totalScore >= 90) {
      scoreColor = const Color(0xFF10b981);
      scoreGradient = const [Color(0xFF10b981), Color(0xFF059669)];
    } else if (inspection.totalScore >= 75) {
      scoreColor = const Color(0xFFf59e0b);
      scoreGradient = const [Color(0xFFf59e0b), Color(0xFFd97706)];
    } else {
      scoreColor = const Color(0xFFef4444);
      scoreGradient = const [Color(0xFFef4444), Color(0xFFdc2626)];
    }

    // Status Colors
    List<Color> statusGradient;
    if (['completed', 'submitted'].contains(inspection.status)) {
       statusGradient = const [Color(0xFF10b981), Color(0xFF059669)];
    } else if (inspection.status == 'pending') {
       statusGradient = const [Color(0xFFf59e0b), Color(0xFFd97706)];
    } else {
       statusGradient = const [Color(0xFF3b82f6), Color(0xFF2563eb)];
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 // Flags
                 Wrap(
                   spacing: 8,
                   runSpacing: 8,
                   children: [
                     if (inspection.isDeficient) _buildFlagBadge('Deficient', const Color(0xFFfee2e2), const Color(0xFF991b1b)),
                     if (inspection.isFlagged) _buildFlagBadge('Flagged', const Color(0xFFfef3c7), const Color(0xFF92400e)),
                     if (inspection.isPrivate) _buildFlagBadge('Private', const Color(0xFFf3e8ff), const Color(0xFF6b21a8)),
                   ],
                 ),
                 if (inspection.isDeficient || inspection.isFlagged || inspection.isPrivate)
                   const SizedBox(height: 16),
                 
                 Padding(
                   padding: const EdgeInsets.only(right: 60), // Room for score badge
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                          const Icon(Icons.place, color: Color(0xFF3b82f6), size: 24),
                          const SizedBox(width: 8),
                          Expanded(child: Text(inspection.location?.name ?? 'Unknown Location', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1e293b)))),
                       ]),
                       const SizedBox(height: 8),
                       Row(children: [
                          const Icon(Icons.description, color: Color(0xFF64748b), size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(inspection.template?.name ?? 'Template', style: const TextStyle(color: Color(0xFF64748b), fontSize: 14))),
                       ]),
                     ],
                   )
                 ),

                 const SizedBox(height: 20),
                 
                 Row(
                   children: [
                     Expanded(
                       child: _buildInfoBox('Inspector', inspection.inspector?.name ?? 'Unassigned', Icons.person),
                     ),
                     const SizedBox(width: 12),
                     Expanded(
                       child: _buildInfoBox(
                         inspection.scheduledDate != null ? 'Scheduled' : 'Created', 
                         DateFormat('MMM d, y\nh:mm a').format(inspection.scheduledDate ?? inspection.completedDate ?? DateTime.now()), 
                         Icons.schedule
                       ),
                     ),
                   ],
                 ),
                 
                 const SizedBox(height: 20),
                 
                 // Status Badge
                 Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: statusGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                         BoxShadow(color: statusGradient[0].withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
                      ]
                    ),
                    child: Text(
                      inspection.status.toUpperCase().replaceAll('_', ' '),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12
                      ),
                    ),
                 ),

                 const SizedBox(height: 20),
                 const Divider(),
                 const SizedBox(height: 8),

                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Row(
                       children: [
                         if (isAdmin && !['completed', 'submitted'].contains(inspection.status) && inspection.inspector == null)
                           _buildActionButton(Icons.person, const [Color(0xFF3b82f6), Color(0xFF2563eb)], () {
                              // Assign logic
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use detail page to assign or wait for wizard update.')));
                           }, 'Assign'),
                         if ((!['completed', 'submitted'].contains(inspection.status)) && (inspection.scheduledDate == null || isAdmin))
                           Padding(
                             padding: const EdgeInsets.only(left: 8.0),
                             child: _buildActionButton(Icons.calendar_month, const [Color(0xFF8b5cf6), Color(0xFF7c3aed)], () => _scheduleInspection(inspection), 'Schedule'),
                           ),
                         if (user?.role == 'supervisor' && inspection.status == 'in_progress')
                           Padding(
                             padding: const EdgeInsets.only(left: 8.0),
                             child: _buildActionButton(Icons.check_circle, const [Color(0xFF10b981), Color(0xFF059669)], () {
                                Navigator.pushNamed(context, '/inspection-wizard', arguments: {'inspectionId': inspection.id}).then((_)=>_fetchData());
                             }, 'Perform'),
                           )
                       ],
                     ),
                     Row(
                       children: [
                         IconButton(
                           icon: const Icon(Icons.visibility, color: Color(0xFF475569)), 
                           tooltip: 'View Details',
                           onPressed: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(
                                 builder: (context) => InspectionDetailsScreen(inspectionId: inspection.id),
                               ),
                             ).then((_) => _fetchData()); // Refresh on return
                           }
                         ),
                         IconButton(
                           icon: const Icon(Icons.download, color: Color(0xFF475569)), 
                           tooltip: 'Download PDF',
                           onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Download not supported on mobile yet.')));
                           }
                         ),
                       ]
                     )
                   ],
                 )
              ],
            ),
          ),
          // Absolute Positioned Score Badge
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: scoreGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: scoreColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))
                ]
              ),
              child: Text(
                '${inspection.totalScore.toStringAsFixed(0)}%', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
              ),
            ),
          )
        ],
      ),
    );
  }
  
  Widget _buildActionButton(IconData icon, List<Color> gradient, VoidCallback onPressed, String tooltip) {
     return Container(
       decoration: BoxDecoration(
         gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
         borderRadius: BorderRadius.circular(10),
         boxShadow: [
           BoxShadow(color: gradient[0].withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
         ]
       ),
       child: IconButton(
         icon: Icon(icon, color: Colors.white, size: 18),
         tooltip: tooltip,
         onPressed: onPressed,
         constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
         padding: EdgeInsets.zero,
       ),
     );
  }

  Widget _buildFlagBadge(String text, Color bg, Color textC) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 12, color: textC),
          const SizedBox(width: 4),
          Text(text.toUpperCase(), style: TextStyle(color: textC, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  Widget _buildInfoBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFf8fafc), // Light slate
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 12, color: const Color(0xFF64748b)), 
            const SizedBox(width: 4), 
            Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, color: Color(0xFF64748b), fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1e293b), fontSize: 14)),
        ],
      ),
    );
  }
}

// Fix typo in AppBar Title standard usage
class ROW extends StatelessWidget {
   final List<Widget> children;
   const ROW({super.key, required this.children});
   @override Widget build(context) => Row(children: children);
}
