import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/document.dart';
import '../models/baptism_booking.dart';
import '../providers/auth_provider.dart';
import '../services/baptism_service.dart';
import '../config/api_config.dart';

class BaptismDetailScreen extends StatefulWidget {
  final int? baptismId;
  final bool fromStatusButton;

  const BaptismDetailScreen({
    super.key,
    required this.baptismId,
    this.fromStatusButton = false,
  });

  @override
  State<BaptismDetailScreen> createState() => _BaptismDetailScreenState();
}

class _BaptismDetailScreenState extends State<BaptismDetailScreen> {
  final BaptismService _baptismService = BaptismService();
  PlatformFile? _birthCertificateFile;
  bool _isUploading = false;

  bool _isEditMode = false;
  bool _isSaving = false;
  bool _showStatusButtons = true;

  BaptismBooking? _booking;

  final TextEditingController _childNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
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
    if (widget.baptismId == null || widget.baptismId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid booking ID')));
      return;
    }

    final result = await _baptismService.getBaptismBookingById(id: widget.baptismId!);
    if (mounted && result.success && result.data != null) {
      final booking = result.data!;
      final status = booking.status?.toLowerCase() ?? 'pending';
      final isEditable = status == 'pending' || status == 'declined';
      setState(() {
        _booking = booking;
        _childNameController.text = booking.childFullName ?? '';
        _dobController.text = booking.dateOfBirth ?? '';
        _fatherNameController.text = booking.fatherName ?? '';
        _motherNameController.text = booking.motherName ?? '';
        _contactEmailController.text = booking.contactEmail ?? '';
        _contactPhoneController.text = booking.contactPhone ?? '';
        _preferredDateController.text = booking.preferredDate?.split('T')[0] ?? '';
        _preferredTimeController.text = booking.preferredTimeSlot ?? '';
        _preferredPriestController.text = booking.preferredPriest ?? '';
        _notesController.text = booking.additionalNotes ?? '';
        _documents = booking.documents ?? [];
        _birthCertificateFile = null;
      });
      if (widget.fromStatusButton && isEditable) {
        setState(() => _isEditMode = true);
      } else {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        final isOwner = booking.userId == currentUser?.id;
        if (!widget.fromStatusButton && isOwner && isEditable) {
          setState(() => _isEditMode = true);
        }
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to load booking')));
    }
  }

