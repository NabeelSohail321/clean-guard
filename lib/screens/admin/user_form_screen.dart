import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/models/user.dart';
import 'package:mobile_app/models/location.dart';
import 'package:mobile_app/services/user_service.dart';
import 'package:mobile_app/services/location_service.dart';

class UserFormScreen extends StatefulWidget {
  final User? user;

  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String _selectedRole = 'supervisor';
  List<String> _selectedLocations = [];
  bool _isLoading = false;
  List<Location> _availableLocations = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    _selectedRole = widget.user?.role ?? 'supervisor';
    _selectedLocations = List.from(widget.user?.assignedLocations ?? []);
    
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final locs = await Provider.of<LocationService>(context, listen: false).getLocations();
      setState(() {
        _availableLocations = locs;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading locations: $e')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final service = Provider.of<UserService>(context, listen: false);
      final data = {
        'name': _nameController.text,
        'email': _emailController.text,
        'role': _selectedRole,
        'assignedLocations': _selectedLocations,
      };
      
      if (_passwordController.text.isNotEmpty) {
        data['password'] = _passwordController.text;
      }

      if (widget.user != null) {
        await service.updateUser(widget.user!.id, data);
      } else {
        // Password required for new user
        if (_passwordController.text.isEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password is required for new users')));
           setState(() => _isLoading = false);
           return;
        }
        await service.createUser(data);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user != null ? 'Edit User' : 'New User'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: widget.user != null ? 'Leave blank to keep existing' : null,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'sub_admin', child: Text('Sub Admin')),
                  DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                  DropdownMenuItem(value: 'client', child: Text('Client')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRole = val);
                },
              ),
              
              if (_selectedRole == 'client') ...[
                const SizedBox(height: 24),
                const Text('Assigned Locations', style: TextStyle(fontWeight: FontWeight.bold)),
                if (_availableLocations.isEmpty)
                   const Text('No locations available', style: TextStyle(color: Colors.grey)),
                   
                ..._availableLocations.map((loc) {
                  return CheckboxListTile(
                    title: Text(loc.name),
                    value: _selectedLocations.contains(loc.id),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedLocations.add(loc.id);
                        } else {
                          _selectedLocations.remove(loc.id);
                        }
                      });
                    },
                  );
                }),
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(widget.user != null ? 'Update User' : 'Create User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
