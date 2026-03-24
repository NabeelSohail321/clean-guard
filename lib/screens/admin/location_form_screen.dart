import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/models/location.dart';
import 'package:mobile_app/services/location_service.dart';

class LocationFormScreen extends StatefulWidget {
  final Location? location; // If null, creating new

  const LocationFormScreen({super.key, this.location});

  @override
  State<LocationFormScreen> createState() => _LocationFormScreenState();
}

class _LocationFormScreenState extends State<LocationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _typeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location?.name ?? '');
    _addressController = TextEditingController(text: widget.location?.address ?? '');
    _typeController = TextEditingController(text: widget.location?.type ?? 'building');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final service = Provider.of<LocationService>(context, listen: false);
      final data = {
        'name': _nameController.text,
        'address': _addressController.text,
        'type': _typeController.text,
      };

      if (widget.location != null) {
        await service.updateLocation(widget.location!.id, data);
      } else {
        await service.createLocation(data);
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh list
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
    final isEditing = widget.location != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Location' : 'New Location'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _typeController.text.isNotEmpty ? _typeController.text : 'building',
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'building', child: Text('Building')),
                  DropdownMenuItem(value: 'floor', child: Text('Floor')),
                  DropdownMenuItem(value: 'room', child: Text('Room')),
                ],
                onChanged: (val) {
                  if (val != null) _typeController.text = val;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
