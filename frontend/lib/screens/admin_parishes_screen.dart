import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';

class AdminParishesScreen extends StatefulWidget {
  const AdminParishesScreen({super.key});

  @override
  State<AdminParishesScreen> createState() => _AdminParishesScreenState();
}

class _AdminParishesScreenState extends State<AdminParishesScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<dynamic> _parishes = [];

  @override
  void initState() {
    super.initState();
    _loadParishes();
  }

  Future<void> _loadParishes() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() => _isLoading = true);

    final response = await _adminService.getAllParishes(token);

    if (response.success && response.data != null) {
      setState(() {
        _parishes = response.data!['parishes'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to load parishes')),
        );
      }
    }
  }

  void _showAddParishDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Parish'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Parish Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final token = authProvider.token;

                if (token == null) return;

                final response = await _adminService.createParish(
                  token,
                  {
                    'name': nameController.text,
                    'address': addressController.text,
                    'contactEmail': emailController.text.isEmpty ? null : emailController.text,
                    'contactPhone': phoneController.text.isEmpty ? null : phoneController.text,
                    'isActive': true,
                  },
                );

                if (response.success) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Parish created successfully')),
                    );
                    _loadParishes();
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(response.message ?? 'Failed to create parish')),
                    );
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Parishes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _parishes.isEmpty
              ? const Center(child: Text('No parishes found'))
              : RefreshIndicator(
                  onRefresh: _loadParishes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _parishes.length,
                    itemBuilder: (context, index) {
                      final parish = _parishes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: parish['isActive'] == true
                                ? Colors.green
                                : Colors.grey,
                            child: const Icon(Icons.church, color: Colors.white),
                          ),
                          title: Text(
                            parish['name'] ?? 'Unknown Parish',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(parish['address'] ?? 'No address'),
                              if (parish['contactEmail'] != null)
                                Text('📧 ${parish['contactEmail']}'),
                              if (parish['contactPhone'] != null)
                                Text('📞 ${parish['contactPhone']}'),
                            ],
                          ),
                          trailing: parish['isActive'] == true
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.cancel, color: Colors.grey),
                          onTap: () {
                            // TODO: Show parish details/edit dialog
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddParishDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Parish'),
      ),
    );
  }
}
