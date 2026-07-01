import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../providers/mass_schedule_provider.dart';
import '../services/admin_service.dart';
import '../models/mass_intention.dart';
import '../models/mass_schedule.dart';
import '../utils/sacrament_icons.dart';

class AdminMassIntentionsScreen extends StatefulWidget {
  const AdminMassIntentionsScreen({super.key});

  @override
  State<AdminMassIntentionsScreen> createState() =>
      _AdminMassIntentionsScreenState();
}

class _AdminMassIntentionsScreenState extends State<AdminMassIntentionsScreen> {
  final AdminService _adminService = AdminService();
  final List<MassIntention> _intentions = [];
  bool _isLoading = true;
  String? _errorMessage;

  String? _selectedDate;
  String? _selectedTime;
  String? _selectedParishId;
  List<MassSchedule> _availableSchedules = [];

  List<String> get _massTimes {
    if (_availableSchedules.isEmpty) {
      return [
        '05:00',
        '06:00',
        '07:00',
        '08:00',
        '09:00',
        '10:00',
        '16:00',
        '17:00',
        '18:00',
        '19:00'
      ];
    }
    return _availableSchedules
        .map((s) {
          final parts = s.startTime.split(':');
          return '${parts[0]}:${parts[1]}';
        })
        .toSet()
        .toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDefaults();
    });
  }

  Future<void> _initializeDefaults() async {
    final now = DateTime.now();
    setState(() {
      _selectedDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    });

    await _loadSchedulesForDate(now);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userParishId = authProvider.currentUser?.effectiveParishId;
    if (userParishId != null) {
      setState(() {
        _selectedParishId = userParishId.toString();
      });
    }

    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _loadSchedulesForDate(DateTime date) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final scheduleProvider =
        Provider.of<MassScheduleProvider>(context, listen: false);

    int? parishId;
    if (_selectedParishId != null) {
      parishId = int.tryParse(_selectedParishId!);
    } else if (authProvider.currentUser?.effectiveParishId != null) {
      parishId = authProvider.currentUser!.effectiveParishId;
    }

    await scheduleProvider.loadSchedules(parishId: parishId);
    final schedules = scheduleProvider.getSchedulesForDate(date);

    setState(() {
      _availableSchedules = schedules;
      if (schedules.isNotEmpty && _selectedTime == null) {
        _selectedTime = _findNearestMassTime();
      }
    });

    await _loadIntentions();
  }

  String _findNearestMassTime() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    if (_massTimes.isNotEmpty) {
      String nearestTime = _massTimes.first;
      int smallestDiff = 999999;

      for (final time in _massTimes) {
        final timeParts = time.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        final diff = (hour * 60 + minute) - (currentHour * 60 + currentMinute);
        if (diff >= 0 && diff < smallestDiff) {
          smallestDiff = diff;
          nearestTime = time;
        }
      }

      if (smallestDiff == 999999) {
        nearestTime = _massTimes.first;
      }

      return nearestTime;
    }

    final fallbackTimes = [
      '05:00',
      '06:00',
      '07:00',
      '08:00',
      '09:00',
      '10:00',
      '16:00',
      '17:00',
      '18:00',
      '19:00'
    ];
    String nearestTime = fallbackTimes.first;
    int smallestDiff = 999999;

    for (final time in fallbackTimes) {
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final diff = (hour * 60 + minute) - (currentHour * 60 + currentMinute);
      if (diff >= 0 && diff < smallestDiff) {
        smallestDiff = diff;
        nearestTime = time;
      }
    }

    if (smallestDiff == 999999) {
      nearestTime = fallbackTimes.first;
    }

    return nearestTime;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate != null
          ? DateTime.parse(_selectedDate!)
          : DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        _selectedTime = null;
        _availableSchedules.clear();
      });
      await _loadSchedulesForDate(picked);
      await _loadIntentions();
    }
  }

  Future<void> _loadIntentions() async {
    if (_selectedDate == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _intentions.clear();
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Authentication required';
          });
        }
        return;
      }

      final response = await _adminService.getAdminMassIntentions(
        token,
        status: 'approved',
        parishId: _selectedParishId,
        startDate: _selectedDate,
        endDate: _selectedDate,
        massTime: _selectedTime,
      );

      print(
          '[MassIntentionsScreen] Request: parishId=$_selectedParishId, startDate=$_selectedDate, massTime=$_selectedTime');
      print('[MassIntentionsScreen] Response success: ${response.success}');
      print('[MassIntentionsScreen] Response message: ${response.message}');
      print(
          '[MassIntentionsScreen] Response data keys: ${response.data?.keys.toList()}');
      print(
          '[MassIntentionsScreen] Mass intentions count: ${(response.data?['massIntentions'] as List?)?.length ?? 0}');
      print(
          '[MassIntentionsScreen] Mass intentions data: ${response.data?['massIntentions']}');

      if (mounted) {
        if (response.success && response.data != null) {
          final rawList = response.data!['massIntentions'] as List? ?? [];
          final mapped = rawList
              .map((item) =>
                  MassIntention.fromJson(item as Map<String, dynamic>))
              .toList();

          setState(() {
            _intentions.clear();
            _intentions.addAll(mapped);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                response.message ?? 'Failed to load mass intentions';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Map<String, List<MassIntention>> _groupIntentionsByType() {
    final Map<String, List<MassIntention>> grouped = {};
    for (final intention in _intentions) {
      final type = intention.type ?? 'Other';
      if (!grouped.containsKey(type)) {
        grouped[type] = [];
      }
      grouped[type]!.add(intention);
    }
    return grouped;
  }

  String _formatDateDisplay(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getParishName(String? parishId) {
    if (parishId == null) return 'All Parishes';
    final parishProvider = Provider.of<ParishProvider>(context, listen: false);
    final id = int.tryParse(parishId);
    if (id == null) return 'Unknown Parish';
    final parish = parishProvider.parishes.where((p) => p.id == id).firstOrNull;
    return parish?.name ?? 'Unknown Parish';
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    final grouped = _groupIntentionsByType();
    final parishName = _getParishName(_selectedParishId);
    final dateDisplay = _formatDateDisplay(_selectedDate);
    String timeDisplay = 'N/A';
    if (_selectedTime != null) {
      final parts = _selectedTime!.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      timeDisplay = '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final List<pw.Widget> content = [];

          content.add(
            pw.Header(
              level: 0,
              child: pw.Text(
                'Mass Intentions',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
          );

          content.add(pw.SizedBox(height: 8));

          content.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Date: $dateDisplay',
                    style: pw.TextStyle(fontSize: 14)),
                pw.Text('Time: $timeDisplay',
                    style: pw.TextStyle(fontSize: 14)),
              ],
            ),
          );

          content.add(
            pw.Text(
              'Parish: $parishName',
              style: pw.TextStyle(fontSize: 14),
            ),
          );

          content.add(pw.Divider());
          content.add(pw.SizedBox(height: 12));

          int typeIndex = 0;
          grouped.forEach((type, intentions) {
            typeIndex++;
            content.add(
              pw.Text(
                'Intention Type $typeIndex: $type',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            );
            content.add(pw.SizedBox(height: 6));

            for (final intention in intentions) {
              final offeredBy = intention.donorName ?? 'Unknown';
              final details = intention.intentionDetails ?? '';
              content.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
                  child: pw.Text(
                    details.isNotEmpty
                        ? '- $details offered by $offeredBy'
                        : '- offered by $offeredBy',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ),
              );
            }

            content.add(pw.SizedBox(height: 12));
          });

          if (grouped.isEmpty) {
            content.add(
              pw.Center(
                child: pw.Text(
                  'No mass intentions found for the selected date.',
                  style: pw.TextStyle(
                      fontSize: 14, fontStyle: pw.FontStyle.italic),
                ),
              ),
            );
          }

          return content;
        },
      ),
    );

    final now = DateTime.now();
    String dateStr = 'report';
    if (_selectedDate != null) {
      final parts = _selectedDate!.split('-');
      final y = parts[0];
      final m = int.parse(parts[1]);
      final d = parts[2];
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      dateStr = '${months[m - 1]}_${d}_$y';
    }
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'MassIntention_${dateStr}_${timeStr}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mass Intentions'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'View/Download PDF',
            onPressed: _intentions.isNotEmpty ? _generatePdf : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Mass Date',
                            border: OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _selectedDate != null
                                ? _formatDateDisplay(_selectedDate)
                                : 'Select date',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTime,
                        decoration: const InputDecoration(
                          labelText: 'Mass Time',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: _massTimes.map((time) {
                          final hour = int.parse(time.split(':')[0]);
                          final minute = int.parse(time.split(':')[1]);
                          final period = hour >= 12 ? 'PM' : 'AM';
                          final displayHour =
                              hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
                          return DropdownMenuItem(
                            value: time,
                            child: Text(
                                '$displayHour:${minute.toString().padLeft(2, '0')} $period'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedTime = value);
                          _loadIntentions();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Consumer<ParishProvider>(
                  builder: (context, parishProvider, _) {
                    final authProvider =
                        Provider.of<AuthProvider>(context, listen: false);
                    final currentUser = authProvider.currentUser;
                    final isParishLevel = currentUser != null &&
                        ['parish_admin', 'parish_staff']
                            .contains(currentUser.role);

                    if (isParishLevel) {
                      return InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Parish',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        child: Text(_getParishName(_selectedParishId)),
                      );
                    }

                    List<dynamic> availableParishes = parishProvider.parishes;
                    return DropdownButtonFormField<String>(
                      value: _selectedParishId,
                      decoration: const InputDecoration(
                        labelText: 'Parish',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('All Parishes')),
                        ...availableParishes
                            .map((parish) => DropdownMenuItem<String>(
                                  value: parish.id.toString(),
                                  child: Text(parish.name),
                                )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedParishId = value);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
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
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadIntentions,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _intentions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_busy,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No mass intentions for ${_formatDateDisplay(_selectedDate)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : _buildIntentionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIntentionsList() {
    final grouped = _groupIntentionsByType();
    final entries = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final type = entry.key;
        final intentions = entry.value;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      getSacramentIcon('mass_intention'),
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Intention Type ${index + 1}: $type',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                ...intentions.map((MassIntention intention) {
                  final offeredBy = intention.donorName ?? 'Unknown';
                  final details = intention.intentionDetails ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\u2022 ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            details.isNotEmpty
                                ? '$details offered by $offeredBy'
                                : 'offered by $offeredBy',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}
