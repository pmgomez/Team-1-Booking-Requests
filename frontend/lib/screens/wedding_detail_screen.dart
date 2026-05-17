import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../providers/priest_provider.dart';
import '../providers/wedding_provider.dart';
import '../services/wedding_service.dart';
import '../services/file_service.dart';
import '../models/document.dart';
import '../models/wedding_booking.dart';
import '../models/note.dart';
import '../config/api_config.dart';
import '../widgets/notes_display.dart';

class WeddingDetailScreen extends StatefulWidget {
  final int? weddingId;
  final bool fromStatusButton;

  const WeddingDetailScreen({
    super.key,
    required this.weddingId,
    this.fromStatusButton = false,
  });

  @override
  State<WeddingDetailScreen> createState() => _WeddingDetailScreenState();
}

class _WeddingDetailScreenState extends State<WeddingDetailScreen> {
  final WeddingService _weddingService = WeddingService();
  final _formKey = GlobalKey<FormState>();

  bool _isEditMode = false;
  bool _isSaving = false;
  bool _showStatusButtons = true;
  bool _isLoading = true;

  WeddingBooking? _booking;

  // Controllers
  final TextEditingController _groomNameController = TextEditingController();
  final TextEditingController _brideNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _preferredDateController = TextEditingController();
  final TextEditingController _preferredTimeController = TextEditingController();
  final TextEditingController _seminarScheduleController = TextEditingController();
  int? _selectedPriestId;
  final TextEditingController _newNoteController = TextEditingController();

  // Document files and upload data
  PlatformFile? _cenomarFile;
  bool _isUploadingCenomar = false;
  Map<String, dynamic>? _uploadedCenomarData;

  PlatformFile? _birthCertificateFile;
  bool _isUploadingBirth = false;
  Map<String, dynamic>? _uploadedBirthData;

  PlatformFile? _baptismalCertificateFile;
  bool _isUploadingBaptismal = false;
  Map<String, dynamic>? _uploadedBaptismalData;

  PlatformFile? _confirmationCertificateFile;
  bool _isUploadingConfirmation = false;
  Map<String, dynamic>? _uploadedConfirmationData;

  List<Document> _documents = [];

