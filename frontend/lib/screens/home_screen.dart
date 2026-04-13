import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/role_helpers.dart';

// Home Screen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.currentUser?.role ?? Roles.parishioner;
    final isAdmin = Roles.isAdmin(userRole);
    final isDioceseLevel = Roles.isDioceseLevel(userRole);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Diocese Booking System"),
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
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
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
              if (isDioceseLevel)
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Manage Users'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/admin-users');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Sacramental Records'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin-records');
                },
              ),
            ],
            const Divider(),
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
            "Welcome to Diocese Booking System",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            isAdmin
                ? 'Manage sacraments, bookings, and parish operations across ${isDioceseLevel ? 'all parishes' : 'your parish'}.\nSelect a service below to begin.'
                : 'Book sacraments and mass intentions across all parishes in the diocese.\nSelect a service below to begin your booking request.',
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
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
                        Icons.church,
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
      ),
    );
  }
}
