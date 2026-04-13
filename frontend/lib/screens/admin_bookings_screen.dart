import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../utils/role_helpers.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  String _selectedStatus = 'all';
  String _selectedType = 'all';

  final List<Map<String, String>> _statusOptions = [
    {'value': 'all', 'label': 'All Statuses'},
    {'value': 'pending', 'label': 'Pending'},
    {'value': 'approved', 'label': 'Approved'},
    {'value': 'declined', 'label': 'Declined'},
    {'value': 'completed', 'label': 'Completed'},
  ];

  final List<Map<String, String>> _typeOptions = [
    {'value': 'all', 'label': 'All Types'},
    {'value': 'baptism', 'label': 'Baptism'},
    {'value': 'wedding', 'label': 'Wedding'},
    {'value': 'confirmation', 'label': 'Confirmation'},
    {'value': 'eucharist', 'label': 'Eucharist'},
    {'value': 'reconciliation', 'label': 'Reconciliation'},
    {'value': 'anointing_sick', 'label': 'Anointing Sick'},
    {'value': 'funeral_mass', 'label': 'Funeral Mass'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() => _isLoading = true);

    final response = await _adminService.getAllBookings(
      token,
      sacramentType: _selectedType == 'all' ? null : _selectedType,
      status: _selectedStatus == 'all' ? null : _selectedStatus,
    );

    if (response.success && response.data != null) {
      setState(() {
        _bookings = response.data!['bookings'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to load bookings')),
        );
      }
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    final response = await _adminService.updateBookingStatus(
      token,
      bookingId,
      status,
    );

    if (response.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking $status successfully')),
        );
        _loadBookings();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to update booking')),
        );
      }
    }
  }

  void _showBookingDetails(dynamic booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Booking Details',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                _buildDetailRow('ID', '#${booking['id']}'),
                _buildDetailRow(
                  'Type',
                  (booking['bookingType'] ?? booking['sacramentType'] ?? 'N/A').toString().replaceAll('_', ' ').toUpperCase(),
                ),
                _buildDetailRow(
                  'Status',
                  booking['status']?.toString().toUpperCase() ?? 'N/A',
                ),
                _buildDetailRow('Name', booking['childFullName'] ?? booking['deceasedFullName'] ?? booking['coupleNames'] ?? booking['fullName'] ?? 'N/A'),
                _buildDetailRow(
                  'Date',
                  booking['preferredDate']?.toString().substring(0, 10) ?? 'N/A',
                ),
                _buildDetailRow('Email', booking['contactEmail'] ?? 'N/A'),
                _buildDetailRow('Phone', booking['contactPhone'] ?? 'N/A'),
                if (booking['preferredPriest'] != null)
                  _buildDetailRow('Priest', booking['preferredPriest']),
                if (booking['adminNotes'] != null)
                  _buildDetailRow('Admin Notes', booking['adminNotes']),
                const SizedBox(height: 24),
                if (booking['status'] == 'pending') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _updateBookingStatus(booking['id'].toString(), 'approved');
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _updateBookingStatus(booking['id'].toString(), 'declined');
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Decline'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'declined':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bookings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _statusOptions
                        .map((option) => DropdownMenuItem(
                              value: option['value'],
                              child: Text(option['label']!),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedStatus = value ?? 'all');
                      _loadBookings();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _typeOptions
                        .map((option) => DropdownMenuItem(
                              value: option['value'],
                              child: Text(option['label']!),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedType = value ?? 'all');
                      _loadBookings();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Bookings List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _bookings.isEmpty
                    ? const Center(child: Text('No bookings found'))
                    : RefreshIndicator(
                        onRefresh: _loadBookings,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _bookings.length,
                          itemBuilder: (context, index) {
                            final booking = _bookings[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: () => _showBookingDetails(booking),
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(
                                    booking['status'] ?? 'pending',
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  booking['childFullName'] ??
                                      booking['deceasedFullName'] ??
                                      booking['coupleNames'] ??
                                      booking['fullName'] ??
                                      'Booking #${booking['id']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      (booking['bookingType'] ?? booking['sacramentType'] ?? 'booking')
                                          .toString()
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                    ),
                                    Text(
                                      booking['preferredDate']?.toString().substring(0, 10) ??
                                          'No date set',
                                    ),
                                  ],
                                ),
                                trailing: Chip(
                                  label: Text(
                                    booking['status']?.toString().toUpperCase() ?? 'PENDING',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: _getStatusColor(
                                    booking['status'] ?? 'pending',
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
