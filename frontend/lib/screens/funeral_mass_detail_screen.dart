import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/document.dart';
import '../models/funeral_mass_booking.dart';
import '../providers/auth_provider.dart';
import '../services/funeral_mass_service.dart';
import '../config/api_config.dart';

class FuneralMassDetailScreen extends StatefulWidget {
  final int? funeralMassId;
  final bool fromStatusButton;

  const FuneralMassDetailScreen({
    super.key,
    required this.funeralMassId,
    this.fromStatusButton = false,
  });

  @override
  State<FuneralMassDetailScreen> createState() => _FuneralMassDetailScreenState();
}

class _FuneralMassDetailScreenState extends State<FuneralMassDetailScreen> {
  final FuneralMassService _funeralMassService = FuneralMassService();
  XFile? _documentFile;
  bool _isUploading = false;

  bool _isEditMode = false;
  bool _isSaving = false;
  bool _showStatusButtons = true;

  FuneralMassBooking? _booking;

  final TextEditingController _deceasedNameController = TextEditingController();
  final TextEditingController _dateOfDeathController = TextEditingController();
  final TextEditingController _representativeNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _wakeStartDateController = TextEditingController();
  final TextEditingController _wakeEndDateController = TextEditingController();
  final TextEditingController _wakeLocationController = TextEditingController();
  final TextEditingController _preferredDateController = TextEditingController();
  final TextEditingController _preferredTimeController = TextEditingController();
  final TextEditingController _preferredPriestController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<Document> _documents = [];

