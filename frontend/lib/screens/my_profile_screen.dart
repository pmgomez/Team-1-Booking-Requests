import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/text_field.dart';
import '../utils/validators.dart';
import '../utils/role_helpers.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      setState(() {
        _firstNameController.text = user.firstName;
        _lastNameController.text = user.lastName;
        _phoneController.text = user.phone ?? '';
        _isInitialized = true;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          setState(() {
            _errorMessage = authProvider.errorMessage ?? 'Failed to update profile';
          });
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final userRole = user?.role ?? Roles.parishioner;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isInitialized
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // User Info Card (Read-only)
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, size: 60, color: Theme.of(context).primaryColor),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${user?.firstName} ${user?.lastName}',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user?.email ?? '',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        Roles.getRoleDisplayName(userRole),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).primaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (user?.assignedParishId != null) ...[
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.church, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Consumer<ParishProvider>(
                                      builder: (context, parishProvider, _) {
                                        final parish = parishProvider.parishes
                                            .where((p) => p.id == user?.assignedParishId)
                                            .firstOrNull;
                                        return Text(
                                          'Parish: ${parish?.name ?? "N/A"}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Editable Profile Fields
                    Text(
                      'Edit Profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _firstNameController,
                            labelText: 'First Name',
                            hintText: 'Enter first name',
                            validator: Validators.requiredField,
                            prefixIcon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _lastNameController,
                            labelText: 'Last Name',
                            hintText: 'Enter last name',
                            validator: Validators.requiredField,
                            prefixIcon: Icons.person_outline,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      hintText: 'Enter phone number',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                    ),

                    const SizedBox(height: 30),

                    CustomButton(
                      text: 'Save Changes',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _saveProfile,
                    ),

                    const SizedBox(height: 20),

                    // Change Password Section
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.lock, color: Theme.of(context).primaryColor),
                        title: const Text('Change Password'),
                        subtitle: const Text('Update your account password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/profile',
                          );
                          if (result == true && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password changed successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
