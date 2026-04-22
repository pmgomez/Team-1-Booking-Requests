import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../services/admin_service.dart';
import '../utils/role_helpers.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isSelectionMode = false;
  Set<int> _selectedUserIds = {};
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final currentUserRole = authProvider.currentUser?.role ?? Roles.parishioner;

    if (token == null) return;

    setState(() => _isLoading = true);

    final response = await _adminService.getAllUsers(token);

    if (response.success && response.data != null) {
      setState(() {
        // Filter users based on current user's role
        _users = (response.data!['users'] ?? []).where((user) {
          return Roles.canViewUser(currentUserRole, user['role'] ?? Roles.parishioner);
        }).toList();
        _applySearchFilter();
        _isLoading = false;
      });
    } else if (response.mustChangePassword) {
      // Redirect to change password screen
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/change-password',
          (route) => route.isFirst,
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to load users')),
        );
      }
    }
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = List.from(_users);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredUsers = _users.where((user) {
        final firstName = (user['firstName'] ?? '').toLowerCase();
        final lastName = (user['lastName'] ?? '').toLowerCase();
        final email = (user['email'] ?? '').toLowerCase();
        final role = Roles.getRoleDisplayName(user['role'] ?? 'parishioner').toLowerCase();
        return firstName.contains(query) ||
            lastName.contains(query) ||
            email.contains(query) ||
            role.contains(query);
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

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedUserIds.clear();
    });
  }

  void _toggleUserSelection(int userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }

      // Exit selection mode if no users selected
      if (_selectedUserIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _showEditUserDialog(dynamic user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserRole = authProvider.currentUser?.role ?? Roles.parishioner;

    final firstNameController = TextEditingController(text: user['firstName'] ?? '');
    final lastNameController = TextEditingController(text: user['lastName'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');
    final phoneController = TextEditingController(text: user['phone'] ?? '');
    String selectedRole = user['role'] ?? Roles.parishioner;
    int? selectedParishId = user['assignedParishId'];
    bool isActive = user['isActive'] ?? true;
    final formKey = GlobalKey<FormState>();

    // Filter roles based on current user's role using helper
    final availableRoles = Roles.getAvailableRolesForUserManagement(currentUserRole);
    
    // Check if parish selection should be shown (not for diocese-level roles)
    bool showParishSelection = Roles.shouldShowParishSelection(selectedRole);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit User'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: false, // Email cannot be changed
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    items: availableRoles
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(Roles.getRoleDisplayName(role)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRole = value ?? Roles.parishioner;
                        // Update parish selection visibility based on role
                        showParishSelection = Roles.shouldShowParishSelection(selectedRole);
                        // Clear parish selection if switching to diocese-level role
                        if (!showParishSelection) {
                          selectedParishId = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Parish selection - only show for non-diocese roles
                  if (showParishSelection)
                    Consumer<ParishProvider>(
                      builder: (context, parishProvider, _) {
                        if (parishProvider.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        // Filter parishes based on current user's role
                        List<dynamic> availableParishes = parishProvider.parishes;
                        final currentUser = authProvider.currentUser;
                        
                        // If current user is parish-level, only show their assigned parish
                        if (currentUser != null && 
                            Roles.isParishLevel(currentUser.role) && 
                            currentUser.effectiveParishId != null) {
                          final currentUserParish = parishProvider.parishes
                              .where((parish) => parish.id == currentUser.effectiveParishId)
                              .firstOrNull;
                          
                          if (currentUserParish != null) {
                            availableParishes = [currentUserParish];
                            // Auto-select the parish if not already selected
                            if (selectedParishId == null) {
                              selectedParishId = currentUserParish.id;
                            }
                          }
                        }
                        
                        return DropdownButtonFormField<int>(
                          value: selectedParishId,
                          decoration: const InputDecoration(
                            labelText: 'Assigned Parish',
                            hintText: 'Select assigned parish',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.church),
                          ),
                          items: availableParishes
                              .map((parish) => DropdownMenuItem<int>(
                                    value: parish.id as int,
                                    child: Text(parish.name),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedParishId = value;
                            });
                          },
                        );
                      },
                    ),
                  if (!showParishSelection)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Diocese-level roles do not belong to a specific parish.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
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

                  final response = await _adminService.updateUser(
                    token,
                    user['id'],
                    {
                      'firstName': firstNameController.text,
                      'lastName': lastNameController.text,
                      'phone': phoneController.text.isEmpty ? null : phoneController.text,
                      'role': selectedRole,
                      'assignedParishId': showParishSelection ? selectedParishId : null,
                      'isActive': isActive,
                    },
                  );

                  if (response.success) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User updated successfully')),
                      );
                      _loadUsers();
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(response.message ?? 'Failed to update user')),
                      );
                    }
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSelectedUsers() async {
    if (_selectedUserIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Users'),
        content: Text('Are you sure you want to delete ${_selectedUserIds.length} user(s)? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    // Track deletion results
    int successCount = 0;
    int failCount = 0;
    List<String> errors = [];

    for (final userId in _selectedUserIds) {
      try {
        final response = await _adminService.deleteUser(token, userId);

        if (response.success) {
          successCount++;
        } else {
          failCount++;
          errors.add(response.message ?? 'Failed to delete user $userId');
        }
      } catch (e) {
        failCount++;
        errors.add('Error deleting user $userId: $e');
      }
    }

    if (mounted) {
      setState(() {
        _selectedUserIds.clear();
        _isSelectionMode = false;
      });

      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully deleted $successCount user(s)')),
        );
      }

      if (failCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete $failCount user(s): ${errors.first}')),
        );
      }

      _loadUsers();
    }
  }

  void _showAddUserDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserRole = authProvider.currentUser?.role ?? Roles.parishioner;

    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = Roles.parishioner;
    int? selectedParishId;
    final formKey = GlobalKey<FormState>();

    // Filter roles based on current user's role using helper
    final availableRoles = Roles.getAvailableRolesForUserManagement(currentUserRole);
    
    // Check if parish selection should be shown (not for diocese-level roles)
    bool showParishSelection = Roles.shouldShowParishSelection(selectedRole);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  // Password field removed - system generates random password
                  const Text(
                    'A random password will be generated and sent via email.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    items: availableRoles
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(Roles.getRoleDisplayName(role)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRole = value ?? Roles.parishioner;
                        // Update parish selection visibility based on role
                        showParishSelection = Roles.shouldShowParishSelection(selectedRole);
                        // Clear parish selection if switching to diocese-level role
                        if (!showParishSelection) {
                          selectedParishId = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Parish selection - only show for non-diocese roles
                  if (showParishSelection)
                    Consumer<ParishProvider>(
                      builder: (context, parishProvider, _) {
                        if (parishProvider.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        // Filter parishes based on current user's role
                        List<dynamic> availableParishes = parishProvider.parishes;
                        final currentUser = authProvider.currentUser;
                        
                        // If current user is parish-level, only show their assigned parish
                        if (currentUser != null && 
                            Roles.isParishLevel(currentUser.role) && 
                            currentUser.effectiveParishId != null) {
                          final currentUserParish = parishProvider.parishes
                              .where((parish) => parish.id == currentUser.effectiveParishId)
                              .firstOrNull;
                          
                          if (currentUserParish != null) {
                            availableParishes = [currentUserParish];
                            // Auto-select the parish if not already selected
                            if (selectedParishId == null) {
                              selectedParishId = currentUserParish.id;
                            }
                          }
                        }
                        
                        return DropdownButtonFormField<int>(
                          value: selectedParishId,
                          decoration: const InputDecoration(
                            labelText: 'Assigned Parish',
                            hintText: 'Select assigned parish',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.church),
                          ),
                          items: availableParishes
                              .map((parish) => DropdownMenuItem<int>(
                                    value: parish.id as int,
                                    child: Text(parish.name),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedParishId = value;
                            });
                          },
                        );
                      },
                    ),
                  if (!showParishSelection)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Diocese-level roles do not belong to a specific parish.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
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

                  final response = await _adminService.createUser(
                    token,
                    {
                      'firstName': firstNameController.text,
                      'lastName': lastNameController.text,
                      'email': emailController.text,
                      'role': selectedRole,
                      'assignedParishId': showParishSelection ? selectedParishId : null,
                    },
                  );

                  if (response.success) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User created successfully. Login credentials sent via email.')),
                      );
                      _loadUsers();
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(response.message ?? 'Failed to create user')),
                      );
                    }
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'diocese_admin':
        return Colors.purple;
      case 'diocese_staff':
        return Colors.blue;
      case 'parish_admin':
        return Colors.orange;
      case 'parish_staff':
        return Colors.teal;
      case 'priest':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedUserIds.length} selected')
            : const Text('Manage Users'),
        leading: IconButton(
          icon: Icon(_isSelectionMode ? Icons.close : Icons.arrow_back),
          onPressed: _isSelectionMode ? _toggleSelectionMode : () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Select users',
              onPressed: _toggleSelectionMode,
            ),
          if (_isSelectionMode && _selectedUserIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete selected users',
              onPressed: _deleteSelectedUsers,
            ),
        ],
        bottom: !_isSelectionMode
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users by name, email, or role...',
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
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No users found matching "$_searchQuery"'
                            : 'No users found',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final userId = user['id'] ?? 0;
                      final isSelected = _selectedUserIds.contains(userId);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isSelected ? Colors.blue.shade50 : null,
                        child: ListTile(
                          onTap: () {
                            if (_isSelectionMode) {
                              _toggleUserSelection(userId);
                            } else {
                              _showEditUserDialog(user);
                            }
                          },
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              _toggleSelectionMode();
                              _toggleUserSelection(userId);
                            }
                          },
                          leading: CircleAvatar(
                            backgroundColor: _getRoleColor(user['role'] ?? 'parishioner'),
                            child: Text(
                              (user['firstName'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(user['email'] ?? ''),
                              Text(
                                'Role: ${Roles.getRoleDisplayName(user['role'] ?? 'parishioner')}',
                                style: TextStyle(
                                  color: _getRoleColor(user['role'] ?? 'parishioner'),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          trailing: _isSelectionMode
                              ? Icon(
                                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: isSelected ? Colors.blue : Colors.grey,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
    );
  }
}
