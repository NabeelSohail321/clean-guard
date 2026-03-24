import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/models/location.dart';
import 'package:mobile_app/services/location_service.dart';
import 'package:mobile_app/widgets/app_drawer.dart';

class LocationListScreen extends StatefulWidget {
  const LocationListScreen({super.key});

  @override
  State<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  late Future<List<Location>> _locationsFuture;

  @override
  void initState() {
    super.initState();
    _refreshLocations();
  }

  void _refreshLocations() {
    setState(() {
      _locationsFuture = Provider.of<LocationService>(context, listen: false).getLocations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Locations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/admin/locations/new');
              if (result == true) _refreshLocations();
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<Location>>(
        future: _locationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final locations = snapshot.data ?? [];
          if (locations.isEmpty) {
            return const Center(child: Text('No locations found'));
          }

          return ListView.builder(
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return ListTile(
                title: Text(location.name),
                subtitle: Text(location.address ?? 'No address'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          context, 
                          '/admin/locations/edit', 
                          arguments: location
                        );
                        if (result == true) _refreshLocations();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(location),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(Location location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Are you sure you want to delete ${location.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await Provider.of<LocationService>(context, listen: false).deleteLocation(location.id);
        _refreshLocations();
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location deleted')));
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
