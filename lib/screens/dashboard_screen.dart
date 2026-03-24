import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';

import 'package:mobile_app/screens/admin_dashboard_screen.dart';
import 'package:mobile_app/screens/supervisor_dashboard_screen.dart';
import 'package:mobile_app/screens/client_dashboard_screen.dart';
import 'package:mobile_app/widgets/app_drawer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    // If not authenticated, we should not be here.
    // AuthWrapper usually handles this, but if we pushed/replaced to /dashboard,
    // we need to handle the case where auth state changes while this screen is active.
    if (!authProvider.isAuthenticated) {
      // Return a loading state or empty scaffold while the logout navigation finishes
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isAdmin = user?.role == 'admin' || user?.role == 'sub_admin';

    // Route based on role
    if (user?.role == 'client') {
      return const ClientDashboardScreen();
    }
    
    // Fallback/Default routing
    if (isAdmin) {
      return const AdminDashboardScreen();
    } else {
      // Supervisor or others (Inspector fallback)
      return const SupervisorDashboardScreen();
    }
  }
}
