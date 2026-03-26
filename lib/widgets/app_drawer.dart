import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/config/theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final isAuth = auth.isAuthenticated;
    final isAdmin = user?.role == 'admin' || user?.role == 'sub_admin';

    if (!isAuth) return const SizedBox.shrink();

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
               Navigator.pop(context);
               Navigator.pushNamed(context, '/profile');
            },
            child: UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.primary,
              ),
              accountName: Text(user?.name ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(user?.email ?? '', style: const TextStyle(color: Colors.white70)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user?.name.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 24),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(context, 'Dashboard', Icons.dashboard, '/dashboard'),
                _buildDrawerItem(context, 'My Profile', Icons.person, '/profile'),
                _buildDrawerItem(context, 'Inspections', Icons.assignment, '/inspections'),
                _buildDrawerItem(context, 'Tickets', Icons.report_problem, '/tickets'),
                _buildDrawerItem(context, 'Schedule', Icons.calendar_month, '/schedule'),
                if (user?.role != 'client')
                  _buildDrawerItem(context, 'Start Work', Icons.play_circle_outline, '/start-work'),
                
                if (isAdmin) ...[
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 12, bottom: 8),
                    child: Text('ADMIN', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  _buildDrawerItem(context, 'Locations', Icons.place, '/admin/locations'),
                  _buildDrawerItem(context, 'Templates', Icons.description, '/admin/templates'),
                  _buildDrawerItem(context, 'User Management', Icons.people, '/users'),
                  _buildDrawerItem(context, 'Reports', Icons.bar_chart, '/reports'),
                  _buildDrawerItem(context, 'Work Stats', Icons.insights, '/admin/work-stats'),
                ],
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.danger),
            title: const Text('Logout', style: TextStyle(color: AppTheme.danger)),
            onTap: () {
              // Close drawer first
              Navigator.pop(context);
              
              // Logout (triggers notifyListeners internally)
              auth.logout();
               
              // Explicitly redirect to login and clear the entire navigation stack
              // Use pushNamedAndRemoveUntil to ensure we land on /login clean.
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
           const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, String title, IconData icon, String route) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isActive = currentRoute == route;

    return ListTile(
      leading: Icon(icon, color: isActive ? AppTheme.primary : AppTheme.secondary),
      title: Text(
        title, 
        style: TextStyle(
          color: isActive ? AppTheme.primary : AppTheme.text,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: AppTheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (!isActive) {
          if (route == '/dashboard') {
             // Pop until first to avoid stacking
             Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
             Navigator.pushNamed(context, route);
          }
        }
      },
    );
  }
}
