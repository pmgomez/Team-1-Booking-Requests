import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../utils/role_helpers.dart';
import '../services/user_booking_service.dart';
import '../utils/sacrament_icons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, String>> services = const [
    {
      "title": "Baptism",
      "desc": "Book a baptism ceremony for your child",
      "route": "/baptism-booking",
    },
    {
      "title": "Wedding",
      "desc": "Schedule your sacred matrimony ceremony",
      "route": "/wedding-booking",
    },
    {
      "title": "Confirmation",
      "desc": "Book confirmation for strengthening faith",
      "route": "/confirmation-booking",
    },
    {
      "title": "Eucharist (First Communion)",
      "desc": "Schedule first holy communion ceremony",
      "route": "/eucharist",
    },
    {
      "title": "Reconciliation (Confession)",
      "desc": "Book a time for confession",
      "route": "/reconciliation",
    },
    {
      "title": "Anointing the Sick",
      "desc": "Request anointing for the sick",
      "route": "/anointing-the-sick",
    },
    {
      "title": "Mass Intentions",
      "desc": "Submit a mass intention request",
      "route": "/mass-intention",
    },
    {
      "title": "Funeral Mass",
      "desc": "Arrange a funeral mass service",
      "route": "/funeral-mass",
    },
  ];

  bool _isLoadingStats = true;
  Map<String, int> _bookingStats = {};
  int _totalBookings = 0;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.currentUser?.role ?? Roles.parishioner;
    if (!Roles.isAdmin(userRole) && !Roles.isPriest(userRole)) {
      _loadBookingStats();
    } else {
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadBookingStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
      return;
    }
    try {
      final response = await UserBookingService().getUserBookings(
        token: token,
        limit: 1000,
      );
      if (mounted) {
        if (response.success && response.data != null) {
          final bookings = response.data as List;
          Map<String, int> stats = {
            'total': bookings.length,
            'pending': 0,
            'approved': 0,
            'declined': 0,
            'completed': 0,
          };
          for (var booking in bookings) {
            final status = (booking['status'] ?? 'pending').toString().toLowerCase();
            if (stats.containsKey(status)) {
              stats[status] = stats[status]! + 1;
            } else {
              stats[status] = 1;
            }
          }
          setState(() {
            _bookingStats = stats;
            _totalBookings = bookings.length;
            _isLoadingStats = false;
          });
        } else {
          setState(() => _isLoadingStats = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.currentUser?.role ?? Roles.parishioner;
    final isAdmin = Roles.isAdmin(userRole);
    final isDioceseLevel = Roles.isDioceseLevel(userRole);
    final isPriest = Roles.isPriest(userRole);

    // Show password change modal if required and user is not a parishioner
    if (authProvider.mustChangePassword &&
        userRole != Roles.parishioner &&
        context.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPasswordChangeModal(context);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("RCDOK Booking System"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    authProvider.currentUser?.fullName ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '${authProvider.currentUser?.email ?? ''}\n${Roles.getRoleDisplayName(userRole)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                  ),
                  // Show parish info for non-diocese users
                  if (authProvider.currentUser?.effectiveParishId != null && !isDioceseLevel)
                    Consumer<ParishProvider>(
                      builder: (context, parishProvider, _) {
                        final parish = parishProvider.parishes
                            .where((p) => p.id == authProvider.currentUser?.effectiveParishId)
                            .firstOrNull;
                        if (parish != null) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Parish: ${parish.name}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            // Parishioner Menu Items
            if (!isAdmin && !isPriest) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'MY ACCOUNT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('My Bookings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/my-bookings');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('My Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/my-profile');
                },
              ),
            ],
            // Priest Menu Items
            if (isPriest) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'MY SCHEDULE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('My Schedule'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/priest-schedule');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('My Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/my-profile');
                },
              ),
            ],
            // Admin/Staff Menu Items
            if (isAdmin) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'ADMINISTRATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin-dashboard');
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Manage Bookings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin-bookings');
                },
              ),
              if (isDioceseLevel)
                ListTile(
                  leading: const Icon(Icons.church),
                  title: const Text('Manage Parishes'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin-parishes');
                  },
                ),
              if (isDioceseLevel || isAdmin)
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Manage Users'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin-users');
                  },
                ),
              // ListTile(
              //   leading: const Icon(Icons.description),
              //   title: const Text('Sacramental Records'),
              //   onTap: () {
              //     Navigator.pop(context);
              //     Navigator.pushNamed(context, '/admin-records');
              //   },
              // ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          const Text(
            "Welcome to the Roman Catholic Diocese of Kalookan Booking System",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            isAdmin
                ? 'Manage sacraments, bookings, and parish operations across ${isDioceseLevel ? 'all parishes' : 'your parish'}.'
                  '\nSelect a service below to begin.'
                : isPriest
                    ? 'View your schedule of assigned sacraments and bookings.'
                      '\nClick below to see your monthly schedule.'
                    : 'Book sacraments and mass intentions across all parishes in the diocese.'
                      '\nSelect a service below to begin your booking request.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),

          // Admin Quick Actions
          if (isAdmin) ...[
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/admin-dashboard');
                          },
                          icon: const Icon(Icons.dashboard, size: 20),
                          label: const Text('Dashboard'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/admin-bookings');
                          },
                          icon: const Icon(Icons.calendar_today, size: 20),
                          label: const Text('Bookings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        if (isDioceseLevel)
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/admin-parishes');
                            },
                            icon: const Icon(Icons.church, size: 20),
                            label: const Text('Parishes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        if (isDioceseLevel || isAdmin)
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/admin-users');
                            },
                            icon: const Icon(Icons.people, size: 20),
                            label: const Text('Users'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/admin-mass-intentions');
                          },
                          icon: const Icon(Icons.book, size: 20),
                          label: const Text('Mass Intentions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/admin-mass-schedule');
                          },
                          icon: const Icon(Icons.schedule, size: 20),
                          label: const Text('Mass Schedule'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Parishioner Quick Actions
          if (!isAdmin && !isPriest) ...[
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/my-bookings');
                          },
                          icon: const Icon(Icons.list_alt, size: 20),
                          label: const Text('My Bookings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/my-profile');
                          },
                          icon: const Icon(Icons.person, size: 20),
                          label: const Text('My Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Booking Statistics Section
            _isLoadingStats
                ? const Center(child: CircularProgressIndicator())
                : _totalBookings > 0
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Bookings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.3,
                            ),
                            itemCount: _bookingStats.entries.where((e) => e.key != 'total' && e.value > 0).length,
                            itemBuilder: (context, index) {
                              final entries = _bookingStats.entries.where((e) => e.key != 'total' && e.value > 0).toList();
                              if (index >= entries.length) return const SizedBox.shrink();
                              final entry = entries[index];
                              final status = entry.key;
                              final count = entry.value;
                              Color color;
                              IconData icon;
                              switch (status) {
                                case 'pending':
                                  color = Colors.orange;
                                  icon = Icons.pending_actions;
                                  break;
                                case 'approved':
                                  color = Colors.green;
                                  icon = Icons.check_circle;
                                  break;
                                case 'declined':
                                  color = Colors.red;
                                  icon = Icons.cancel;
                                  break;
                                case 'completed':
                                  color = Colors.blue;
                                  icon = Icons.done_all;
                                  break;
                                default:
                                  color = Colors.grey;
                                  icon = Icons.info;
                              }
                              return _buildStatCard(
                                title: _capitalize(status),
                                value: count.toString(),
                                icon: icon,
                                color: color,
                              );
                            },
                          ),
                        ],
                      )
                    : const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('You have no bookings yet.'),
                        ),
                      ),
            const SizedBox(height: 24),
          ],

          // Priest Schedule Section
          if (isPriest) ...[
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month, color: Colors.purple.shade700, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'My Schedule',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'View your monthly schedule of sacraments and bookings.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/priest-schedule');
                        },
                        icon: const Icon(Icons.calendar_today, size: 20),
                        label: const Text('View Schedule'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Services Grid (hidden for priest)
          if (!isPriest) ...[
            const Text(
              'Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemBuilder: (context, index) {
                final service = services[index];
                return InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, service["route"]!);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getSacramentIcon(_getServiceSacramentType(service["title"]!)),
                          size: 32,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(height: 6),
                        Flexible(
                          child: Text(
                            service["title"]!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Flexible(
                          child: Text(
                            service["desc"]!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showPasswordChangeModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Password Change Required'),
        content: const Text(
          'You must change your password before continuing. Please update your password now.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/profile');
            },
            child: const Text('Change Password'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Later'),
          ),
        ],
      ),
    );
  }

  String _getServiceSacramentType(String title) {
    switch (title) {
      case 'Baptism':
        return 'baptism';
      case 'Wedding':
        return 'wedding';
      case 'Confirmation':
        return 'confirmation';
      case 'Eucharist (First Communion)':
        return 'eucharist';
      case 'Reconciliation (Confession)':
        return 'reconciliation';
      case 'Anointing the Sick':
        return 'anointing_sick';
      case 'Mass Intentions':
        return 'mass_intention';
      case 'Funeral Mass':
        return 'funeral_mass';
      default:
        return '';
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
