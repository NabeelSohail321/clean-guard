import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
               content: Text('Account created successfully! Please sign in.'),
               backgroundColor: Colors.green,
               behavior: SnackBarBehavior.floating,
            ),
         );
         Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
             content: Text(errorMsg),
             backgroundColor: Colors.red.shade600,
             behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Header
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'CG',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Create an Account',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Join CleanGuard QC',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Sign Up Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Name
                          Text('Full Name', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(hintText: 'John Doe'),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                          
                          // Email
                          Text('Email Address', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(hintText: 'name@company.com'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                               if (value == null || value.trim().isEmpty) return 'Required';
                               if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                  return 'Enter a valid email address';
                               }
                               return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Password
                          Text('Password', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(hintText: '••••••••'),
                            validator: (value) {
                               if (value == null || value.isEmpty) return 'Required';
                               if (value.length < 6) return 'Password must be at least 6 characters';
                               return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Confirm Password
                          Text('Confirm Password', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(hintText: '••••••••'),
                            validator: (value) {
                               if (value == null || value.isEmpty) return 'Required';
                               if (value != _passwordController.text) return 'Passwords do not match';
                               return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          
                          // Submit Button
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                                : const Text('Sign Up'),
                            ),
                          ),
                           
                           const SizedBox(height: 16),
                           TextButton(
                              onPressed: () {
                                 Navigator.of(context).pop();
                              },
                              child: Text('Already have an account? Sign In', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                           )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
