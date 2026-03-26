import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/config/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _profileData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null) {
       setState(() {
         _error = 'User not authenticated';
         _isLoading = false;
       });
       return;
    }
    
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final data = await userService.getProfile(auth.user!.id);
      if (mounted) {
         setState(() {
           _profileData = data;
           _isLoading = false;
         });
      }
    } catch (e) {
      if (mounted) {
         setState(() {
           _error = e.toString().replaceAll('Exception: ', '');
           _isLoading = false;
         });
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you absolutely sure you want to delete your account? This action cannot be undone and will erase all your personal data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm || !mounted) return;

    try {
      // Show loading overlay
      showDialog(
         context: context, 
         barrierDismissible: false, 
         builder: (_) => const Center(child: CircularProgressIndicator())
      );
      
      await userService.deleteUser(auth.user!.id);
      
      if (mounted) {
         // Clear loading popup
         Navigator.of(context).pop();
         
         // Trigger local logout sequentially and route home
         await auth.logout();
         
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Your account has been successfully deleted.'), backgroundColor: Colors.green),
            );
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
         }
      }
    } catch (e) {
      if (mounted) {
         Navigator.of(context).pop(); // clear loading
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to delete account: $e'), backgroundColor: AppTheme.danger),
         );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null 
          ? Center(child: Text('Error: $_error', style: const TextStyle(color: AppTheme.danger)))
          : _buildProfileContent(context),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    final user = _profileData!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          CircleAvatar(
            radius: 48,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            child: Text(
              user.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.text),
          ),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: AppTheme.secondary),
          ),
          const SizedBox(height: 32),

          // Details Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   _buildDetailRow(Icons.badge, 'Role', user.role.toUpperCase().replaceAll('_', ' ')),
                   const Divider(height: 24),
                   
                   _buildDetailRow(Icons.place, 'Assigned Locations', '${user.assignedLocations?.length ?? 0} Location(s)'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 48),

          // Action Buttons
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 16)
            ),
            onPressed: () async {
               final auth = Provider.of<AuthProvider>(context, listen: false);
               auth.logout();
               Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger.withValues(alpha: 0.1),
              foregroundColor: AppTheme.danger,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16)
            ),
            onPressed: _handleDeleteAccount,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
     return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Icon(icon, color: AppTheme.primary, size: 20),
           const SizedBox(width: 12),
           Expanded(
             child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(label, style: const TextStyle(color: AppTheme.secondary, fontSize: 13, fontWeight: FontWeight.w500)),
                   const SizedBox(height: 4),
                   Text(value, style: const TextStyle(color: AppTheme.text, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
             )
           )
        ],
     );
  }
}
