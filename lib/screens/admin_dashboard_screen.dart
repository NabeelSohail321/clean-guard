import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/dashboard_provider.dart';
import 'package:mobile_app/config/theme.dart';
import 'package:mobile_app/models/dashboard_data.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile_app/widgets/app_drawer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    final theme = Theme.of(context);

    if (provider.loading && provider.metrics == null) {
      return const Scaffold(
        drawer: AppDrawer(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        drawer: const AppDrawer(),
        body: Center(child: Text('Error: ${provider.error}')),
      );
    }

    final metrics = provider.metrics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Section (Simplified for mobile)
            _buildFilterSection(provider, theme),
            const SizedBox(height: 24),

            // Stats Grid
            if (metrics != null) ...[
              _buildStatsGrid(metrics),
              const SizedBox(height: 24),
            ],

            // Charts
            if (provider.inspectionsChartData.isNotEmpty) ...[
              Text('Inspections Performed', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildBarChart(provider.inspectionsChartData, AppTheme.primary),
              const SizedBox(height: 24),
            ],

            if (provider.ticketsChartData.isNotEmpty) ...[
              Text('Tickets Created', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildBarChart(provider.ticketsChartData, Colors.orange), // Use distinct color for tickets
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<CheckpointData> data, Color barColor) {
    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (data.isEmpty 
              ? 10 
              : data.map((e) => e.count).reduce((a, b) => a > b ? a : b) + 5).toDouble(),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${data[group.x.toInt()].date}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: (rod.toY - 1).toString(),
                      style: const TextStyle(color: Colors.yellowAccent),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                     // Calculate interval to show max 5 labels
                     final int totalItems = data.length;
                     final int interval = (totalItems / 5).ceil();
                     
                     if (value.toInt() % interval == 0) {
                       final date = data[value.toInt()].date;
                       return Padding(
                         padding: const EdgeInsets.only(top: 8.0),
                         child: Text(
                           date, 
                           style: const TextStyle(fontSize: 10),
                           textAlign: TextAlign.center,
                         ),
                       );
                     }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.count.toDouble(),
                  color: barColor,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterSection(DashboardProvider provider, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true, // Key fix for long text
              value: provider.selectedLocationId,
              decoration: const InputDecoration(
                labelText: 'Location',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Areas')),
                ...provider.locations.map((loc) => DropdownMenuItem(
                      value: loc.id,
                      child: Text(
                        loc.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )),
              ],
              onChanged: (value) {
                if (value != null) provider.setLocation(value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(

                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_formatDateRange(provider.startDate, provider.endDate)),
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: DateTimeRange(start: provider.startDate, end: provider.endDate),
                      );
                      if (picked != null) {
                        provider.setDateRange(picked.start, picked.end);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
  }

  Widget _buildStatsGrid(DashboardMetrics metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard(
              'Total Inspections',
              metrics.totalInspections.toString(),
              Icons.assignment,
              Colors.blue.shade100,
              Colors.blue.shade700,
              constraints.maxWidth / 2 - 8,
            ),
            _buildStatCard(
              'Average Score',
              '${metrics.averageScore}%',
              Icons.check_circle,
              Colors.green.shade100,
              Colors.green.shade700,
              constraints.maxWidth / 2 - 8,
            ),
            _buildStatCard(
              'Open Issues',
              metrics.openIssues.toString(),
              Icons.warning,
              Colors.red.shade100,
              Colors.red.shade700,
              constraints.maxWidth / 2 - 8,
            ),
            _buildStatCard(
              'Resolved',
              metrics.resolvedIssues.toString(),
              Icons.task_alt,
              Colors.purple.shade100,
              Colors.purple.shade700,
              constraints.maxWidth / 2 - 8,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color bg, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.secondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.text)),
        ],
      ),
    );
  }
}
