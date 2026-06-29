import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../services/admin_service.dart';
import '../config/api_config.dart';
import '../utils/role_helpers.dart';
import 'document_preview_screen.dart';
import '../models/document.dart';
import '../utils/sacrament_icons.dart';

class AdminBookingsScreen extends StatefulWidget {
  final String? initialStatus;
  final String? initialParishId;
  final String? initialDateFilter;

  const AdminBookingsScreen({
    super.key,
    this.initialStatus,
    this.initialParishId,
    this.initialDateFilter,
  });

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  String _selectedStatus = 'all';
  String _selectedType = 'all';
  String? _selectedParishId;

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
    {'value': 'mass_intention', 'label': 'Mass Intention'},
  ];

  @override
  void initState() {
    super.initState();
    // Set initial filters from navigation arguments
    if (widget.initialStatus != null) {
      _selectedStatus = widget.initialStatus!;
    }
    if (widget.initialParishId != null) {
      _selectedParishId = widget.initialParishId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ParishProvider>(context, listen: false).loadAllParishes();
    });
    _loadBookings();
  }

  /// Calculate date range for "this month" filter
  Map<String, String>? _getThisMonthDateRange() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return {
      'startDate': firstDayOfMonth.toIso8601String(),
      'endDate': lastDayOfMonth.toIso8601String(),
    };
  }

  Future<void> _loadBookings() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() => _isLoading = true);

    // Handle "this month" date filter
    String? startDate;
    String? endDate;
    if (widget.initialDateFilter == 'this_month') {
      final dateRange = _getThisMonthDateRange();
      startDate = dateRange?['startDate'];
      endDate = dateRange?['endDate'];
    }

    final response = await _adminService.getAllBookings(
      token,
      sacramentType: _selectedType == 'all' ? null : _selectedType,
      status: _selectedStatus == 'all' ? null : _selectedStatus,
      parishId: _selectedParishId,
      startDate: startDate,
      endDate: endDate,
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

  Future<void> _deleteBooking(String bookingId, {String? sacramentType}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Booking'),
        content: const Text('Are you sure you want to delete this booking? This action cannot be undone.'),
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

    final response = await _adminService.deleteBooking(token, bookingId, sacramentType: sacramentType);

    if (mounted) {
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking deleted successfully')),
        );
        _loadBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to delete booking')),
        );
      }
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    // Don't proceed if bookingId is empty
    if (bookingId.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    // Find the booking from the list to get its type
    final booking = _bookings.firstWhere(
          (b) => b['id'].toString() == bookingId,
      orElse: () => {},
    );
    
    // Return if booking not found
    if (booking.isEmpty) return;
    
    final bookingType = booking['bookingType'] ?? booking['sacramentType'];
    if (bookingType == 'baptism') {
      // Navigate to baptism detail screen for approval/completion actions
      final id = booking['id'] is String
          ? int.tryParse(booking['id'])
          : booking['id'] is int
              ? booking['id']
              : null;
      
      Navigator.pushNamed(
        context,
        '/baptism-detail',
        arguments: {'id': id, 'fromStatusButton': true},
      ).then((_) => _loadBookings());
      return;
    } else if (bookingType == 'mass_intention') {
      // Navigate to mass intention detail screen for approval/completion actions
      final id = booking['id'] is String
          ? int.tryParse(booking['id'])
          : booking['id'] is int
              ? booking['id']
              : null;

      Navigator.pushNamed(
        context,
        '/mass-intention-detail',
        arguments: {'id': id, 'fromStatusButton': true},
      ).then((_) => _loadBookings());
      return;
     } else if (bookingType == 'confirmation') {
       // Navigate to confirmation detail screen for approval/completion actions
       final id = booking['id'] is String
           ? int.tryParse(booking['id'])
           : booking['id'] is int
               ? booking['id']
               : null;

       Navigator.pushNamed(
         context,
         '/confirmation-detail',
         arguments: {'id': id, 'fromStatusButton': true},
       ).then((_) => _loadBookings());
       return;
      } else if (bookingType == 'anointing_sick') {
        // Navigate to anointing sick detail screen for approval/completion actions
        final id = booking['id'] is String
            ? int.tryParse(booking['id'])
            : booking['id'] is int
                ? booking['id']
                : null;

        Navigator.pushNamed(
          context,
          '/anointing-sick-detail',
          arguments: {'id': id, 'fromStatusButton': true},
        ).then((_) => _loadBookings());
        return;
      } else if (bookingType == 'funeral_mass') {
        // Navigate to funeral mass detail screen for approval/completion actions
        final id = booking['id'] is String
            ? int.tryParse(booking['id'])
            : booking['id'] is int
                ? booking['id']
                : null;

        Navigator.pushNamed(
          context,
          '/funeral-mass-detail',
          arguments: {'id': id, 'fromStatusButton': true},
        ).then((_) => _loadBookings());
        return;
      } else if (bookingType == 'wedding') {
        final weddingId = booking['id'] is String
            ? int.tryParse(booking['id'])
            : booking['id'] is int
                ? booking['id']
                : null;

        Navigator.pushNamed(
          context,
          '/wedding-detail',
          arguments: {'weddingId': weddingId, 'fromStatusButton': true},
        ).then((_) => _loadBookings());
        return;
      }

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
                  formatDateMMDDYYYY(
                    (booking['bookingType'] ?? booking['sacramentType']) == 'mass_intention'
                        ? booking['massSchedule']?.toString()
                        : booking['preferredDate']?.toString(),
                  ),
                ),
                _buildDetailRow('Email', booking['contactEmail'] ?? 'N/A'),
                _buildDetailRow('Phone', booking['contactPhone'] ?? 'N/A'),
                if (booking['preferredPriest'] != null)
                  _buildDetailRow('Priest', booking['preferredPriest']),
                if (booking['adminNotes'] != null)
                  _buildDetailRow('Admin Notes', booking['adminNotes']),
                // Documents section
                if (booking['documents'] != null && booking['documents'].isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Documents',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  ...booking['documents'].map<Widget>((doc) {
                    final documentType = doc['documentType']?.toString().toUpperCase().replaceAll('_', ' ') ?? 'DOCUMENT';
                    final fileName = doc['fileName'] ?? 'File';
                    final isVerified = doc['isVerified'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(documentType),
                        subtitle: Text(fileName),
                        trailing: isVerified == true
                            ? Icon(Icons.check_circle, color: Colors.green[600])
                            : Icon(Icons.pending, color: Colors.orange),
                        onTap: () => _openDocument(doc),
                      ),
                    );
                  }).toList(),
                ],
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

  /// Opens a document in the preview screen
  Future<void> _openDocument(dynamic doc) async {
    final fileUrl = doc['fileUrl'];
    if (fileUrl == null || fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document URL is not available')),
      );
      return;
    }

    // Convert to Document object
    final document = Document(
      id: doc['id'],
      documentType: doc['documentType'],
      fileName: doc['fileName'],
      fileUrl: fileUrl,
    );

    // Navigate to document preview screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentPreviewScreen(document: document),
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
            child: Column(
              children: [
                Row(
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
                const SizedBox(height: 12),
                Consumer<ParishProvider>(
                  builder: (context, parishProvider, _) {
                    if (parishProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    // Filter parishes based on current user's role
                    List<dynamic> availableParishes = parishProvider.parishes;
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
                        if (_selectedParishId == null) {
                          _selectedParishId = currentUserParish.id.toString();
                        }
                      }
                    }
                    
                    return DropdownButtonFormField<String>(
                      value: _selectedParishId,
                      decoration: const InputDecoration(
                        labelText: 'Parish',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        if (!Roles.isParishLevel(currentUser?.role ?? ''))
                          const DropdownMenuItem(value: null, child: Text('All Parishes')),
                        ...availableParishes
                            .map((parish) => DropdownMenuItem<String>(
                                  value: parish.id.toString(),
                                  child: Text(parish.name),
                                )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedParishId = value);
                        _loadBookings();
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Bookings List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _bookings.isEmpty
        //fix this for the admin to have their filter for the empty state - s vitug
                    ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.filter_list_off, size:64, color: Colors.grey),
                                SizedBox(height:16),
                                Text('No bookings found with current filters'),
                              ]
                            ),
                          )

                    : RefreshIndicator(
                        onRefresh: _loadBookings,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _bookings.length,
                          itemBuilder: (context, index) {
                            final booking = _bookings[index];
                            final bookingType = booking['bookingType'] ?? booking['sacramentType'];
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  // Navigate to detail screen for editing or view
                                  if (bookingType == 'baptism') {
                                    Navigator.pushNamed(
                                      context,
                                      '/baptism-detail',
                                      arguments: {
                                        'id': booking['id'] is String
                                            ? int.tryParse(booking['id'])
                                            : booking['id'] is int
                                                ? booking['id']
                                                : null,
                                        'fromStatusButton': true,
                                      },
                                    ).then((_) => _loadBookings());
                                  } else if (bookingType == 'mass_intention') {
                                    Navigator.pushNamed(
                                      context,
                                      '/mass-intention-detail',
                                      arguments: {
                                        'id': booking['id'] is String
                                            ? int.tryParse(booking['id'])
                                            : booking['id'] is int
                                                ? booking['id']
                                                : null,
                                        'fromStatusButton': true,
                                      },
                                    ).then((_) => _loadBookings());
                                  } else if (bookingType == 'confirmation') {
                                    Navigator.pushNamed(
                                      context,
                                      '/confirmation-detail',
                                      arguments: {
                                        'id': booking['id'] is String
                                            ? int.tryParse(booking['id'])
                                            : booking['id'] is int
                                                ? booking['id']
                                                : null,
                                        'fromStatusButton': true,
                                      },
                                    ).then((_) => _loadBookings());
                                  } else if (bookingType == 'anointing_sick') {
                                    Navigator.pushNamed(
                                      context,
                                      '/anointing-sick-detail',
                                      arguments: {
                                        'id': booking['id'] is String
                                            ? int.tryParse(booking['id'])
                                            : booking['id'] is int
                                                ? booking['id']
                                                : null,
                                        'fromStatusButton': true,
                                      },
                                    ).then((_) => _loadBookings());
                                  } else if (bookingType == 'funeral_mass') {
                                    Navigator.pushNamed(
                                      context,
                                      '/funeral-mass-detail',
                                      arguments: {
                                        'id': booking['id'] is String
                                            ? int.tryParse(booking['id'])
                                            : booking['id'] is int
                                                ? booking['id']
                                                : null,
                                        'fromStatusButton': true,
                                      },
                                    ).then((_) => _loadBookings());
                                  } else if (bookingType == 'reconciliation') {
                                    Navigator.pushNamed(
                                      context,
                                      '/reconciliation-detail',
                                      arguments: {
                                        'id': booking['id'] is String
                                            ? int.tryParse(booking['id'])
                                            : booking['id'] is int
                                                ? booking['id']
                                                : null,
                                        'fromStatusButton': true,
                                      },
                                    ).then((_) => _loadBookings());
                                  } else if (bookingType == 'wedding') {
                                     Navigator.pushNamed(
                                       context,
                                       '/wedding-detail',
                                       arguments: {
                                         'weddingId': booking['id'] is String
                                             ? int.tryParse(booking['id'])
                                             : booking['id'] is int
                                                 ? booking['id']
                                                 : null,
                                         'fromStatusButton': true,
                                       },
                                     ).then((_) => _loadBookings());
                                   } else if (bookingType == 'eucharist') {
                                     Navigator.pushNamed(
                                       context,
                                       '/eucharist-detail',
                                       arguments: {
                                         'id': booking['id'] is String
                                             ? int.tryParse(booking['id'])
                                             : booking['id'] is int
                                                 ? booking['id']
                                                 : null,
                                         'fromStatusButton': true,
                                       },
                                     ).then((_) => _loadBookings());
                                   } else {
                                    // Show generic details for other types
                                    _showBookingDetails(booking);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: _getStatusColor(
                                          booking['status'] ?? 'pending',
                                        ),
                                        radius: 24,
                                        child: Icon(
                                          getSacramentIcon(bookingType),
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
Text(
                                                bookingType == 'wedding'
                                                    ? booking['groomFullName'] ?? 'Booking #${booking['id']}'
                                                    : bookingType == 'mass_intention'
                                                        ? booking['donorName'] ?? 'Booking #${booking['id']}'
                                                        : bookingType == 'reconciliation'
                                                            ? booking['penitentName'] ?? 'Booking #${booking['id']}'
                                                            : bookingType == 'eucharist'
                                                                ? booking['communicantName'] ?? 'Booking #${booking['id']}'
                                                                : booking['childFullName'] ??
                                                                    booking['confirmandName'] ??
                                                                    booking['sickPersonName'] ??
                                                                    booking['deceasedFullName'] ??
                                                                    booking['coupleNames'] ??
                                                                    booking['fullName'] ??
                                                                    'Booking #${booking['id']}',
                                               style: const TextStyle(
                                                 fontWeight: FontWeight.bold,
                                                 fontSize: 15,
                                               ),
                                             ),
                                            const SizedBox(height: 4),
                                            Text(
                                              (bookingType ?? 'booking')
                                                  .toString()
                                                  .replaceAll('_', ' ')
                                                  .toUpperCase(),
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              formatDateMMDDYYYY(
                                                bookingType == 'mass_intention'
                                                    ? booking['massSchedule']?.toString()
                                                    : booking['preferredDate']?.toString(),
                                              ),
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      MaterialButton(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        color: _getStatusColor(booking['status'] ?? 'pending'),
                                        textColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          booking['status']?.toString().toUpperCase() ?? 'PENDING',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        onPressed: () {
                                          // Navigate to detail screen with editing, same as entry click
                                          if (bookingType == 'baptism') {
                                            final id = booking['id'] is String
                                                ? int.tryParse(booking['id'])
                                                : booking['id'] is int
                                                    ? booking['id']
                                                    : null;
                                            Navigator.pushNamed(
                                              context,
                                              '/baptism-detail',
                                              arguments: {'id': id, 'fromStatusButton': true},
                                            ).then((_) => _loadBookings());
                                          } else if (bookingType == 'mass_intention') {
                                            final id = booking['id'] is String
                                                ? int.tryParse(booking['id'])
                                                : booking['id'] is int
                                                    ? booking['id']
                                                    : null;
                                            Navigator.pushNamed(
                                              context,
                                              '/mass-intention-detail',
                                              arguments: {'id': id, 'fromStatusButton': true},
                                            ).then((_) => _loadBookings());
                                          } else if (bookingType == 'confirmation') {
                                            final id = booking['id'] is String
                                                ? int.tryParse(booking['id'])
                                                : booking['id'] is int
                                                    ? booking['id']
                                                    : null;
                                            Navigator.pushNamed(
                                              context,
                                              '/confirmation-detail',
                                              arguments: {'id': id, 'fromStatusButton': true},
                                            ).then((_) => _loadBookings());
                                          } else if (bookingType == 'anointing_sick') {
                                            final id = booking['id'] is String
                                                ? int.tryParse(booking['id'])
                                                : booking['id'] is int
                                                    ? booking['id']
                                                    : null;
                                            Navigator.pushNamed(
                                              context,
                                              '/anointing-sick-detail',
                                              arguments: {'id': id, 'fromStatusButton': true},
                                            ).then((_) => _loadBookings());
                                          } else if (bookingType == 'funeral_mass') {
                                            final id = booking['id'] is String
                                                ? int.tryParse(booking['id'])
                                                : booking['id'] is int
                                                    ? booking['id']
                                                    : null;
                                            Navigator.pushNamed(
                                              context,
                                              '/funeral-mass-detail',
                                              arguments: {'id': id, 'fromStatusButton': true},
                                            ).then((_) => _loadBookings());
                                          } else if (bookingType == 'reconciliation') {
                                             final id = booking['id'] is String
                                                 ? int.tryParse(booking['id'])
                                                 : booking['id'] is int
                                                     ? booking['id']
                                                     : null;
                                             Navigator.pushNamed(
                                               context,
                                               '/reconciliation-detail',
                                               arguments: {'id': id, 'fromStatusButton': true},
                                             ).then((_) => _loadBookings());
                                           } else if (bookingType == 'wedding') {
                                             final weddingId = booking['id'] is String
                                                 ? int.tryParse(booking['id'])
                                                 : booking['id'] is int
                                                     ? booking['id']
                                                     : null;
                                             Navigator.pushNamed(
                                               context,
                                               '/wedding-detail',
                                               arguments: {'weddingId': weddingId, 'fromStatusButton': true},
                                             ).then((_) => _loadBookings());
                                           } else if (bookingType == 'eucharist') {
                                             final eucharistId = booking['id'] is String
                                                 ? int.tryParse(booking['id'])
                                                 : booking['id'] is int
                                                     ? booking['id']
                                                     : null;
                                             Navigator.pushNamed(
                                               context,
                                               '/eucharist-detail',
                                               arguments: {'id': eucharistId, 'fromStatusButton': true},
                                             ).then((_) => _loadBookings());
                                           } else {
                                             // Show generic details for other types
                                             _showBookingDetails(booking);
                                           }
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        tooltip: 'Delete booking',
                                        onPressed: () => _deleteBooking(booking['id'].toString(), sacramentType: booking['bookingType'] ?? booking['sacramentType']),
                                      ),
                                    ],
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
