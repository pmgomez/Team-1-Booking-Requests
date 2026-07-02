import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../providers/mass_intention_provider.dart';
import '../providers/mass_schedule_provider.dart';
import '../models/mass_schedule.dart';

class MassIntentionScreen extends StatefulWidget {
  const MassIntentionScreen({super.key});

  @override
  State<MassIntentionScreen> createState() => _MassIntentionScreenState();
}

class _MassIntentionScreenState extends State<MassIntentionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _offeredByController = TextEditingController();
  final TextEditingController _intentionForController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedType = 'Thanksgiving';
  String? _selectedTime;
  DateTime? _selectedDate;
  List<MassSchedule> _availableSchedules = [];
  String _noSchedulesMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ParishProvider>(context, listen: false).loadAllParishes();
    });
  }

  @override
  void dispose() {
    _offeredByController.dispose();
    _intentionForController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        _selectedTime = null;
      });
      _loadSchedulesForDate(picked);
    }
  }

  Future<void> _loadSchedulesForDate(DateTime date) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final parishProvider = Provider.of<ParishProvider>(context, listen: false);
    final scheduleProvider =
        Provider.of<MassScheduleProvider>(context, listen: false);

    int? parishId;
    if (parishProvider.selectedParish != null) {
      parishId = parishProvider.selectedParish!.id;
    } else if (authProvider.currentUser?.effectiveParishId != null) {
      parishId = authProvider.currentUser!.effectiveParishId;
    }

    await scheduleProvider.loadSchedules(parishId: parishId);
    List<MassSchedule> schedules = scheduleProvider.getSchedulesForDate(date);

    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) {
      final currentTimeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      schedules = schedules.where((s) {
        if (s.intentionCutoffTime == null) return true;
        return currentTimeStr.compareTo(s.intentionCutoffTime!) < 0;
      }).toList();
    }

    setState(() {
      _availableSchedules = schedules;
      if (schedules.isNotEmpty && _selectedTime == null) {
        _selectedTime = _normalizeTime(schedules.first.startTime);
      }
      final allSchedules = scheduleProvider.getSchedulesForDate(date);
      if (allSchedules.isEmpty) {
        _noSchedulesMessage =
            'No mass schedules configured for ${_getDayName(date.weekday)}. Please select another date or contact the parish office.';
      } else if (schedules.isEmpty && isToday) {
        _noSchedulesMessage =
            'Intention cutoff time has passed for all masses today. Please select another date.';
      } else {
        _noSchedulesMessage = '';
      }
    });
  }

  String _normalizeTime(String? time) {
    if (time == null) return '';
    final parts = time.split(':');
    return '${parts[0]}:${parts[1]}';
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a mass date.")),
        );
        return;
      }
      if (_selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a mass time.")),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final massIntentionProvider =
          Provider.of<MassIntentionProvider>(context, listen: false);
      final parishProvider =
          Provider.of<ParishProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Please login to submit a mass intention.")),
        );
        return;
      }

      if (parishProvider.selectedParish == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a parish.")),
        );
        return;
      }

      String mapType(String frontendType) {
        switch (frontendType) {
          case 'Thanksgiving':
            return 'Thanksgiving';
          case 'Petition':
            return 'Special Intention';
          case 'Soul / Death Anniversary':
            return 'For the Dead';
          case 'Healing':
            return 'Special Intention';
          case 'Special Intention':
          default:
            return 'Special Intention';
        }
      }

      String formatDate(String date) {
        final parts = date.split('-');
        if (parts.length == 3) {
          return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
        }
        return date;
      }

      List<Map<String, dynamic>>? notesToAdd;
      if (_notesController.text.trim().isNotEmpty) {
        notesToAdd = [
          {
            'author': 'parishioner',
            'content': _notesController.text.trim(),
            'authorId': authProvider.currentUser!.id,
          }
        ];
      }

      final success = await massIntentionProvider.createMassIntention(
        type: mapType(_selectedType),
        intentionDetails: _intentionForController.text.trim(),
        donorName: _offeredByController.text.trim(),

        //QA Fix: Add trim() to both uses of _dateController
        dateRequested: formatDate(_dateController.text),
        parishId: parishProvider.selectedParish!.id!,
        massSchedule: formatDate(_dateController.text),

        //QA Fix: Add trim() method to the selected time.
        preferredTime: _selectedTime,
        notes: notesToAdd,
      );

      if (success && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Mass Intention Submitted"),
            content: const Text(
                "Your mass intention request has been submitted successfully."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(massIntentionProvider.errorMessage ??
                  "Failed to submit mass intention.")),
        );
      }
    }
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  String _formatTimeDisplay(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mass Intention"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSection(title: "Intention Details", children: [
                    Consumer<ParishProvider>(
                      builder: (context, parishProvider, _) {
                        return DropdownButtonFormField<int>(
                          value: parishProvider.selectedParish?.id,
                          decoration: const InputDecoration(
                            labelText: "Parish *",
                            border: OutlineInputBorder(),
                          ),
                          items: parishProvider.parishes
                              .map((parish) => DropdownMenuItem(
                                    value: parish.id,
                                    child: Text(parish.name),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            final parish = parishProvider.parishes
                                .firstWhere((p) => p.id == value);
                            parishProvider.selectParish(parish);
                            if (_selectedDate != null) {
                              _loadSchedulesForDate(_selectedDate!);
                            }
                          },
                          validator: (value) =>
                              value == null ? "Please select a parish" : null,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                          labelText: "Intention Type *",
                          border: OutlineInputBorder()),
                      items: [
                        'Thanksgiving',
                        'Petition',
                        'Soul / Death Anniversary',
                        'Healing',
                        'Special Intention'
                      ]
                          .map((label) => DropdownMenuItem(
                              value: label, child: Text(label)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedType = value!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _intentionForController,
                      decoration: const InputDecoration(
                          labelText: "Name of Person / Intention *",
                          border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? "Required" : null,
                    ),
                  ]),
                  _buildSection(title: "Schedule & Offering", children: [
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                          labelText: "Preferred Mass Date *",
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today)),
                      onTap: () async {
                        FocusScope.of(context).requestFocus(FocusNode());
                        await _selectDate();
                      },
                      validator: (value) =>
                          value!.isEmpty ? "Please select a date" : null,
                    ),
                    const SizedBox(height: 12),
                    if (_selectedDate != null && _availableSchedules.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _noSchedulesMessage,
                                style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_availableSchedules.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _selectedTime,
                        decoration: const InputDecoration(
                          labelText: "Mass Time *",
                          border: OutlineInputBorder(),
                        ),
                        items: _availableSchedules
                            .fold<Map<String, MassSchedule>>({}, (map, s) {
                              final normalized = _normalizeTime(s.startTime);
                              if (!map.containsKey(normalized)) {
                                map[normalized] = s;
                              }
                              return map;
                            })
                            .values
                            .map((s) => DropdownMenuItem(
                                  value: _normalizeTime(s.startTime),
                                  child: Text(
                                      '${_formatTimeDisplay(s.startTime)} - ${_formatTimeDisplay(s.endTime)}${s.notes != null ? ' (${s.notes})' : ''}'),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedTime = value),
                        validator: (value) =>
                            value == null ? "Please select a mass time" : null,
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _offeredByController,
                      decoration: const InputDecoration(
                          labelText: "Offered By (Name/Family) *",
                          border: OutlineInputBorder()),
                      validator: (value) => value!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                          labelText: "Additional Notes",
                          border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Consumer<MassIntentionProvider>(
                    builder: (context, provider, _) {
                      return Center(
                        child: ElevatedButton(
                          onPressed: provider.isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 28),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: provider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text("Submit Mass Intention",
                                  style: TextStyle(fontSize: 16)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }
}
