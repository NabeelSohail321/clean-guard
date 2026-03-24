import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/screens/admin/template_form_screen.dart';
import 'package:mobile_app/screens/admin/template_list_screen.dart';
import 'package:mobile_app/screens/admin_dashboard_screen.dart';
import 'package:mobile_app/screens/client_dashboard_screen.dart';
import 'package:mobile_app/screens/supervisor_dashboard_screen.dart';
import 'package:mobile_app/services/ticket_service.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/config/theme.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/admin_dashboard_service.dart';
import 'package:mobile_app/services/location_service.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/services/template_service.dart';
import 'package:mobile_app/services/inspection_service.dart';
import 'package:mobile_app/services/report_service.dart';
import 'package:mobile_app/screens/admin/reports_screen.dart';
import 'package:mobile_app/screens/admin/overall_report_screen.dart';
import 'package:mobile_app/screens/admin/inspector_leaderboard_screen.dart';
import 'package:mobile_app/screens/admin/work_stats_screen.dart';
import 'package:mobile_app/services/work_stats_service.dart';
import 'package:mobile_app/screens/ticket_list_screen.dart';
import 'package:mobile_app/screens/schedule_screen.dart';
import 'package:mobile_app/screens/start_work_screen.dart';
import 'package:mobile_app/providers/dashboard_provider.dart';
import 'package:mobile_app/screens/login_screen.dart';
import 'package:mobile_app/screens/dashboard_screen.dart';
import 'package:mobile_app/screens/splash_screen.dart';
import 'package:mobile_app/screens/admin/location_list_screen.dart';
import 'package:mobile_app/screens/admin/location_form_screen.dart';
import 'package:mobile_app/models/location.dart';
import 'package:mobile_app/screens/admin/user_list_screen.dart';
import 'package:mobile_app/screens/admin/user_form_screen.dart';
import 'package:mobile_app/models/user.dart';

import 'package:mobile_app/screens/ticket_form_screen.dart';

import 'package:mobile_app/screens/inspection_wizard_screen.dart';
import 'package:mobile_app/screens/inspection_list_screen.dart';
import 'firebase_options.dart';
import 'models/template.dart';
import 'notification_service.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notifications and request permissions immediately
  final notificationServices = NotificationServices();
  await notificationServices.requestNotificationPermission();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    // Ideally use a ServiceLocator or just simple DI here
    final apiService = ApiService();
    final locationService = LocationService(apiService);
    final adminDashboardService = AdminDashboardService(apiService);
    final userService = UserService(apiService);
    final templateService = TemplateService(apiService);
    final reportService = ReportService(apiService);
    final ticketService = TicketService(apiService);
    final inspectionService = InspectionService(apiService);
    final workStatsService = WorkStatsService(apiService);

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<LocationService>.value(value: locationService),
        Provider<AdminDashboardService>.value(value: adminDashboardService),
        Provider<UserService>.value(value: userService),
        Provider<TemplateService>.value(value: templateService),
        Provider<ReportService>.value(value: reportService),
        Provider<TicketService>.value(value: ticketService),
        Provider<InspectionService>.value(value: inspectionService),
        Provider<WorkStatsService>.value(value: workStatsService),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(apiService),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (_) => DashboardProvider(adminDashboardService, locationService),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'CleanGuard QC',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            home: const AuthWrapper(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/dashboard': (context) => const DashboardScreen(), // Keep for now, but AuthWrapper will override
              '/admin-dashboard': (context) => const AdminDashboardScreen(),
              '/supervisor-dashboard': (context) => const SupervisorDashboardScreen(),
              // Inspector dashboard route removed or redirected
              '/inspector-dashboard': (context) => const InspectionListScreen(), 
              '/client-dashboard': (context) => const ClientDashboardScreen(),
              '/admin/locations': (context) => const LocationListScreen(),
              '/admin/locations/new': (context) => const LocationFormScreen(),
              '/admin/locations/edit': (context) => LocationFormScreen(location: ModalRoute.of(context)!.settings.arguments as Location),
              '/users': (context) => const UserListScreen(),
              '/users/new': (context) => const UserFormScreen(),
              '/users/edit': (context) => UserFormScreen(user: ModalRoute.of(context)!.settings.arguments as User),
              '/admin/templates': (context) => const TemplateListScreen(),
              '/admin/templates/new': (context) => const TemplateFormScreen(),
              '/admin/templates/edit': (context) => TemplateFormScreen(template: ModalRoute.of(context)!.settings.arguments as Template),
              '/reports': (context) => const ReportsScreen(),
              '/reports/overall': (context) => const OverallReportScreen(),
              '/reports/inspectors': (context) => const InspectorLeaderboardScreen(),
              '/admin/work-stats': (context) => const WorkStatsScreen(),
              '/inspections': (context) => const InspectionListScreen(),
              '/tickets': (context) => const TicketListScreen(),
              '/schedule': (context) => const ScheduleScreen(),
              '/start-work': (context) => const StartWorkScreen(),
              '/inspection-wizard': (context) => const InspectionWizardScreen(),
              '/tickets/new': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                  return TicketFormScreen(
                    initialLocationId: args?['locationId'],
                    initialDescription: args?['description'],
                  );
              },
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    if (auth.loading) {
      return const SplashScreen();
    }
    
    if (auth.isAuthenticated) {
      return const DashboardScreen();
    }
    
    return const LoginScreen();
  }
}
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(message.notification!.title.toString());
}