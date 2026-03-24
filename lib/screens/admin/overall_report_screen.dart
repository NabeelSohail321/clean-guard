import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/services/report_service.dart';
import 'package:mobile_app/services/location_service.dart';
import 'package:mobile_app/models/location.dart';
import 'package:intl/intl.dart';

class OverallReportScreen extends StatefulWidget {
  const OverallReportScreen({super.key});

  @override
  State<OverallReportScreen> createState() => _OverallReportScreenState();
}

class _OverallReportScreenState extends State<OverallReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedLocation = 'all';
  List<Location> _locations = [];
  Map<String, dynamic>? _data;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _fetchReport();
  }

  Future<void> _loadLocations() async {
    try {
      final locs = await Provider.of<LocationService>(context, listen: false).getLocations();
      if (mounted) setState(() => _locations = locs);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    try {
      final data = await Provider.of<ReportService>(context, listen: false).getOverallReport(
        startDate: _startDate,
        endDate: _endDate,
        locationId: _selectedLocation,
      );
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overall Report')),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedLocation,
                        decoration: const InputDecoration(labelText: 'Location', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('All Locations')),
                          ..._locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedLocation = val);
                            _fetchReport();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                      });
                      _fetchReport();
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text('${DateFormat('MMM d, y').format(_startDate)} - ${DateFormat('MMM d, y').format(_endDate)}'),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _data == null 
                  ? const Center(child: Text('No data loaded'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_data!.isNotEmpty) ...[
                           _buildStatCard('Total Inspections', _data!['totalStartWork']?.toString() ?? '0', Colors.blue),
                           _buildStatCard('Average APPA', '${(_data!['overallAverage'] ?? 0).toStringAsFixed(1)}', Colors.green),
                           _buildStatCard('Tickets Created', _data!['totalTickets']?.toString() ?? '0', Colors.orange),
                           // Add more stats/charts here matching React
                        ]
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