  Future<void> _pickBirthCertificateFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _birthCertificateFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: $e')),
        );
      }
    }
  }

  Future<void> _uploadBirthCertificate() async {
    if (_birthCertificateFile == null || widget.baptismId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file first')),
      );
      return;
    }

    final filePath = _birthCertificateFile!.path;
    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get file path. Please try a different file.')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to upload files')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final result = await _baptismService.attachDocumentToBooking(
      bookingId: widget.baptismId!,
      token: token,
      filePath: filePath,
      documentType: 'birth_certificate',
    );

    setState(() => _isUploading = false);

    if (mounted) {
      if (result.success) {
        await _loadBooking();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Birth certificate uploaded successfully')));
      } else {
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
      // Construct full URL by resolving relative path against base URL
      // The fileUrl stored is like: /uploads/documents/{userId}/baptism/{filename}
      final baseUri = Uri.parse(ApiConfig.baseUrl);
      final fileUri = baseUri.resolve(document.fileUrl!);

      // Launch the URL using external application (browser or file viewer)
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
    if (_childNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Child\'s name is required')));
      return false;
    }
    if (_dobController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Date of birth is required')));
      return false;
    }
    if (_fatherNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Father\'s name is required')));
      return false;
    }
    if (_motherNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mother\'s name is required')));
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
    print('=== SAVE BUTTON CLICKED ===');
    
    if (!_validateForm()) {
      print('Validation failed');
      return;
    }

    if (widget.baptismId == null) {
      print('No baptism ID');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid booking ID')));
      return;
    }

    print('Starting save...');
    setState(() => _isSaving = true);

    try {
      final result = await _baptismService.updateBaptismBooking(
        id: widget.baptismId!,
        childFullName: _childNameController.text.trim(),
        dateOfBirth: _dobController.text,
        fatherName: _fatherNameController.text.trim(),
        motherName: _motherNameController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        preferredDate: _preferredDateController.text,
        preferredTimeSlot: _preferredTimeController.text,
        preferredPriest: _preferredPriestController.text.trim().isEmpty ? null : _preferredPriestController.text.trim(),
        additionalNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      print('Save result: ${result.success} - ${result.message}');

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
      print('Error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _showStatusButtons = true;
        _birthCertificateFile = null;
      }
    });
  }

  void _updateStatus(String status) async {
    if (widget.baptismId == null) return;

    final result = await _baptismService.updateBaptismStatus(id: widget.baptismId!, status: status);

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking marked as $status')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed')));
      }
    }
  }

  /// Computes the display status based on current status and scheduled date
  String get _displayStatus {
    if (_booking == null) return 'PENDING';
    final status = (_booking?.status?.toUpperCase() ?? 'PENDING');
    if (status == 'APPROVED') {
      final scheduledDate = _booking?.preferredDate;
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
    if (_booking == null) return false;
    final status = _booking!.status?.toLowerCase();
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

  /// Returns the appropriate action button text based on status
  String get _actionButtonText {
    if (_booking == null) return 'Approve';
    final status = _booking!.status?.toLowerCase();
    if (status == 'pending') return 'Approve';
    if (status == 'approved') return 'Mark as Completed';
    return 'Approve';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final role = currentUser?.role;
    final isAdmin = ['parish_admin', 'parish_staff', 'diocese_admin', 'diocese_staff'].contains(role);
    final isOwner = _booking?.userId == currentUser?.id;
    final status = _booking?.status?.toLowerCase();
    final canEdit = isAdmin || (isOwner && (status == 'pending' || status == 'declined'));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Baptism Details"),
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
          _buildSectionTitle('Child Information'),
          _textField('Child\'s Full Name *', _childNameController, enabled: _isEditMode),
          _textField('Date of Birth *', _dobController, enabled: _isEditMode, readOnly: _isEditMode, onTap: _selectDob),
          
          _buildSectionTitle('Parents'),
          Row(children: [
            Expanded(child: _textField("Father's Name *", _fatherNameController, enabled: _isEditMode)),
            const SizedBox(width: 12),
            Expanded(child: _textField("Mother's Name *", _motherNameController, enabled: _isEditMode)),
          ]),
          _textField("Contact Email", _contactEmailController, enabled: _isEditMode),
          _textField("Contact Phone *", _contactPhoneController, enabled: _isEditMode),
          
          _buildSectionTitle('Booking Details'),
          _textField("Parish", TextEditingController(text: _booking?.parishName ?? ''), enabled: false),
          _textField("Preferred Date *", _preferredDateController, enabled: _isEditMode, readOnly: _isEditMode, onTap: _selectDate),
          _textField("Time Slot *", _preferredTimeController, enabled: _isEditMode, readOnly: _isEditMode, onTap: _selectTime),
          _textField("Preferred Priest", _preferredPriestController, enabled: _isEditMode),
          _textField("Additional Notes", _notesController, maxLines: 3, enabled: _isEditMode),

          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "PSA Birth Certificate *",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Please upload a copy of the PSA birth certificate. Accepted formats: PDF, JPG, PNG",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _pickBirthCertificateFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      _birthCertificateFile != null
                          ? 'File Selected: ${_birthCertificateFile!.name}'
                          : 'Select Birth Certificate File',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _birthCertificateFile != null
                          ? Colors.green[100]
                          : Colors.grey[200],
                      foregroundColor: Colors.black87,
                    ),
                  ),
                  if (_birthCertificateFile != null) ...[
                    const SizedBox(height: 12),
                    _isUploading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Uploading...'),
                            ],
                          )
                        : ElevatedButton.icon(
                            onPressed: _isUploading ? null : _uploadBirthCertificate,
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text('Upload Birth Certificate'),
                          ),
                  ],
                  const SizedBox(height: 16),
                  if (_documents.isNotEmpty) ...[
                    const Text(
                      'Uploaded Documents',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ..._documents.map((doc) => Padding(
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
                    )),
                  ],
                ],
              ),
            ),
          ),

          _buildStatusSection(isAdmin, widget.baptismId ?? 0),
        ]),
      ),
    ));
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

  void _selectDob() async {
    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1950), lastDate: DateTime.now());
    if (picked != null) setState(() => _dobController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
  }

  void _selectDate() async {
    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().add(const Duration(days: -7)), lastDate: DateTime.now().add(const Duration(days: 365 * 2)));
    if (picked != null) setState(() => _preferredDateController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
  }

  void _selectTime() async {
    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _preferredTimeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
  }

  Widget _buildStatusSection(bool isAdmin, int bookingId) {
    if (!isAdmin || _showStatusButtons) return const SizedBox.shrink();

    final displayStatus = _displayStatus;
    final canChangeStatus = _canChangeStatus;
    final actionButtonText = _actionButtonText;
    final status = _booking?.status?.toLowerCase();

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
    _childNameController.dispose();
    _dobController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _preferredPriestController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
