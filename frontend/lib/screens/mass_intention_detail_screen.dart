import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mass_intention.dart';
import '../models/note.dart';
import '../models/mass_schedule.dart';
import '../providers/auth_provider.dart';
import '../providers/mass_schedule_provider.dart';
import '../services/mass_intention_service.dart';
import '../widgets/notes_display.dart';

class MassIntentionDetailScreen extends StatefulWidget {
  final int? massIntentionId;
  final bool fromStatusButton;

  const MassIntentionDetailScreen({
    super.key,
    required this.massIntentionId,
    this.fromStatusButton = false,
  });

  @override
  State<MassIntentionDetailScreen> createState() => _MassIntentionDetailScreenState();
}

class _MassIntentionDetailScreenState extends State<MassIntentionDetailScreen> {
  final MassIntentionService _massIntentionService = MassIntentionService();
  bool _isEditMode = false;
  bool _isSaving = false;
  bool _showStatusButtons = true;

  MassIntention? _intention;

  final TextEditingController _intentionForController = TextEditingController();
  final TextEditingController _offeredByController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _preferredTimeController = TextEditingController();
  final TextEditingController _newNoteController = TextEditingController();
  final TextEditingController _parishNameController = TextEditingController();

  String? _selectedType;
  String? _selectedTime;
  DateTime? _selectedDate;
  List<MassSchedule> _availableSchedules = [];

  @override
  void initState() {
    super.initState();
    _showStatusButtons = !widget.fromStatusButton;
    _loadMassIntention();
  }

