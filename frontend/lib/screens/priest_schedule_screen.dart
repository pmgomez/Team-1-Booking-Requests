import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';

class PriestScheduleScreen extends StatefulWidget {
  const PriestScheduleScreen({super.key});

  @override
  State<PriestScheduleScreen> createState() => _PriestScheduleScreenState();
}

class _PriestScheduleScreenState extends State<PriestScheduleScreen> {
  final AdminService _adminService = AdminService();
  
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication error';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _adminService.getPriestSchedule(
        token,
        month: _currentMonth,
        year: _currentYear,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _bookings = List<dynamic>.from(response.data!['bookings'] ?? []);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = response.message ?? 'Failed to load schedule';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _previousMonth() {
    if (_currentMonth == 1) {
      setState(() {
        _currentMonth = 12;
        _currentYear -= 1;
      });
    } else {
      setState(() {
        _currentMonth -= 1;
      });
    }
    _loadSchedule();
  }

  void _nextMonth() {
    if (_currentMonth == 12) {
      setState(() {
        _currentMonth = 1;
        _currentYear += 1;
      });
    } else {
      setState(() {
        _currentMonth += 1;
      });
    }
    _loadSchedule();
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _getSacramentDisplayName(String? type) {
    switch (type) {
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
        return 'Anointing of the Sick';
      case 'funeral_mass':
        return 'Funeral Mass';
      default:
        return type ?? 'Sacrament';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSacramentIcon(String? type) {
    switch (type) {
      case 'baptism':
        return Icons.water_drop;
      case 'wedding':
        return Icons.wc;
      case 'confirmation':
        return Icons.local_fire_department;
      case 'eucharist':
        return Icons.breakfast_dining;
      case 'reconciliation':
        return Icons.handshake;
      case 'anointing_sick':
        return Icons.medical_services;
      case 'funeral_mass':
        return Icons.church;
      default:
        return Icons.event;
    }
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    _getSacramentIcon(booking['bookingType']),
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getSacramentDisplayName(booking['bookingType']),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Status', booking['status']?.toString().toUpperCase() ?? 'N/A', color: _getStatusColor(booking['status'])),
              _buildDetailRow('Date', _formatDate(booking['preferredDate'])),
              _buildDetailRow('Time', booking['preferredTimeSlot'] ?? 'Not specified'),
              if (booking['parish'] != null)
                _buildDetailRow('Parish', booking['parish']['name'] ?? 'N/A'),
              const Divider(height: 32),
              const Text(
                'Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildBookingDetails(booking),
              if (booking['notes'] != null && (booking['notes'] as List).isNotEmpty) ...[
                const Divider(height: 32),
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...(booking['notes'] as List).map<Widget>((note) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${note['author'] ?? 'Unknown'} - ${_formatDateTime(note['timestamp'])}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(note['content'] ?? ''),
                      ],
                    ),
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBookingDetails(Map<String, dynamic> booking) {
    final List<Widget> details = [];
    final type = booking['bookingType'];

    switch (type) {
      case 'baptism':
        if (booking['childFullName'] != null) {
          details.add(_buildDetailRow('Child Name', booking['childFullName']));
        }
        if (booking['fatherName'] != null) {
          details.add(_buildDetailRow('Father', booking['fatherName']));
        }
        if (booking['motherName'] != null) {
          details.add(_buildDetailRow('Mother', booking['motherName']));
        }
        if (booking['contactPhone'] != null) {
          details.add(_buildDetailRow('Phone', booking['contactPhone']));
        }
        if (booking['contactEmail'] != null) {
          details.add(_buildDetailRow('Email', booking['contactEmail']));
        }
        break;
      case 'wedding':
        if (booking['groomName'] != null) {
          details.add(_buildDetailRow('Groom', booking['groomName']));
        }
        if (booking['brideName'] != null) {
          details.add(_buildDetailRow('Bride', booking['brideName']));
        }
        if (booking['contactPhone'] != null) {
          details.add(_buildDetailRow('Phone', booking['contactPhone']));
        }
        if (booking['contactEmail'] != null) {
          details.add(_buildDetailRow('Email', booking['contactEmail']));
        }
        break;
      case 'confirmation':
      case 'eucharist':
        if (booking['fullName'] != null) {
          details.add(_buildDetailRow('Name', booking['fullName']));
        }
        if (booking['contactPhone'] != null) {
          details.add(_buildDetailRow('Phone', booking['contactPhone']));
        }
        if (booking['contactEmail'] != null) {
          details.add(_buildDetailRow('Email', booking['contactEmail']));
        }
        break;
      case 'reconciliation':
        if (booking['fullName'] != null) {
          details.add(_buildDetailRow('Name', booking['fullName']));
        }
        if (booking['contactPhone'] != null) {
          details.add(_buildDetailRow('Phone', booking['contactPhone']));
        }
        break;
      case 'anointing_sick':
        if (booking['fullName'] != null) {
          details.add(_buildDetailRow('Patient Name', booking['fullName']));
        }
        if (booking['contactPhone'] != null) {
          details.add(_buildDetailRow('Contact Phone', booking['contactPhone']));
        }
        if (booking['hospitalName'] != null) {
          details.add(_buildDetailRow('Hospital', booking['hospitalName']));
        }
        break;
      case 'funeral_mass':
        if (booking['deceasedName'] != null) {
          details.add(_buildDetailRow('Deceased', booking['deceasedName']));
        }
        if (booking['contactPerson'] != null) {
          details.add(_buildDetailRow('Contact Person', booking['contactPerson']));
        }
        if (booking['contactPhone'] != null) {
          details.add(_buildDetailRow('Phone', booking['contactPhone']));
        }
        break;
    }

    return details;
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr.toString();
    }
  }

  String _formatDateTime(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous Month',
                ),
                Text(
                  '${_getMonthName(_currentMonth)} $_currentYear',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next Month',
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadSchedule,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _bookings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No scheduled bookings for this month',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _bookings.length,
                            itemBuilder: (context, index) {
                              final booking = _bookings[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () => _showBookingDetails(booking),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            _getSacramentIcon(booking['bookingType']),
                                            color: Theme.of(context).primaryColor,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _getSacramentDisplayName(booking['bookingType']),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${_formatDate(booking['preferredDate'])} ${booking['preferredTimeSlot'] ?? ''}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              if (booking['parish'] != null)
                                                Text(
                                                  booking['parish']['name'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(booking['status']).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            booking['status']?.toString().toUpperCase() ?? 'N/A',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _getStatusColor(booking['status']),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}