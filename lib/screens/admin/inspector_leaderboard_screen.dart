import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/services/report_service.dart';
import 'package:intl/intl.dart';

class InspectorLeaderboardScreen extends StatefulWidget {
  const InspectorLeaderboardScreen({super.key});

  @override
  State<InspectorLeaderboardScreen> createState() => _InspectorLeaderboardScreenState();
}

class _InspectorLeaderboardScreenState extends State<InspectorLeaderboardScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await Provider.of<ReportService>(context, listen: false).getInspectorLeaderboard(
        startDate: _startDate,
        endDate: _endDate,
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
      appBar: AppBar(title: const Text('Inspector Leaderboard')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
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
                  _fetchData();
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text('${DateFormat('MMM d, y').format(_startDate)} - ${DateFormat('MMM d, y').format(_endDate)}'),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _data.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final item = _data[index];
                    final rank = index + 1;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: rank <= 3 ? Colors.amber : Colors.grey.shade300,
                          child: Text('$rank'),
                        ),
                        title: Text(item['name'] ?? 'Unknown'),
                        subtitle: Text('${item['inspectionCount']} Inspections'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${(item['averageScore'] ?? 0).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Text('Avg Score', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
