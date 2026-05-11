import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/auth_provider.dart';
import '../providers/eucharist_provider.dart';
import '../providers/parish_provider.dart';
import '../providers/priest_provider.dart';
import '../services/file_service.dart';

class EucharistScreen extends StatefulWidget {
  const EucharistScreen({super.key});

  @override
  State<EucharistScreen> createState() => _EucharistScreenState();
}

class _EucharistScreenState extends State<EucharistScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _communicantNameController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _preferredDateController = TextEditingController();
  final TextEditingController _preferredTimeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Priest selection state
  int? _selectedPriestId;

  // Document files and upload data
  PlatformFile? _birthCertificateFile;
  bool _isUploadingBirth = false;
  Map<String, dynamic>? _uploadedBirthData;

  PlatformFile? _baptismalCertificateFile;
  bool _isUploadingBaptismal = false;
  Map<String, dynamic>? _uploadedBaptismalData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final parishProvider = Provider.of<ParishProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final priestProvider = Provider.of<PriestProvider>(context, listen: false);

      parishProvider.loadAllParishes();

      // Default to user's preferred parish if available
      if (authProvider.currentUser?.preferredParishId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final userParishId = authProvider.currentUser!.preferredParishId;
          final userParish = parishProvider.parishes
              .where((p) => p.id == userParishId)
              .firstOrNull;
          if (userParish != null) {
            parishProvider.selectParish(userParish);
            if (userParishId != null) {
              priestProvider.loadPriestsByParish(userParishId, token: authProvider.token);
            }
          }
        });
      }

      // Set default contact email to current user's email
      if (authProvider.currentUser?.email != null) {
        _contactEmailController.text = authProvider.currentUser!.email;
      }
    });
  }

  @override
  void dispose() {
    _communicantNameController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Birth Certificate
  Future<void> _pickBirthCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
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
    if (_birthCertificateFile == null) {
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

    setState(() => _isUploadingBirth = true);

    try {
      final fileService = FileService();
      final response = await fileService.uploadFile(
        file: _birthCertificateFile!,
        token: token,
        category: 'eucharist',
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

  // Baptismal Certificate
  Future<void> _pickBaptismalCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
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
    if (_baptismalCertificateFile == null) {
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

    setState(() => _isUploadingBaptismal = true);

    try {
      final fileService = FileService();
      final response = await fileService.uploadFile(
        file: _baptismalCertificateFile!,
        token: token,
        category: 'eucharist',
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final eucharistProvider = Provider.of<EucharistProvider>(context, listen: false);
      final parishProvider = Provider.of<ParishProvider>(context, listen: false);
      final priestProvider = Provider.of<PriestProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to submit a booking.")),
        );
        return;
      }

      if (parishProvider.selectedParish == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a parish.")),
        );
        return;
      }

      final token = authProvider.token;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication token not available.")),
        );
        return;
      }

      // Validate required documents are uploaded
      if (_uploadedBirthData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload the required Birth Certificate.")),
        );
        return;
      }
      if (_uploadedBaptismalData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload the required Baptismal Certificate.")),
        );
        return;
      }

      // Build documents array
      final documents = [
        {
          'uploadedFile': _uploadedBirthData!['filename'],
          'filePath': _uploadedBirthData!['path'],
          'fileUrl': _uploadedBirthData!['url'],
          'fileSize': _uploadedBirthData!['size'],
          'mimeType': _uploadedBirthData!['mimeType'],
          'documentType': 'birth_certificate',
        },
        {
          'uploadedFile': _uploadedBaptismalData!['filename'],
          'filePath': _uploadedBaptismalData!['path'],
          'fileUrl': _uploadedBaptismalData!['url'],
          'fileSize': _uploadedBaptismalData!['size'],
          'mimeType': _uploadedBaptismalData!['mimeType'],
          'documentType': 'baptismal_certificate',
        },
      ];

      // Format dates to ISO format (YYYY-MM-DD)
      String formatDate(String date) {
        final parts = date.split('-');
        if (parts.length == 3) {
          return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
        }
        return date;
      }

      // Prepare notes array if a note was added
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

      final success = await eucharistProvider.createEucharistBooking(
        token: token,
        parishId: parishProvider.selectedParish!.id!,
        communicantName: _communicantNameController.text.trim(),
        fatherName: _fatherNameController.text.trim(),
        motherName: _motherNameController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        preferredDate: formatDate(_preferredDateController.text),
        preferredTimeSlot: _preferredTimeController.text.trim(),
        priestId: _selectedPriestId,
        notes: notesToAdd,
        documents: documents,
      );

      if (success && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Booking Submitted"),
            content: const Text(
                "Your First Holy Communion booking request has been submitted. Parish will confirm availability."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to home
                },
                child: const Text("OK"),
              )
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(eucharistProvider.errorMessage ?? "Failed to submit booking.")),
        );
      }
    }
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
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
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUploadSection({
    required String title,
    required String description,
    required PlatformFile? file,
    required bool isUploading,
    required Map<String, dynamic>? uploadedData,
    required VoidCallback onPick,
    required VoidCallback onUpload,
  }) {
    return _buildSection(
      title: title,
      children: [
        Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: isUploading ? null : onPick,
          icon: const Icon(Icons.attach_file),
          label: const Text("Select Document"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200]),
        ),
        if (file != null) ...[
          const SizedBox(height: 8),
          Text("Selected: ${file.name}", style: const TextStyle(color: Colors.blue)),
        ],
        if (uploadedData != null) ...[
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              SizedBox(width: 4),
              Text("Uploaded", style: TextStyle(color: Colors.green)),
            ],
          ),
        ],
        if (!isUploading && file != null && uploadedData == null) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.cloud_upload),
            label: const Text("Upload"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          ),
        ],
        if (isUploading) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("First Holy Communion"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Back to Home
          },
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Fill out the form below to submit your booking request. All fields marked with * are required.",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 5),
              const Text(
                "Subject to availability. Parish will confirm your booking.",
                style: TextStyle(
                    fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Communicant Information Section
              _buildSection(title: "Communicant Information", children: [
                TextFormField(
                  controller: _communicantNameController,
                  decoration: const InputDecoration(
                    labelText: "Child's Full Name *",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Required" : null,
                ),
              ]),

              // Parents Information Section
              _buildSection(title: "Parents Information", children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _fatherNameController,
                        decoration: const InputDecoration(
                          labelText: "Father's Name *",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? "Required" : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _motherNameController,
                        decoration: const InputDecoration(
                          labelText: "Mother's Name *",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? "Required" : null,
                      ),
                    ),
                  ],
                ),
              ]),

              // Contact Information Section
              _buildSection(title: "Contact Information", children: [
                TextFormField(
                  controller: _contactEmailController,
                  decoration: const InputDecoration(
                    labelText: "Contact Email *",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value == null || value.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactPhoneController,
                  decoration: const InputDecoration(
                    labelText: "Contact Phone *",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value == null || value.isEmpty ? "Required" : null,
                ),
              ]),

              // Booking Preferences
              _buildSection(title: "Booking Preferences", children: [
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
                      },
                      validator: (value) =>
                          value == null ? "Please select a parish" : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _preferredDateController,
                  decoration: const InputDecoration(
                    labelText: "Preferred Date *",
                    hintText: "YYYY-MM-DD",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Required" : null,
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      _preferredDateController.text =
                          "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _preferredTimeController,
                  decoration: const InputDecoration(
                    labelText: "Preferred Time Slot *",
                    hintText: "HH:MM",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Required" : null,
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      _preferredTimeController.text =
                          "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                    }
                  },
                ),
                const SizedBox(height: 12),
                Consumer2<ParishProvider, PriestProvider>(
                  builder: (context, parishProvider, priestProvider, _) {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    if (parishProvider.selectedParish != null) {
                      priestProvider.loadPriestsByParish(
                        parishProvider.selectedParish!.id!,
                        token: authProvider.token,
                      );
                    }
                    
                    return DropdownButtonFormField<int>(
                      value: _selectedPriestId,
                      decoration: const InputDecoration(
                        labelText: "Preferred Priest (Optional) - Subject to availability",
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
                    );
                  },
                ),
              ]),

              // Required Documents - Separate uploads
              _buildDocumentUploadSection(
                title: "Birth Certificate",
                description: "Upload birth certificate of the communicant *",
                file: _birthCertificateFile,
                isUploading: _isUploadingBirth,
                uploadedData: _uploadedBirthData,
                onPick: _pickBirthCertificate,
                onUpload: _uploadBirthCertificate,
              ),
              _buildDocumentUploadSection(
                title: "Baptismal Certificate",
                description: "Upload baptismal certificate of the communicant *",
                file: _baptismalCertificateFile,
                isUploading: _isUploadingBaptismal,
                uploadedData: _uploadedBaptismalData,
                onPick: _pickBaptismalCertificate,
                onUpload: _uploadBaptismalCertificate,
              ),

              // Additional Notes
              _buildSection(title: "Additional Information", children: [
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: "Additional Notes",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ]),

              const SizedBox(height: 20),
              Consumer<EucharistProvider>(
                builder: (context, eucharistProvider, _) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: eucharistProvider.isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: eucharistProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text("Submit Request", style: TextStyle(fontSize: 16)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