  Future<void> _loadMassIntention() async {
    if (widget.massIntentionId == null || widget.massIntentionId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid ID')));
      return;
    }

    print('=== Loading mass intention ID: ${widget.massIntentionId} ===');
    final result = await _massIntentionService.getMassIntentionById(id: widget.massIntentionId!);
    print('Result success: ${result.success}');
    print('Result data: ${result.data}');
    print('Result message: ${result.message}');
    print('Result errors: ${result.errors}');

    if (mounted && result.success && result.data != null) {
      final intention = result.data!;
      final status = intention.status?.toLowerCase() ?? 'pending';
      final isEditable = status == 'pending' || status == 'declined';

      String mapTypeToFrontend(String? backendType) {
        switch (backendType) {
          case 'Thanksgiving':
            return 'Thanksgiving';
          case 'Special Intention':
            return 'Special Intention';
          case 'For the Dead':
            return 'Soul / Death Anniversary';
          default:
            return 'Special Intention';
        }
      }

      setState(() {
        _intention = intention;
        _intentionForController.text = intention.intentionDetails ?? '';
        _offeredByController.text = intention.donorName ?? '';
        _parishNameController.text = intention.parishName ?? '';
        _selectedType = mapTypeToFrontend(intention.type);

        final massSchedule = intention.massSchedule ?? '';
        print('[MassIntentionDetail] massSchedule: "$massSchedule"');
        if (massSchedule.isNotEmpty && massSchedule.contains('T')) {
          final utcDate = DateTime.parse(massSchedule);
          final phDate = utcDate.add(const Duration(hours: 8));
          _dateController.text = '${phDate.year}-${phDate.month.toString().padLeft(2, '0')}-${phDate.day.toString().padLeft(2, '0')}';
          _selectedTime = _normalizeTime(intention.preferredTime);
          print('[MassIntentionDetail] Parsed date (PH): "${_dateController.text}", time: "$_selectedTime"');
        } else {
          _dateController.text = intention.dateRequested ?? '';
          _selectedTime = _normalizeTime(intention.preferredTime);
          print('[MassIntentionDetail] Fallback date: "${_dateController.text}", time: "$_selectedTime"');
        }
        _preferredTimeController.text = _selectedTime ?? '';

        if (_dateController.text.isNotEmpty) {
          try {
            _selectedDate = DateTime.parse(_dateController.text);
          } catch (e) {}
        }
        // Do not populate _newNoteController - it's for adding new notes
      });

      if (_selectedDate != null) {
        await _loadSchedulesForDate(_selectedDate!);
      }
      if (widget.fromStatusButton && isEditable) {
        setState(() => _isEditMode = true);
      } else {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        final isOwner = intention.submittedBy == currentUser?.id;
        if (!widget.fromStatusButton && isOwner && isEditable) {
          setState(() => _isEditMode = true);
        }
      }
    } else if (mounted) {
      print('Failed to load: ${result.message}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to load mass intention')));
    }
  }

  String _normalizeTime(String? time) {
    if (time == null || time.isEmpty) return '';
    final parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return time;
  }

  Future<void> _loadSchedulesForDate(DateTime date) async {
    final scheduleProvider = Provider.of<MassScheduleProvider>(context, listen: false);
    int? parishId = _intention?.parishId;

    print('[MassIntentionDetail] Loading schedules for parishId: $parishId, date: $date (${_getDayName(date.weekday)})');
    print('[MassIntentionDetail] _intention.parishId: ${_intention?.parishId}');

    await scheduleProvider.loadSchedules(parishId: parishId);

    print('[MassIntentionDetail] All loaded schedules: ${scheduleProvider.schedules.length}');
    for (final s in scheduleProvider.schedules) {
      print('  - ${s.dayOfWeek} ${s.startTime} active: ${s.isActive} parishId: ${s.parishId}');
    }

    final schedules = scheduleProvider.getSchedulesForDate(date);
    print('[MassIntentionDetail] Filtered schedules for ${_getDayName(date.weekday)}: ${schedules.length}');

    final normalizedSelectedTime = _normalizeTime(_selectedTime);

    setState(() {
      _availableSchedules = schedules;
      if (schedules.isNotEmpty) {
        final availableTimes = schedules.map((s) => _normalizeTime(s.startTime)).toSet();
        if (normalizedSelectedTime.isNotEmpty && !availableTimes.contains(normalizedSelectedTime)) {
          _availableSchedules = [
            MassSchedule(
              parishId: _intention?.parishId ?? 0,
              dayOfWeek: _getDayName(date.weekday),
              startTime: normalizedSelectedTime,
              endTime: normalizedSelectedTime,
              isActive: true,
            ),
            ...schedules,
          ];
        }
        _selectedTime = normalizedSelectedTime.isNotEmpty ? normalizedSelectedTime : _normalizeTime(schedules.first.startTime);
        _preferredTimeController.text = _selectedTime!;
      } else {
        _selectedTime = normalizedSelectedTime.isNotEmpty ? normalizedSelectedTime : null;
        _preferredTimeController.text = _selectedTime ?? '';
      }
    });
  }

  void _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        _selectedTime = null;
        _preferredTimeController.text = '';
        _availableSchedules.clear();
      });
      _loadSchedulesForDate(picked);
    }
  }

  bool _validateForm() {
    if (_intentionForController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name of person/intention is required')));
      return false;
    }
    if (_offeredByController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offered by is required')));
      return false;
    }
    if (_dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferred date is required')));
      return false;
    }
    if (_preferredTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferred time is required')));
      return false;
    }
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intention type is required')));
      return false;
    }
    return true;
  }

  Future<void> _saveChanges() async {
    if (!_validateForm()) return;
    if (widget.massIntentionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid ID')));
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

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      final isParishioner = currentUser?.role == 'parishioner';

      // Prepare notes array if a new note was added
      List<Map<String, dynamic>>? notesToAdd;
      if (_newNoteController.text.trim().isNotEmpty) {
        notesToAdd = [
          {
            'author': isParishioner ? 'parishioner' : 'admin',
            'content': _newNoteController.text.trim(),
            'authorId': currentUser?.id,
          }
        ];
      }

      final result = await _massIntentionService.updateMassIntention(
        id: widget.massIntentionId!,
        type: mapType(_selectedType!),
        intentionDetails: _intentionForController.text.trim(),
        donorName: _offeredByController.text.trim(),
        dateRequested: _dateController.text,
        parishId: _intention?.parishId ?? 0,
        massSchedule: _dateController.text,
        preferredTime: _preferredTimeController.text.trim().isEmpty ? null : _normalizeTime(_preferredTimeController.text.trim()),
        notes: notesToAdd,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mass intention updated successfully')));
          _newNoteController.clear();
          // Reload data to get updated preferredTime
          await _loadMassIntention();
          _toggleEditMode();
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to update')));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) _showStatusButtons = true;
    });
  }

  void _updateStatus(String status) async {
    if (widget.massIntentionId == null) return;

    final result = await _massIntentionService.updateMassIntentionStatus(
      id: widget.massIntentionId!,
      status: status,
    );

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mass intention marked as $status')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed')));
      }
    }
  }

  Future<void> _resubmitMassIntention(dynamic currentUser) async {
    if (widget.massIntentionId == null) return;

    setState(() => _isSaving = true);

    try {
      final isParishioner = currentUser?.role == 'parishioner';

      List<Map<String, dynamic>>? notes;
      if (_newNoteController.text.trim().isNotEmpty) {
        notes = [{
          'author': isParishioner ? 'parishioner' : 'user',
          'content': _newNoteController.text.trim(),
          'authorId': currentUser?.id,
        }];
      }

      // Use updateMassIntention with status='pending' to resubmit
      String mapTypeForResubmit(String? frontendType) {
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

      final result = await _massIntentionService.updateMassIntention(
        id: widget.massIntentionId!,
        type: mapTypeForResubmit(_selectedType),
        intentionDetails: _intentionForController.text.trim(),
        donorName: _offeredByController.text.trim(),
        dateRequested: _dateController.text,
        parishId: _intention?.parishId ?? 0,
        massSchedule: _dateController.text,
        preferredTime: _preferredTimeController.text.trim().isEmpty ? null : _normalizeTime(_preferredTimeController.text.trim()),
        notes: notes,
        status: 'pending',
      );

      if (mounted) {
        setState(() => _isSaving = false);

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mass intention resubmitted successfully')));
          _newNoteController.clear();
          await _loadMassIntention();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to resubmit')));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String get _displayStatus {
    if (_intention == null) return 'PENDING';
    final status = (_intention?.status?.toUpperCase() ?? 'PENDING');
    if (status == 'APPROVED') {
      final scheduledDate = _intention?.massSchedule;
      if (scheduledDate != null && scheduledDate.isNotEmpty) {
        try {
          final nowPh = DateTime.now().add(const Duration(hours: 8));
          final bookingDateUtc = DateTime.parse(scheduledDate);
          final bookingDatePh = bookingDateUtc.add(const Duration(hours: 8));
          final todayPh = DateTime(nowPh.year, nowPh.month, nowPh.day);
          final eventDatePh = DateTime(bookingDatePh.year, bookingDatePh.month, bookingDatePh.day);
          if (eventDatePh.isBefore(todayPh)) {
            return 'COMPLETED';
          }
        } catch (e) {}
      }
    }
    return status;
  }

  bool get _canChangeStatus {
    if (_intention == null) return false;
    final status = _intention!.status?.toLowerCase();
    if (status == 'pending') {
      return true;
    } else if (status == 'approved') {
      final scheduledDate = _intention!.massSchedule;
      if (scheduledDate != null && scheduledDate.isNotEmpty) {
        try {
          final nowPh = DateTime.now().add(const Duration(hours: 8));
          final bookingDateUtc = DateTime.parse(scheduledDate);
          final bookingDatePh = bookingDateUtc.add(const Duration(hours: 8));
          final todayPh = DateTime(nowPh.year, nowPh.month, nowPh.day);
          final eventDatePh = DateTime(bookingDatePh.year, bookingDatePh.month, bookingDatePh.day);
          return eventDatePh.isBefore(todayPh);
        } catch (e) {
          return false;
        }
      }
      return false;
    }
    return false;
  }

  String get _actionButtonText {
    if (_intention == null) return 'Approve';
    final status = _intention!.status?.toLowerCase();
    if (status == 'pending') return 'Approve';
    if (status == 'approved') return 'Mark as Completed';
    return 'Approve';
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

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      );

  Widget _textField(String label, TextEditingController controller,
      {bool enabled = true, bool readOnly = false, VoidCallback? onTap, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        readOnly: readOnly,
        maxLines: maxLines,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          border: enabled ? const OutlineInputBorder() : OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: enabled,
          fillColor: enabled ? null : Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildStatusSection(bool isAdmin, int intentionId) {
    if (!isAdmin || _showStatusButtons) return const SizedBox.shrink();

    // 1. Check the current user's role
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserRole = authProvider.currentUser?.role;

    // 2. Define who has final approval authority (exclude parish_staff)
    final canApprove = currentUserRole == 'priest' ||
        currentUserRole == 'parish_admin' ||
        currentUserRole == 'diocese_admin' ||
        currentUserRole == 'diocese_staff';

    final displayStatus = _displayStatus;
    final canChangeStatus = _canChangeStatus;
    final actionButtonText = _actionButtonText;
    final status = _intention?.status?.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 120,
                child: Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: Text(
                  displayStatus,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        if (status == 'pending') ...[
          // 3. Conditionally render buttons based on the role flag
          if (canApprove)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => _updateStatus('approved'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Decline'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => _updateStatus('declined'),
                  ),
                ),
              ],
            )
          else
          // Fallback UI for parish_staff
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Pending Priest Approval",
                style: TextStyle(color: Colors.orange, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
              ),
            ),
        ] else if (status == 'approved') ...[
          if (canApprove)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(actionButtonText),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: canChangeStatus ? () => _updateStatus('completed') : null,
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final role = currentUser?.role;
    final isAdmin = ['parish_admin', 'parish_staff', 'diocese_admin', 'diocese_staff'].contains(role);
    final isOwner = _intention?.submittedBy == currentUser?.id;
    final status = _intention?.status?.toLowerCase();
    final canEdit = isAdmin || (isOwner && (status == 'pending' || status == 'declined'));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mass Intention Details"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: Icon(_isSaving ? Icons.edit : Icons.save),
              tooltip: _isSaving ? 'Saving...' : 'Save changes',
              color: _isSaving ? Colors.orange : null,
              onPressed: _saveChanges,
            )
          else if (!_showStatusButtons && canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: _toggleEditMode,
            )
          else
            const SizedBox.shrink(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildSectionTitle('Intention Details'),
            if (_isEditMode)
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: "Intention Type *", border: OutlineInputBorder()),
                items: ['Thanksgiving', 'Petition', 'Soul / Death Anniversary', 'Healing', 'Special Intention']
                    .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              )
            else
              _textField('Intention Type', TextEditingController(text: _selectedType ?? ''), enabled: false),
            const SizedBox(height: 12),
            _textField('Parish', _parishNameController, enabled: false),
            const SizedBox(height: 12),
            _textField('Name of Person / Intention *', _intentionForController, enabled: _isEditMode),
            const SizedBox(height: 12),

            _buildSectionTitle('Schedule & Offering'),
            _textField('Preferred Date *', _dateController,
                enabled: _isEditMode, readOnly: _isEditMode, onTap: _selectDate),
            const SizedBox(height: 12),
            if (_isEditMode) ...[
              if (_selectedDate != null && _availableSchedules.isEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No mass schedules for ${_getDayName(_selectedDate!.weekday)}',
                          style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_availableSchedules.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedTime != null ? _normalizeTime(_selectedTime) : null,
                  decoration: const InputDecoration(
                    labelText: 'Mass Time *',
                    border: OutlineInputBorder(),
                  ),
                  items: _availableSchedules
                      .map((s) {
                        final normalizedTime = _normalizeTime(s.startTime);
                        return DropdownMenuItem(
                          value: normalizedTime,
                          child: Text(_formatTimeDisplay(s.startTime)),
                        );
                      })
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTime = value;
                      _preferredTimeController.text = value ?? '';
                    });
                  },
                  validator: (value) => value == null ? 'Please select a mass time' : null,
                ),
            ] else
              _textField('Preferred Time *', _preferredTimeController, enabled: false),
            const SizedBox(height: 12),
            _textField('Offered By (Name/Family) *', _offeredByController, enabled: _isEditMode),
            const SizedBox(height: 12),

            // Display existing notes
            if (_intention?.notes != null && _intention!.notes!.isNotEmpty)
              NotesDisplay(notes: _intention!.notes!),

            // Add new note field (only in edit mode)
            if (_isEditMode) ...[
              const SizedBox(height: 16),
              _buildSectionTitle('Add Note (Optional)'),
              _textField('Add a note', _newNoteController, maxLines: 3, enabled: true),
            ],

            const SizedBox(height: 20),

            // Resubmit button for declined status (owner only)
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final currentUser = authProvider.currentUser;
                final isOwner = _intention?.submittedBy == currentUser?.id;
                final status = _intention?.status?.toLowerCase();

                if (status == 'declined' && isOwner) {
                  return Column(
                    children: [
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your mass intention was declined. Please make the necessary changes and resubmit.',
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: _isSaving
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.refresh),
                                  label: Text(_isSaving ? 'Resubmitting...' : 'Resubmit'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _isSaving ? null : () => _resubmitMassIntention(currentUser),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            _buildStatusSection(isAdmin, widget.massIntentionId ?? 0),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _intentionForController.dispose();
    _offeredByController.dispose();
    _dateController.dispose();
    _preferredTimeController.dispose();
    _newNoteController.dispose();
    super.dispose();
  }
}