  @override
  void initState() {
    super.initState();
    _showStatusButtons = !widget.fromStatusButton;
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    if (widget.funeralMassId == null || widget.funeralMassId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid booking ID')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication required')));
      return;
    }

    final result = await _funeralMassService.getFuneralMassBookingById(
      token: token,
      id: widget.funeralMassId!,
    );

    if (mounted && result.success && result.data != null) {
      final booking = result.data!;
      setState(() {
        _booking = booking;
        _deceasedNameController.text = booking.deceasedFullName ?? '';
        _dateOfDeathController.text = booking.dateOfDeath ?? '';
        _representativeNameController.text = booking.representativeName ?? '';
        _contactEmailController.text = booking.contactEmail ?? '';
        _contactPhoneController.text = booking.contactPhone ?? '';
        _wakeStartDateController.text = booking.wakeStartDate?.split('T')[0] ?? '';
        _wakeEndDateController.text = booking.wakeEndDate?.split('T')[0] ?? '';
        _wakeLocationController.text = booking.wakeLocation ?? '';
        _preferredDateController.text = booking.preferredDate?.split('T')[0] ?? '';
        _preferredTimeController.text = booking.preferredTimeSlot ?? '';
        _preferredPriestController.text = booking.preferredPriest ?? '';
        _notesController.text = booking.additionalNotes ?? '';
        _documents = booking.documents ?? [];
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to load booking')));
    }
  }

  Future<void> _pickDocumentFile() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result != null && mounted) {
      setState(() {
        _documentFile = XFile(result.path, name: result.name, mimeType: result.mimeType);
      });
    }
  }

  Future<void> _uploadDocument() async {
    if (_documentFile == null || widget.funeralMassId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    setState(() => _isUploading = true);

    final result = await _funeralMassService.attachDocumentToBooking(
      bookingId: widget.funeralMassId!,
      token: token,
      filePath: _documentFile!.path,
      documentType: 'other',
    );

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (result.success) {
      await _loadBooking();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded successfully')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Upload failed')));
      }
    }
  }

  /// Opens a document by launching its URL
  Future<void> _openDocument(Document document) async {
    if (document.fileUrl == null || document.fileUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document URL is not available')),
      );
      return;
    }

    try {
      final baseUri = Uri.parse(ApiConfig.baseUrl);
      final fileUri = baseUri.resolve(document.fileUrl!);

      final success = await launchUrl(
        fileUri,
        mode: LaunchMode.externalApplication,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open document. Please check if the file exists.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening document: $e')),
        );
      }
    }
  }

  bool _validateForm() {
    if (_deceasedNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deceased name is required')));
      return false;
    }
    if (_representativeNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Representative name is required')));
      return false;
    }
    if (_contactPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact phone is required')));
      return false;
    }
    if (_preferredDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferred date is required')));
      return false;
    }
    if (_preferredTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferred time slot is required')));
      return false;
    }
    return true;
  }

  Future<void> _saveChanges() async {
    if (!_validateForm()) return;

    if (widget.funeralMassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid booking ID')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication required')));
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final result = await _funeralMassService.updateFuneralMassBooking(
        token: token,
        id: widget.funeralMassId!,
        deceasedFullName: _deceasedNameController.text.trim(),
        dateOfDeath: _dateOfDeathController.text.trim().isEmpty ? null : _dateOfDeathController.text.trim(),
        representativeName: _representativeNameController.text.trim(),
        contactEmail: _contactEmailController.text.trim().isEmpty ? null : _contactEmailController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        wakeStartDate: _wakeStartDateController.text.trim().isEmpty ? null : _wakeStartDateController.text,
        wakeEndDate: _wakeEndDateController.text.trim().isEmpty ? null : _wakeEndDateController.text,
        wakeLocation: _wakeLocationController.text.trim().isEmpty ? null : _wakeLocationController.text.trim(),
        preferredDate: _preferredDateController.text,
        preferredTimeSlot: _preferredTimeController.text,
        preferredPriest: _preferredPriestController.text.trim().isEmpty ? null : _preferredPriestController.text.trim(),
        additionalNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSaving = false);

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking updated successfully')));
          _toggleEditMode();
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed')));
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
    if (widget.funeralMassId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication required')));
      return;
    }

    final result = await _funeralMassService.updateFuneralMassStatus(
      token: token,
      id: widget.funeralMassId!,
      status: status,
    );

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking marked as $status')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed')));
      }
    }
  }

  String get _displayStatus {
    if (_booking == null) return 'PENDING';
    final status = _booking!.status.toUpperCase();
    if (status == 'APPROVED') {
      final scheduledDate = _booking!.preferredDate;
      if (scheduledDate != null && scheduledDate.isNotEmpty) {
        try {
          final now = DateTime.now();
          final bookingDate = DateTime.parse(scheduledDate);
          final today = DateTime(now.year, now.month, now.day);
          final eventDate = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
          if (eventDate.isBefore(today)) {
            return 'COMPLETED';
          }
        } catch (e) {
          // ignore
        }
      }
    }
    return status;
  }

  bool get _canChangeStatus {
    if (_booking == null) return false;
    final status = _booking!.status.toLowerCase();
    if (status == 'pending') {
      return true;
    } else if (status == 'approved') {
      final scheduledDate = _booking!.preferredDate;
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

  String get _actionButtonText {
    if (_booking == null) return 'Approve';
    final status = _booking!.status.toLowerCase();
    if (status == 'pending') return 'Approve';
    if (status == 'approved') return 'Mark as Completed';
    return 'Approve';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.currentUser?.role;
    final isAdmin = ['parish_admin', 'parish_staff', 'diocese_admin', 'diocese_staff'].contains(role);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Funeral Mass Details"),
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
          else if (!_showStatusButtons && isAdmin)
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
            _buildSectionTitle('Deceased Information'),
            _textField('Deceased Full Name *', _deceasedNameController, enabled: _isEditMode),
            _textField('Date of Death', _dateOfDeathController, enabled: _isEditMode),

            _buildSectionTitle('Representative'),
            _textField('Representative Name *', _representativeNameController, enabled: _isEditMode),
            _textField('Contact Email', _contactEmailController, enabled: _isEditMode),
            _textField('Contact Phone *', _contactPhoneController, enabled: _isEditMode),

            _buildSectionTitle('Wake Details'),
            _textField('Wake Start Date', _wakeStartDateController, enabled: _isEditMode, readOnly: _isEditMode, onTap: _selectWakeStartDate),
            _textField('Wake End Date', _wakeEndDateController, enabled: _isEditMode, readOnly: _isEditMode, onTap: _selectWakeEndDate),
            _textField('Wake Location', _wakeLocationController, enabled: _isEditMode, maxLines: 2),

            _buildSectionTitle('Booking Details'),
            _textField("Parish", TextEditingController(text: _booking?.parishName ?? ''), enabled: false),
            _textField("Preferred Date *", _preferredDateController, enabled: _isEditMode, readOnly: _isEditMode, onTap: _selectDate),
            _textField("Time Slot *", _preferredTimeController, enabled: _isEditMode, readOnly: _isEditMode, onTap: _selectTime),
            _textField("Preferred Priest", _preferredPriestController, enabled: _isEditMode),
            _textField("Additional Notes", _notesController, maxLines: 3, enabled: _isEditMode),

            const SizedBox(height: 16),
            Text('Documents', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_documents.isNotEmpty) ...[
                  for (final doc in _documents)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(doc.documentType?.toUpperCase().replaceAll('_', ' ') ?? 'DOCUMENT'),
                        subtitle: Text(doc.fileName ?? 'File'),
                        trailing: doc.isVerified == true
                            ? Icon(Icons.check_circle, color: Colors.green[600])
                            : Icon(Icons.pending, color: Colors.orange),
                        onTap: () => _openDocument(doc),
                      ),
                    )
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('No documents uploaded', style: TextStyle(color: Colors.grey)),
                  )
                ],

                if (_isEditMode) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Select Document'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200]),
                    onPressed: _pickDocumentFile,
                  ),
                  if (_documentFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Text(_documentFile!.name),
                        const SizedBox(width: 8),
                        if (_isUploading)
                          const CircularProgressIndicator(strokeWidth: 2)
                        else
                          ElevatedButton.icon(
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text('Upload'),
                            onPressed: _uploadDocument,
                          ),
                      ]),
                    ),
                ],
              ]),
            )),

            _buildStatusSection(isAdmin, widget.funeralMassId ?? 0),
          ]),
        ),
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller, {bool enabled = true, bool readOnly = false, VoidCallback? onTap, int maxLines = 1}) {
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

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)));

  void _selectDate() async {
    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().add(const Duration(days: -7)), lastDate: DateTime.now().add(const Duration(days: 365 * 2)));
    if (picked != null) setState(() => _preferredDateController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
  }

  void _selectTime() async {
    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _preferredTimeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
  }

  void _selectWakeStartDate() async {
    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().add(const Duration(days: -30)), lastDate: DateTime.now().add(const Duration(days: 365 * 2)));
    if (picked != null) setState(() => _wakeStartDateController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
  }

  void _selectWakeEndDate() async {
    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().add(const Duration(days: -30)), lastDate: DateTime.now().add(const Duration(days: 365 * 2)));
    if (picked != null) setState(() => _wakeEndDateController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
  }

  Widget _buildStatusSection(bool isAdmin, int bookingId) {
    if (!isAdmin || _showStatusButtons) return const SizedBox.shrink();

    final displayStatus = _displayStatus;
    final canChangeStatus = _canChangeStatus;
    final actionButtonText = _actionButtonText;
    final status = _booking?.status.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Status',
          style: const TextStyle(
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
              SizedBox(
                width: 120,
                child: const Text(
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
  void dispose() {
    _deceasedNameController.dispose();
    _dateOfDeathController.dispose();
    _representativeNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _wakeStartDateController.dispose();
    _wakeEndDateController.dispose();
    _wakeLocationController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _preferredPriestController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
