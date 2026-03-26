import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _animationDone = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 1500)
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
       CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
       CurvedAnimation(parent: _controller, curve: Curves.easeIn)
    );
    
    _controller.forward();

    // Ensure splash shows for at least 2 seconds
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _animationDone = true;
        _checkAndNavigate();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.addListener(_checkAndNavigate);
      _checkAndNavigate();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkAndNavigate() {
    if (!_animationDone) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.loading && mounted) {
      auth.removeListener(_checkAndNavigate);
      _navigate(auth.isAuthenticated);
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
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
             animation: _controller,
             builder: (context, child) {
               return Opacity(
                 opacity: _fadeAnimation.value,
                 child: Transform.scale(
                   scale: _scaleAnimation.value,
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Container(
                         width: 100,
                         height: 100,
                         decoration: BoxDecoration(
                           color: theme.colorScheme.primary,
                           shape: BoxShape.circle,
                           boxShadow: [
                             BoxShadow(
                               color: theme.colorScheme.primary.withValues(alpha: 0.4),
                               blurRadius: 15,
                               offset: const Offset(0, 5),
                             ),
                           ],
                         ),
                         alignment: Alignment.center,
                         child: Text(
                           'CG',
                           style: GoogleFonts.outfit(
                             color: Colors.white,
                             fontSize: 42,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ),
                       const SizedBox(height: 24),
                       Text(
                         'CleanGuard QC',
                         style: GoogleFonts.outfit(
                           fontSize: 28,
                           fontWeight: FontWeight.bold,
                           color: theme.colorScheme.primary,
                           letterSpacing: -0.5,
                         ),
                       ),
                       const SizedBox(height: 8),
                       Text(
                         'Professional Quality Control',
                         style: TextStyle(
                           fontSize: 14,
                           fontWeight: FontWeight.w500,
                           letterSpacing: 0.5,
                           color: theme.colorScheme.secondary,
                         ),
                       ),
                       const SizedBox(height: 48),
                       SizedBox(
                         width: 32,
                         height: 32,
                         child: CircularProgressIndicator(
                           strokeWidth: 3, 
                           valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)
                         )
                       )
                     ],
                   ),
                 ),
               );
             }
          ),
        ),
      ),
    );
  }
}
