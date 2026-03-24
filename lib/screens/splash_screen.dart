import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  void _checkAuth() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.loading) {
       _navigate(auth.isAuthenticated);
    } else {
       // Wait slightly if still loading or listen to changes
       // Since AuthProvider init is async, we might need to wait
       // Actually AuthProvider constructor calls init, but it's async so it returns immediately.
       // We should rely on value changes or a Future.
       // However, we can also use a Consumer in MyApp to switch home.
       // But if we use named routes, SplashScreen is better.
       // Let's just wait a bit or check periodically.
       // Better: Use `FutureBuilder` or just rely on `Consumer` in `main.dart` which is cleaner.
       // For this file, I'll just check once after a delay to show splash.
       Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
             final auth = Provider.of<AuthProvider>(context, listen: false);
             _navigate(auth.isAuthenticated);
          }
       });
    }
  }

  void _navigate(bool isAuthenticated) {
    if (isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
