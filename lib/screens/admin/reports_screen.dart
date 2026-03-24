import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/app_drawer.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildReportCard(
            context,
            'Overall Report',
            'General statistics and performance metrics',
            Icons.bar_chart,
            '/reports/overall',
            Colors.blue,
          ),
          _buildReportCard(
            context,
            'Inspector Leaderboard',
            'Performance ranking of inspectors',
            Icons.leaderboard,
            '/reports/inspectors',
            Colors.orange,
          ),
          _buildReportCard(
            context,
            'Tickets Report',
            'Analysis of ticket resolution and types',
            Icons.confirmation_number,
            '/reports/tickets',
            Colors.red,
          ),
           // Add other reports as needed
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String title, String subtitle, IconData icon, String route, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
            // Check if route is implemented
            if (route == '/reports/overall' || route == '/reports/inspectors') {
               Navigator.pushNamed(context, route);
            } else {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report coming soon')));
            }
        },
      ),
    );
  }
}