  Future<void> _updateBookingStatus(String status) async {
    if (widget.weddingId == null) return;

    final result = await _weddingService.updateWeddingStatus(
      token: Provider.of<AuthProvider>(context, listen: false).token!,
      id: widget.weddingId!,
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

  String get _displayBookingStatus {
    if (_booking == null) return 'PENDING';
    final status = (_booking?.status?.toUpperCase() ?? 'PENDING');
    if (status == 'APPROVED') {
      final scheduledDate = _booking?.preferredDate;
      if (scheduledDate != null && scheduledDate.isNotEmpty) {
        try {
          final now = DateTime.now();
          final bookingDate = DateTime.parse(scheduledDate);
          final today = DateTime(now.year, now.month, now.day);
          final eventDate = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
          if (eventDate.isBefore(today)) {
            return 'COMPLETED';
          }
        } catch (e) {}
      }
    }
    return status;
  }

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

  String get _actionButtonText {
    if (_booking == null) return 'Approve';
    final status = _booking!.status?.toLowerCase();
    if (status == 'pending') return 'Approve';
    if (status == 'approved') return 'Mark as Completed';
    return 'Approve';
  }

  Widget _buildStatusSection(bool isAdmin) {
    if (!isAdmin || _showStatusButtons) return const SizedBox.shrink();

    final displayStatus = _displayBookingStatus;
    final canChangeStatus = _canChangeStatus;
    final actionButtonText = _actionButtonText;
    final status = _booking?.status?.toLowerCase();

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
                  onPressed: () => _updateBookingStatus('approved'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Decline'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => _updateBookingStatus('declined'),
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
                  onPressed: canChangeStatus ? () => _updateBookingStatus('completed') : null,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showStatusButtons = !widget.fromStatusButton;
      _loadBooking();
    });
  }

  @override
  void dispose() {
    _groomNameController.dispose();
    _brideNameController.dispose();
    _contactController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _seminarScheduleController.dispose();
    _newNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    if (widget.weddingId == null || widget.weddingId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid booking ID')),
        );
        Navigator.pop(context);
      }
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to view booking')),
        );
        Navigator.pop(context);
      }
      return;
    }

    final result = await _weddingService.getWeddingBookingById(
      token: token,
      id: widget.weddingId!,
    );

    if (mounted && result.success && result.data != null) {
      final booking = result.data!;
      setState(() {
        _booking = booking;
        _groomNameController.text = booking.groomFullName ?? '';
        _brideNameController.text = booking.brideFullName ?? '';
        _contactController.text = booking.contactEmail ?? '';
        _preferredDateController.text = booking.preferredDate?.split('T')[0] ?? '';
        _preferredTimeController.text = booking.preferredTimeSlot ?? '';
        _seminarScheduleController.text = booking.seminarSchedule ?? '';
        if (booking.priestId != null) {
          _selectedPriestId = booking.priestId;
          // Load priests for dropdown
          final priestProvider = Provider.of<PriestProvider>(context, listen: false);
          final parishProvider = Provider.of<ParishProvider>(context, listen: false);
          if (parishProvider.selectedParish != null) {
            priestProvider.loadPriestsByParish(parishProvider.selectedParish!.id!, token: token);
          }
        }
        _documents = booking.documents ?? [];
        _isLoading = false;
      });

      // Auto-enable edit mode if fromStatusButton (with editable status) or user is owner and booking is editable
      final currentUser = authProvider.currentUser;
      final isOwner = booking.userId == currentUser?.id;
      final status = booking.status?.toLowerCase() ?? 'pending';
      final isEditable = status == 'pending' || status == 'declined';
      if (widget.fromStatusButton && isEditable) {
        setState(() => _isEditMode = true);
      } else if (!widget.fromStatusButton && isOwner && isEditable) {
        setState(() => _isEditMode = true);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Failed to load booking')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickCenomar() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
        allowMultiple: false,
      );
      if (result != null && mounted) {
        setState(() {
          _cenomarFile = result.files.first;
          _uploadedCenomarData = null;
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

  Future<void> _uploadCenomar() async {
    if (_cenomarFile == null || widget.weddingId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    setState(() => _isUploadingCenomar = true);

    try {
      final fileService = FileService();
      final response = await fileService.uploadFile(
        file: _cenomarFile!,
        token: token,
        category: 'wedding',
        additionalFields: {
          'documentType': 'cenomar',
        },
      );

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _uploadedCenomarData = response.data!['file'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CENOMAR uploaded successfully')),
          );
          await _loadBooking(); // Reload to show updated documents
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Upload failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingCenomar = false);
      }
    }
  }

  Future<void> _pickBirthCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
        allowMultiple: false,
      );
      if (result != null && mounted) {
        setState(() {
          _birthCertificateFile = result.files.first;
          _uploadedBirthData = null;
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
    if (_birthCertificateFile == null || widget.weddingId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    setState(() => _isUploadingBirth = true);

    try {
      final fileService = FileService();
      final response = await fileService.uploadFile(
        file: _birthCertificateFile!,
        token: token,
        category: 'wedding',
        additionalFields: {
          'documentType': 'birth_certificate',
        },
      );

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _uploadedBirthData = response.data!['file'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Birth certificate uploaded successfully')),
          );
          await _loadBooking();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Upload failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingBirth = false);
      }
    }
  }

  Future<void> _pickBaptismalCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
        allowMultiple: false,
      );
      if (result != null && mounted) {
        setState(() {
          _baptismalCertificateFile = result.files.first;
          _uploadedBaptismalData = null;
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

  Future<void> _uploadBaptismalCertificate() async {
    if (_baptismalCertificateFile == null || widget.weddingId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    setState(() => _isUploadingBaptismal = true);

    try {
      final fileService = FileService();
      final response = await fileService.uploadFile(
        file: _baptismalCertificateFile!,
        token: token,
        category: 'wedding',
        additionalFields: {
          'documentType': 'baptismal_certificate',
        },
      );

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _uploadedBaptismalData = response.data!['file'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Baptismal certificate uploaded successfully')),
          );
          await _loadBooking();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Upload failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingBaptismal = false);
      }
    }
  }

  Future<void> _pickConfirmationCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
        allowMultiple: false,
      );
      if (result != null && mounted) {
        setState(() {
          _confirmationCertificateFile = result.files.first;
          _uploadedConfirmationData = null;
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

  Future<void> _uploadConfirmationCertificate() async {
    if (_confirmationCertificateFile == null || widget.weddingId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    setState(() => _isUploadingConfirmation = true);

    try {
      final fileService = FileService();
      final response = await fileService.uploadFile(
        file: _confirmationCertificateFile!,
        token: token,
        category: 'wedding',
        additionalFields: {
          'documentType': 'confirmation_certificate',
        },
      );

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _uploadedConfirmationData = response.data!['file'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Confirmation certificate uploaded successfully')),
          );
          await _loadBooking();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Upload failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingConfirmation = false);
      }
    }
  }

  Future<void> _saveBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to update booking')),
        );
      }
      setState(() => _isSaving = false);
      return;
    }

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

    final result = await _weddingService.updateWeddingBooking(
      token: token,
      id: widget.weddingId!,
      groomFullName: _groomNameController.text.trim(),
      brideFullName: _brideNameController.text.trim(),
      contactEmail: _contactController.text.trim(),
      preferredDate: _preferredDateController.text.trim(),
      preferredTimeSlot: _preferredTimeController.text.trim(),
      seminarSchedule: _seminarScheduleController.text.trim().isEmpty
          ? null
          : _seminarScheduleController.text.trim(),
      priestId: _selectedPriestId,
      notes: notesToAdd,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Booking updated successfully')),
        );
        _newNoteController.clear();
        setState(() => _isEditMode = false);
        await _loadBooking(); // Reload to show updated data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to update booking')),
        );
      }
    }
  }

  Future<void> _resubmitBooking() async {
    if (widget.weddingId == null) return;

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not authenticated')));
        setState(() => _isSaving = false);
        return;
      }

      final result = await _weddingService.resubmitBooking(
        id: widget.weddingId!,
        token: token,
      );

      if (mounted) {
        setState(() => _isSaving = false);

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking resubmitted successfully')));
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

  Future<void> _deleteBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to delete booking')),
        );
      }
      setState(() => _isSaving = false);
      return;
    }

    final result = await _weddingService.deleteWeddingBooking(
      token: token,
      id: widget.weddingId!,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to cancel booking')),
        );
      }
    }
  }

  void _openDocument(Document document) {
    if (document.fileUrl == null || document.fileUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document URL is not available')),
      );
      return;
    }

    try {
      final baseUri = Uri.parse(ApiConfig.baseUrl);
      final fileUri = baseUri.resolve(document.fileUrl!);

      launchUrl(
        fileUri,
        mode: LaunchMode.externalApplication,
      ).then((success) {
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to open document. Please check if the file exists.')),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening document: $e')),
        );
      }
    }
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
  );

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final role = currentUser?.role;
    final isAdmin = ['parish_admin', 'parish_staff', 'diocese_admin', 'diocese_staff'].contains(role);
    final isOwner = _booking?.userId == currentUser?.id;
    final status = _booking?.status?.toLowerCase();
    final canEdit = isAdmin || (isOwner && (status == 'pending' || status == 'declined'));
    final effectiveStatus = _displayBookingStatus.toLowerCase();
    final canDelete = isAdmin || (isOwner && effectiveStatus != 'approved');

    return Scaffold(
      appBar: AppBar(
        title: Text(_booking != null
            ? 'Wedding #${_booking!.id}'
            : 'Wedding Details'),
        actions: [
          if (_booking != null && !_isEditMode && _showStatusButtons && canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditMode = true),
              tooltip: 'Edit',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
              ? const Center(child: Text('Booking not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Status',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                                _booking!.status?.toLowerCase() ??
                                                    'pending')
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _displayBookingStatus,
                                        style: TextStyle(
                                          color: _getStatusColor(
                                              _displayBookingStatus.toLowerCase()),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (!_showStatusButtons && isAdmin)
                                  Row(
                                    children: [
                                      if (_booking!.status?.toLowerCase() ==
                                          'pending')
                                        ElevatedButton(
                                          onPressed: () => _updateBookingStatus(
                                              'declined'),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red),
                                          child: const Text('Decline'),
                                        ),
                                      if (_booking!.status?.toLowerCase() ==
                                          'pending')
                                        const SizedBox(width: 8),
                                      if (_booking!.status?.toLowerCase() ==
                                          'pending')
                                        ElevatedButton(
                                          onPressed: () =>
                                              _updateBookingStatus('approved'),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green),
                                          child: const Text('Approve'),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
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
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Resubmit Booking'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: _resubmitBooking,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Groom Name
                        if (_isEditMode)
                          TextFormField(
                            controller: _groomNameController,
                            decoration: const InputDecoration(
                              labelText: 'Groom Full Name *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Groom name is required';
                              }
                              return null;
                            },
                          )
                        else
                          _buildInfoRow('Groom Name',
                              _booking!.groomFullName ?? 'Not provided'),
                        const SizedBox(height: 16),

                        // Bride Name
                        if (_isEditMode)
                          TextFormField(
                            controller: _brideNameController,
                            decoration: const InputDecoration(
                              labelText: 'Bride Full Name *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Bride name is required';
                              }
                              return null;
                            },
                          )
                        else
                          _buildInfoRow('Bride Name',
                              _booking!.brideFullName ?? 'Not provided'),
                        const SizedBox(height: 16),

                        // Contact Email
                        if (_isEditMode)
                          TextFormField(
                            controller: _contactController,
                            decoration: const InputDecoration(
                              labelText: 'Contact Email *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Contact email is required';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          )
                        else
                          _buildInfoRow('Contact Email',
                              _booking!.contactEmail ?? 'Not provided'),
                        const SizedBox(height: 16),

                        // Contact Phone
                        if (_isEditMode)
                          TextFormField(
                            controller: _contactController,
                            decoration: const InputDecoration(
                              labelText: 'Contact Phone *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Contact phone is required';
                              }
                              return null;
                            },
                          )
                        else
                          _buildInfoRow('Contact Phone',
                              _booking!.contactPhone ?? 'Not provided'),
                        const SizedBox(height: 16),

                        // Preferred Date
                        if (_isEditMode)
                          TextFormField(
                            controller: _preferredDateController,
                            decoration: const InputDecoration(
                              labelText: 'Preferred Date *',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            readOnly: true,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(
                                    const Duration(days: 7)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                    const Duration(days: 365)),
                              );
                              if (date != null) {
                                _preferredDateController.text =
                                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                              }
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Preferred date is required';
                              }
                              return null;
                            },
                          )
                        else
                          _buildInfoRow('Preferred Date',
                              _booking!.preferredDate ?? 'Not provided'),
                        const SizedBox(height: 16),

                        // Preferred Time
                        if (_isEditMode)
                          TextFormField(
                            controller: _preferredTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Preferred Time *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Preferred time is required';
                              }
                              return null;
                            },
                          )
                        else
                          _buildInfoRow('Preferred Time',
                              _booking!.preferredTimeSlot ?? 'Not provided'),
                        const SizedBox(height: 16),

                        // Seminar Schedule
                        if (_isEditMode)
                          TextFormField(
                            controller: _seminarScheduleController,
                            decoration: const InputDecoration(
                              labelText: 'Seminar Schedule',
                              border: OutlineInputBorder(),
                            ),
                          )
                        else
                          _buildInfoRow('Seminar Schedule',
                              _booking!.seminarSchedule ?? 'Not provided'),
                        const SizedBox(height: 16),

                        // Preferred Priest dropdown
                        Consumer<PriestProvider>(
                          builder: (context, priestProvider, child) {
                            if (priestProvider.priests.isEmpty && _booking != null) {
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              final parishProvider = Provider.of<ParishProvider>(context, listen: false);
                              if (parishProvider.selectedParish != null && authProvider.token != null) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  priestProvider.loadPriestsByParish(parishProvider.selectedParish!.id!, token: authProvider.token);
                                });
                              }
                            }
                            final validPriestId = _selectedPriestId != null && 
                                priestProvider.priests.any((p) => p.id == _selectedPriestId) 
                                ? _selectedPriestId : null;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DropdownButtonFormField<int>(
                                value: validPriestId,
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
                                onChanged: _isEditMode ? (value) {
                                  setState(() {
                                    _selectedPriestId = value;
                                  });
                                } : null,
                              ),
                            );
                          },
                        ),

                        // Notes display
                        _buildSectionTitle('Notes'),
                        if (_booking?.notes != null && _booking!.notes!.isNotEmpty)
                          NotesDisplay(
                            notes: _booking!.notes!.map((note) {
                              if (note is Map) {
                                return Note.fromJson(Map<String, dynamic>.from(note));
                              }
                              return note as Note;
                            }).toList(),
                          ),
                        if (_isEditMode) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _newNoteController,
                            decoration: const InputDecoration(
                              labelText: "Add a note",
                              border: OutlineInputBorder(),
                              hintText: "Enter your note here...",
                            ),
                            maxLines: 2,
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Documents Section
                        const Text(
                          'Required Documents',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // CENOMAR
                        _buildDocumentSection(
                          label: 'CENOMAR',
                          file: _cenomarFile,
                          uploadedData: _uploadedCenomarData,
                          documents: _documents
                              .where((d) => d.documentType == 'cenomar')
                              .toList(),
                          isUploading: _isUploadingCenomar,
                          onPick: _pickCenomar,
                          onUpload: _uploadCenomar,
                          canEdit: _isEditMode,
                        ),
                        const SizedBox(height: 12),

                        // Birth Certificate
                        _buildDocumentSection(
                          label: 'Birth Certificate',
                          file: _birthCertificateFile,
                          uploadedData: _uploadedBirthData,
                          documents: _documents
                              .where((d) => d.documentType == 'birth_certificate')
                              .toList(),
                          isUploading: _isUploadingBirth,
                          onPick: _pickBirthCertificate,
                          onUpload: _uploadBirthCertificate,
                          canEdit: _isEditMode,
                        ),
                        const SizedBox(height: 12),

                        // Baptismal Certificate
                        _buildDocumentSection(
                          label: 'Baptismal Certificate',
                          file: _baptismalCertificateFile,
                          uploadedData: _uploadedBaptismalData,
                          documents: _documents
                              .where((d) =>
                                  d.documentType == 'baptismal_certificate')
                              .toList(),
                          isUploading: _isUploadingBaptismal,
                          onPick: _pickBaptismalCertificate,
                          onUpload: _uploadBaptismalCertificate,
                          canEdit: _isEditMode,
                        ),
                        const SizedBox(height: 12),

                        // Confirmation Certificate
                        _buildDocumentSection(
                          label: 'Confirmation Certificate',
                          file: _confirmationCertificateFile,
                          uploadedData: _uploadedConfirmationData,
                          documents: _documents
                              .where((d) =>
                                  d.documentType == 'confirmation_certificate')
                              .toList(),
                          isUploading: _isUploadingConfirmation,
                          onPick: _pickConfirmationCertificate,
                          onUpload: _uploadConfirmationCertificate,
                          canEdit: _isEditMode,
                        ),
                        const SizedBox(height: 32),

                        // Save/Cancel Buttons
                        if (_isEditMode)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveBooking,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Save Changes'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () => setState(() => _isEditMode = false),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                            ],
                          ),

                        // Delete Button (owners can delete any non-approved booking)
                        if (_isEditMode &&
                            _booking != null &&
                            canDelete)
                          const SizedBox(height: 16),
                        if (_isEditMode &&
                            _booking != null &&
                            canDelete)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _isSaving ? null : _deleteBooking,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                              ),
                              child: const Text('Cancel Booking'),
                            ),
                          ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildDocumentSection({
    required String label,
    required PlatformFile? file,
    required Map<String, dynamic>? uploadedData,
    required List<Document> documents,
    required bool isUploading,
    required VoidCallback onPick,
    required VoidCallback onUpload,
    required bool canEdit,
  }) {
    final hasUploaded = uploadedData != null;
    final hasExisting = documents.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasExisting)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Uploaded',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Show existing document
            if (hasExisting)
              ...documents.map((doc) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.description,
                        color: Colors.green, size: 20),
                    title: Text(
                      doc.originalFilename ?? 'Document',
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new, size: 20),
                      onPressed: () => _openDocument(doc),
                      tooltip: 'Open',
                    ),
                  )),

            // Show newly picked file
            if (file != null && !hasUploaded)
              ListTile(
                dense: true,
                leading: const Icon(Icons.attach_file, size: 20),
                title: Text(
                  file.name,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  '${(file.size / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

            // Show newly uploaded
            if (hasUploaded)
              ListTile(
                dense: true,
                leading: const Icon(Icons.check_circle,
                    color: Colors.green, size: 20),
                title: Text(
                  uploadedData?['originalFilename'] ?? 'Uploaded',
                  style: const TextStyle(fontSize: 14),
                ),
              ),

            if (canEdit) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isUploading ? null : onPick,
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: const Text('Select File'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (file != null && !isUploading)
                          ? onUpload
                          : (hasExisting || hasUploaded)
                              ? null
                              : onPick,
                      icon: isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload, size: 18),
                      label: Text(isUploading ? 'Uploading...' : 'Upload'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'declined':
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
}
