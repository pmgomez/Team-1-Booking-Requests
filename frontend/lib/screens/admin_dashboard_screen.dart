import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../utils/role_helpers.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() => _isLoading = true);

    final response = await _adminService.getDashboardStats(token);

    if (response.success && response.data != null) {
      setState(() {
        _stats = response.data!;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to load dashboard')),
        );
      }
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.currentUser?.role ?? Roles.parishioner;
    final isDioceseLevel = Roles.isDioceseLevel(userRole);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isDioceseLevel
                        ? 'Diocese-wide statistics'
                        : 'Parish statistics',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _buildStatCard(
                        title: 'Total Bookings',
                        value: _stats['totalBookings']?.toString() ?? '0',
                        icon: Icons.calendar_today,
                        color: Colors.blue,
                      ),
                      _buildStatCard(
                        title: 'Pending',
                        value: _stats['pendingBookings']?.toString() ?? '0',
                        icon: Icons.pending,
                        color: Colors.orange,
                      ),
                      _buildStatCard(
                        title: 'Approved',
                        value: _stats['approvedBookings']?.toString() ?? '0',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      _buildStatCard(
                        title: 'Parishes',
                        value: _stats['totalParishes']?.toString() ?? '0',
                        icon: Icons.church,
                        color: Colors.purple,
                      ),
                      if (isDioceseLevel)
                        _buildStatCard(
                          title: 'Total Users',
                          value: _stats['totalUsers']?.toString() ?? '0',
                          icon: Icons.people,
                          color: Colors.teal,
                        ),
                      _buildStatCard(
                        title: 'This Month',
                        value: _stats['thisMonthBookings']?.toString() ?? '0',
                        icon: Icons.today,
                        color: Colors.indigo,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.calendar_today, color: Colors.blue),
                          title: const Text('Manage Bookings'),
                          subtitle: const Text('Review and approve pending bookings'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pushNamed(context, '/admin-bookings');
                          },
                        ),
                        const Divider(height: 1),
                        if (isDioceseLevel)
                          ListTile(
                            leading: const Icon(Icons.church, color: Colors.purple),
                            title: const Text('Manage Parishes'),
                            subtitle: const Text('Add or edit parish information'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pushNamed(context, '/admin-parishes');
                            },
                          ),
                        if (isDioceseLevel) ...[
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.people, color: Colors.teal),
                            title: const Text('Manage Users'),
                            subtitle: const Text('Create and manage user accounts'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pushNamed(context, '/admin-users');
                            },
                          ),
                        ],
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.description, color: Colors.indigo),
                          title: const Text('Sacramental Records'),
                          subtitle: const Text('View and manage sacramental records'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pushNamed(context, '/admin-records');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
