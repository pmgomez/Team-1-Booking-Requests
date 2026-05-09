import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/document.dart';
import '../models/baptism_booking.dart';
import '../models/note.dart';
import '../providers/auth_provider.dart';
import '../providers/priest_provider.dart';
import '../providers/parish_provider.dart';
import '../services/baptism_service.dart';
import '../config/api_config.dart';
import 'document_preview_screen.dart';
import '../widgets/notes_display.dart';

Icon _getDocumentIcon(Document doc) {
  final filename = (doc.fileName ?? '').toLowerCase();
  if (filename.endsWith('.pdf')) {
    return const Icon(Icons.picture_as_pdf, color: Colors.red);
  } else if (filename.endsWith('.jpg') || filename.endsWith('.jpeg') || filename.endsWith('.png')) {
    return const Icon(Icons.image, color: Colors.blue);
  } else {
    return const Icon(Icons.insert_drive_file, color: Colors.grey);
  }
}

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
  bool _isProcessing = false; // For document operations

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
  final TextEditingController _newNoteController = TextEditingController();
  
  int? _selectedPriestId;
  
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
        if (booking.priestId != null) {
          _selectedPriestId = booking.priestId;
        }
        _documents = booking.documents ?? [];
        _birthCertificateFile = null;
      });
      
      // Debug: Print documents count
      print('=== BAPTISM DETAIL: Documents loaded: ${_documents.length} ===');
      for (var doc in _documents) {
        print('Document: id=${doc.id}, type=${doc.documentType}, fileName=${doc.fileName}, fileUrl=${doc.fileUrl}');
      }
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
      file: _birthCertificateFile!,
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

  /// Opens a document in the preview screen
  Future<void> _openDocument(Document document) async {
    if (document.fileUrl == null || document.fileUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document URL is not available')),
      );
      return;
    }

    // Navigate to document preview screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentPreviewScreen(document: document),
      ),
    );
  }

  Future<void> _deleteDocument(Document doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${doc.fileName ?? 'this document'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isProcessing = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not authenticated')));
      setState(() => _isProcessing = false);
      return;
    }

    final result = await _baptismService.deleteDocument(
      bookingId: widget.baptismId!,
      documentId: doc.id!,
    );

    setState(() => _isProcessing = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Document deleted')));
      await _loadBooking(); // Refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to delete document')));
    }
  }

  Future<void> _replaceDocument(Document doc) async {
    // Pick new file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) return;

    final newFile = result.files.first;
    setState(() => _isProcessing = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not authenticated')));
      setState(() => _isProcessing = false);
      return;
    }

    // Upload new document
    final uploadResult = await _baptismService.attachDocumentToBooking(
      bookingId: widget.baptismId!,
      token: token,
      file: newFile,
      documentType: doc.documentType,
    );

    if (uploadResult.success) {
      // Delete old document
      final deleteResult = await _baptismService.deleteDocument(
        bookingId: widget.baptismId!,
        documentId: doc.id!,
      );
      if (!deleteResult.success) {
        // Log but continue
        print('Failed to delete old document: ${deleteResult.message}');
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uploadResult.message ?? 'Document replaced')));
      await _loadBooking();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uploadResult.message ?? 'Failed to upload new document')));
    }

    setState(() => _isProcessing = false);
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
      // Prepare notes array if a new note was added
      List<Map<String, dynamic>>? notesToAdd;
      if (_newNoteController.text.trim().isNotEmpty) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        final isParishioner = currentUser?.role == 'parishioner';
        notesToAdd = [
          {
            'author': isParishioner ? 'parishioner' : 'admin',
            'content': _newNoteController.text.trim(),
            'authorId': currentUser?.id,
          }
        ];
      }

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
        priestId: _selectedPriestId,
        notes: notesToAdd,
      );

      print('Save result: ${result.success} - ${result.message}');

      if (mounted) {
        setState(() => _isSaving = false);
        
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking updated successfully')));
          _newNoteController.clear();
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
          if (_isEditMode)
            _buildPriestDropdown()
          else
            _textField("Preferred Priest", TextEditingController(text: _booking?.priestName ?? ''), enabled: false),

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
                        leading: _getDocumentIcon(doc),
                        title: Text(doc.documentType?.toUpperCase().replaceAll('_', ' ') ?? 'DOCUMENT'),
                        subtitle: Text(doc.fileName ?? 'File'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Verification status
                            if (doc.isVerified == true)
                              const Icon(Icons.check_circle, color: Colors.green, size: 20)
                            else if (doc.isVerified == false)
                              const Icon(Icons.pending, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            // Actions menu
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'view') _openDocument(doc);
                                if (value == 'delete') _deleteDocument(doc);
                                if (value == 'replace') _replaceDocument(doc);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'view', child: Text('View')),
                                if (isAdmin || isOwner)
                                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                if (isAdmin || isOwner)
                                  const PopupMenuItem(value: 'replace', child: Text('Replace')),
                              ],
                            ),
                          ],
                        ),
                        onTap: () => _openDocument(doc),
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),

          // Display existing notes in conversation format
          if (_booking?.notes != null && _booking!.notes!.isNotEmpty)
            NotesDisplay(notes: _booking!.notes!),

          // Add new note field (only in edit mode)
          if (_isEditMode) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('Add Note (Optional)'),
            _textField('Add a note', _newNoteController, maxLines: 3, enabled: true),
          ],

          const SizedBox(height: 20),
          if (status == 'declined' && isOwner) ...[
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your booking was declined. Please make the necessary changes and resubmit.',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.refresh),
                        label: Text(_isSaving ? 'Resubmitting...' : 'Resubmit Booking'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isSaving ? null : _resubmitBooking,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
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

  Future<void> _resubmitBooking() async {
    if (widget.baptismId == null) return;

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      final isParishioner = currentUser?.role == 'parishioner';

      List<Map<String, dynamic>>? notes;
      if (_newNoteController.text.trim().isNotEmpty) {
        notes = [{
          'author': isParishioner ? 'parishioner' : 'admin',
          'content': _newNoteController.text.trim(),
          'authorId': currentUser?.id,
        }];
      }

      final result = await _baptismService.resubmitBooking(
        id: widget.baptismId!,
        notes: notes,
      );

      if (mounted) {
        setState(() => _isSaving = false);

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking resubmitted successfully')));
          _newNoteController.clear();
          await _loadBooking();
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

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)));

  Widget _buildPriestDropdown() {
    return Consumer2<ParishProvider, PriestProvider>(
      builder: (context, parishProvider, priestProvider, _) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final parishId = _booking?.parishId ?? parishProvider.selectedParish?.id;
        if (parishId != null) {
          priestProvider.loadPriestsByParish(parishId, token: authProvider.token);
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<int>(
            value: _selectedPriestId,
            decoration: const InputDecoration(
              labelText: "Preferred Priest (Optional)",
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text("No preference"),
              ),
              ...priestProvider.priests.map((priest) => DropdownMenuItem<int>(
                value: priest.id,
                child: Text(priest.fullName),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPriestId = value;
              });
            },
          ),
        );
      },
    );
  }

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
    _newNoteController.dispose();
    super.dispose();
  }
}
