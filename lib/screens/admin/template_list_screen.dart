import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/models/template.dart';
import 'package:mobile_app/services/template_service.dart';
import 'package:mobile_app/widgets/app_drawer.dart';

class TemplateListScreen extends StatefulWidget {
  const TemplateListScreen({super.key});

  @override
  State<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends State<TemplateListScreen> {
  late Future<List<Template>> _templatesFuture;

  @override
  void initState() {
    super.initState();
    _refreshTemplates();
  }

  void _refreshTemplates() {
    setState(() {
      _templatesFuture = Provider.of<TemplateService>(context, listen: false).getTemplates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/admin/templates/new');
              if (result == true) _refreshTemplates();
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<Template>>(
        future: _templatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final templates = snapshot.data ?? [];
          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.description, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No templates yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.pushNamed(context, '/admin/templates/new');
                      if (result == true) _refreshTemplates();
                    },
                    child: const Text('Create Your First Template'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: templates.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final template = templates[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              template.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy, color: Colors.grey),
                                onPressed: () => _cloneTemplate(template),
                                tooltip: 'Clone',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () async {
                                  final result = await Navigator.pushNamed(
                                    context,
                                    '/admin/templates/edit',
                                    arguments: template,
                                  );
                                  if (result == true) _refreshTemplates();
                                },
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(template),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (template.description != null && template.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(template.description!),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildBadge('${template.sections.length} Sections'),
                          const SizedBox(width: 8),
                          _buildBadge('${template.sections.expand((s) => s.items).length} Items'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  Future<void> _confirmDelete(Template template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete ${template.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await Provider.of<TemplateService>(context, listen: false).deleteTemplate(template.id);
        _refreshTemplates();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template deleted')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _cloneTemplate(Template template) async {
    try {
      final service = Provider.of<TemplateService>(context, listen: false);
      final clonedData = {
        'name': '\${template.name} (Copy)',
        'description': template.description ?? '',
        'sections': template.sections.map((s) => s.toJson()).toList(),
      };
      await service.createTemplate(clonedData);
      _refreshTemplates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template cloned successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to clone template')));
      }
    }
  }
}
