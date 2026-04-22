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
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _parishes = [];
  List<dynamic> _filteredParishes = [];
  String _searchQuery = '';

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
        _applySearchFilter();
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

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredParishes = List.from(_parishes);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredParishes = _parishes.where((parish) {
        final name = (parish['name'] ?? '').toLowerCase();
        final address = (parish['address'] ?? '').toLowerCase();
        final email = (parish['contactEmail'] ?? '').toLowerCase();
        return name.contains(query) ||
            address.contains(query) ||
            email.contains(query);
      }).toList();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applySearchFilter();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  void _showAddParishDialog() {
    _showParishDialog(null);
  }

  void _showEditParishDialog(dynamic parish) {
    _showParishDialog(parish);
  }

  void _showParishDialog(dynamic parish) {
    final nameController = TextEditingController(text: parish?['name'] ?? '');
    final addressController = TextEditingController(text: parish?['address'] ?? '');
    final emailController = TextEditingController(text: parish?['contactEmail'] ?? '');
    final phoneController = TextEditingController(text: parish?['contactPhone'] ?? '');
    bool isActive = parish?['isActive'] ?? true;
    final formKey = GlobalKey<FormState>();
    final isEditing = parish != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Parish' : 'Add New Parish'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
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
                    if (isEditing) ...[
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Active'),
                        value: isActive,
                        onChanged: (value) {
                          setDialogState(() {
                            isActive = value;
                          });
                        },
                      ),
                    ],
                  ],
                ),
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

                  final response = isEditing
                      ? await _adminService.updateParish(
                          token,
                          parish['id'],
                          {
                            'name': nameController.text,
                            'address': addressController.text,
                            'contactEmail': emailController.text.isEmpty ? null : emailController.text,
                            'contactPhone': phoneController.text.isEmpty ? null : phoneController.text,
                            'isActive': isActive,
                          },
                        )
                      : await _adminService.createParish(
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
                        SnackBar(content: Text(isEditing ? 'Parish updated successfully' : 'Parish created successfully')),
                      );
                      _loadParishes();
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(response.message ?? (isEditing ? 'Failed to update parish' : 'Failed to create parish'))),
                      );
                    }
                  }
                }
              },
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search parishes by name, address, or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredParishes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.church_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No parishes found matching "$_searchQuery"'
                            : 'No parishes found',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadParishes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredParishes.length,
                    itemBuilder: (context, index) {
                      final parish = _filteredParishes[index];
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
                            _showEditParishDialog(parish);
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
