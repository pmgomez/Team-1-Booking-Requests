import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_booking_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final UserBookingService _bookingService = UserBookingService();
  List<dynamic> _bookings = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication required';
      });
      return;
    }

    final result = await _bookingService.getUserBookings(token: token);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.data != null) {
          _bookings = result.data!;
        } else {
          _errorMessage = result.message ?? 'Failed to load bookings';
        }
      });
    }
  }

  String? _getDetailRouteForSacrament(String sacramentType) {
    // Map sacrament types to their detail routes
    switch (sacramentType) {
      case 'baptism':
        return '/baptism-detail';
      case 'confirmation':
        return '/confirmation-detail';
      case 'anointing_sick':
        return '/anointing-sick-detail';
      case 'funeral_mass':
        return '/funeral-mass-detail';
      case 'reconciliation':
        return '/reconciliation-detail';
      case 'wedding':
        return '/wedding-detail';
      case 'eucharist':
        return '/eucharist-detail';
      default:
        return null;
    }
  }

  Future<void> _navigateToBookingDetails(int id, String sacramentType) async {
    final route = _getDetailRouteForSacrament(sacramentType);
    if (route == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viewing/editing this sacrament is not yet supported. Please contact the parish office.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final result = await Navigator.pushNamed(
      context,
      route,
      arguments: {
        'id': id,
        'fromStatusButton': true,
      },
    );
    if (result == true) {
      _loadBookings();
    }
  }

  Future<void> _viewBookingDetails(int id, String sacramentType) async {
    final route = _getDetailRouteForSacrament(sacramentType);
    if (route == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viewing this sacrament is not yet supported. Please contact the parish office.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final result = await Navigator.pushNamed(
      context,
      route,
      arguments: {
        'id': id,
        'fromStatusButton': false,
      },
    );
    if (result == true) {
      _loadBookings();
    }
  }

  Future<void> _deleteBooking(int bookingId, String sacramentType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Booking'),
        content: const Text('Are you sure you want to delete this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() => _isLoading = true);

    final result = await _bookingService.deleteUserBooking(token: token, id: bookingId);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking deleted successfully')),
        );
        _loadBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to delete booking')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getSacramentDisplayName(String sacramentType) {
    switch (sacramentType) {
      case 'baptism':
        return 'Baptism';
      case 'wedding':
        return 'Wedding';
      case 'confirmation':
        return 'Confirmation';
      case 'eucharist':
        return 'First Communion';
      case 'reconciliation':
        return 'Reconciliation';
      case 'anointing_sick':
        return 'Anointing the Sick';
      case 'funeral_mass':
        return 'Funeral Mass';
      default:
        return sacramentType.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.currentUser?.role ?? 'parishioner';
    final isAdmin = ['parish_admin', 'parish_staff', 'diocese_admin', 'diocese_staff'].contains(userRole);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBookings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _bookings.isEmpty
                  ? const Center(
                      child: Text(
                        'No bookings found.\nStart by booking a sacrament!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBookings,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final booking = _bookings[index];
                          final id = booking['id'];
                          final sacramentType = booking['sacramentType'] ?? 'unknown';
                          var status = booking['status']?.toLowerCase() ?? 'pending';
                          // Determine the appropriate date field based on sacrament type
                          final dateField = sacramentType == 'mass_intention' ? 'massSchedule' : 'preferredDate';
                          final scheduledDate = booking[dateField];
                          // Compute effective status: if approved but date has passed, treat as completed
                          if (status == 'approved' && scheduledDate != null) {
                            try {
                              final now = DateTime.now();
                              final bookingDate = DateTime.parse(scheduledDate);
                              final today = DateTime(now.year, now.month, now.day);
                              final eventDate = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
                              if (eventDate.isBefore(today)) {
                                status = 'completed';
                              }
                            } catch (e) {
                              // ignore, keep as approved
                            }
                          }
                          // Determine edit and delete permissions based on effective status
                          final canEdit = status == 'pending' || status == 'declined';
                          final canDelete = status != 'approved'; // pending, declined, completed can delete
                          final hasEditSupport = _getDetailRouteForSacrament(sacramentType) != null;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _getSacramentDisplayName(sacramentType),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: _getStatusColor(status)),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _getStatusColor(status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (booking['preferredDate'] != null)
                                    Text('Date: ${booking['preferredDate']}'),
                                  if (booking['preferredTimeSlot'] != null)
                                    Text('Time: ${booking['preferredTimeSlot']}'),
                                  if (booking['parishName'] != null)
                                    Text('Parish: ${booking['parishName']}'),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Edit button for editable bookings
                                      if (canEdit && hasEditSupport)
                                        ElevatedButton.icon(
                                          onPressed: () => _navigateToBookingDetails(id, sacramentType),
                                          icon: const Icon(Icons.edit, size: 16),
                                          label: const Text('Edit'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      // View button for non-editable bookings that have detail support
                                      if (!canEdit && hasEditSupport)
                                        ElevatedButton.icon(
                                          onPressed: () => _viewBookingDetails(id, sacramentType),
                                          icon: const Icon(Icons.visibility, size: 16),
                                          label: const Text('View'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey,
                                          ),
                                        ),
                                      // Spacing before delete if we have a preceding button (edit or view) and delete is present
                                      if (hasEditSupport && canDelete) const SizedBox(width: 8),
                                      // Delete button for deletable bookings
                                      if (canDelete)
                                        ElevatedButton.icon(
                                          onPressed: () => _deleteBooking(id, sacramentType),
                                          icon: const Icon(Icons.delete, size: 16),
                                          label: const Text('Delete'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      // Fallback message if no actions available
                                      if (!canEdit && !canDelete && !hasEditSupport)
                                        const Text(
                                          'No actions available',
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
