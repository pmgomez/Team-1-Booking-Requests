import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mass_intention.dart';
import '../providers/auth_provider.dart';
import '../services/mass_intention_service.dart';

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
  final TextEditingController _preferredPriestController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _parishNameController = TextEditingController();

  String? _selectedType;

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
      print('Intention details: type=${intention.type}, details=${intention.intentionDetails}, donor=${intention.donorName}, date=${intention.dateRequested}, time=${intention.preferredTime}');

      // Map backend type to frontend label
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
        _dateController.text = intention.dateRequested ?? '';
        _preferredTimeController.text = intention.preferredTime ?? '';
        _preferredPriestController.text = intention.preferredPriest ?? '';
        _notesController.text = intention.notes ?? '';
        _parishNameController.text = intention.parishName ?? '';
        _selectedType = mapTypeToFrontend(intention.type);
      });
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

    // Map frontend type to backend enum
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
      final result = await _massIntentionService.updateMassIntention(
        id: widget.massIntentionId!,
        type: mapType(_selectedType!),
        intentionDetails: _intentionForController.text.trim(),
        donorName: _offeredByController.text.trim(),
        dateRequested: _dateController.text,
        massSchedule: _dateController.text,
        preferredTime: _preferredTimeController.text.trim().isEmpty ? null : _preferredTimeController.text.trim(),
        preferredPriest: _preferredPriestController.text.trim().isEmpty ? null : _preferredPriestController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSaving = false);
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mass intention updated successfully')));
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

  /// Computes the display status based on current status and scheduled date
  String get _displayStatus {
    if (_intention == null) return 'PENDING';
    final status = (_intention?.status?.toUpperCase() ?? 'PENDING');
    if (status == 'APPROVED') {
      final scheduledDate = _intention?.massSchedule;
      if (scheduledDate != null && scheduledDate.isNotEmpty) {
        try {
          final now = DateTime.now();
          final bookingDate = DateTime.parse(scheduledDate);
          // Compare date only (ignore time)
          final today = DateTime(now.year, now.month, now.day);
          final eventDate = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
          if (eventDate.isBefore(today)) {
            return 'COMPLETED';
          }
        } catch (e) {
          // If date parsing fails, just return the original status
        }
      }
    }
    return status;
  }

  /// Determines if the action button should be enabled
  /// - For pending status: always true (can approve/decline)
  /// - For approved status: true only if event date has passed (can mark completed)
  /// - For other statuses: false
  bool get _canChangeStatus {
    if (_intention == null) return false;
    final status = _intention!.status?.toLowerCase();
    if (status == 'pending') {
      return true;
    } else if (status == 'approved') {
      final scheduledDate = _intention!.massSchedule;
      if (scheduledDate != null && scheduledDate.isNotEmpty) {
        try {
          final now = DateTime.now();
          final bookingDate = DateTime.parse(scheduledDate);
          final today = DateTime(now.year, now.month, now.day);
          final eventDate = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
          return eventDate.isBefore(today);
        } catch (e) {
          return false;
        }
      }
      return false;
    }
    return false;
  }

  /// Returns the appropriate action button text based on status
  String get _actionButtonText {
    if (_intention == null) return 'Approve';
    final status = _intention!.status?.toLowerCase();
    if (status == 'pending') return 'Approve';
    if (status == 'approved') return 'Mark as Completed';
    return 'Approve';
  }

  void _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _preferredTimeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
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
          ),
        ] else if (status == 'approved') ...[
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
            _textField('Preferred Time *', _preferredTimeController,
                enabled: _isEditMode, readOnly: _isEditMode, onTap: _selectTime),
            const SizedBox(height: 12),
            _textField('Offered By (Name/Family) *', _offeredByController, enabled: _isEditMode),
            const SizedBox(height: 12),
            _textField('Preferred Priest (Optional)', _preferredPriestController, enabled: _isEditMode),
            const SizedBox(height: 12),
            _textField('Additional Notes', _notesController, maxLines: 3, enabled: _isEditMode),

            const SizedBox(height: 16),

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
    _preferredPriestController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
