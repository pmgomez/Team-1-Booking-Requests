import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../providers/wedding_provider.dart';

class WeddingBookingScreen extends StatefulWidget {
  const WeddingBookingScreen({super.key});

  @override
  State<WeddingBookingScreen> createState() => _WeddingBookingScreenState();
}

class _WeddingBookingScreenState extends State<WeddingBookingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _groomNameController = TextEditingController();
  final TextEditingController _brideNameController = TextEditingController();
  final TextEditingController _godparentsController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _preferredDateController = TextEditingController();
  final TextEditingController _preferredTimeController = TextEditingController();
  final TextEditingController _seminarScheduleController = TextEditingController();
  final TextEditingController _preferredPriestController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // File storage
  List<PlatformFile> _documents = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final parishProvider = Provider.of<ParishProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

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
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _groomNameController.dispose();
    _brideNameController.dispose();
    _godparentsController.dispose();
    _contactController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _seminarScheduleController.dispose();
    _preferredPriestController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Pick multiple documents
  Future<void> _pickDocuments() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        _documents = result.files;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Selected ${result.files.length} document(s)")),
      );
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final weddingProvider = Provider.of<WeddingProvider>(context, listen: false);
      final parishProvider = Provider.of<ParishProvider>(context, listen: false);

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

      if (_documents.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload required documents")),
        );
        return;
      }

      // Format dates to ISO format (YYYY-MM-DD)
      String formatDate(String date) {
        final parts = date.split('-');
        if (parts.length == 3) {
          return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
        }
        return date;
      }

      // Format time to HH:MM
      String formatTime(String time) {
        if (time.contains(':')) {
          final parts = time.split(':');
          if (parts.length >= 2) {
            return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
          }
        }
        return time;
      }

      final success = await weddingProvider.createWeddingBooking(
        token: authProvider.token!,
        parishId: parishProvider.selectedParish!.id!,
        groomFullName: _groomNameController.text.trim(),
        brideFullName: _brideNameController.text.trim(),
        contactEmail: authProvider.currentUser!.email,
        contactPhone: _contactController.text.trim(),
        preferredDate: formatDate(_preferredDateController.text),
        preferredTimeSlot: formatTime(_preferredTimeController.text),
        seminarSchedule: _seminarScheduleController.text.trim().isEmpty
            ? null
            : _seminarScheduleController.text.trim(),
        preferredPriest: _preferredPriestController.text.trim().isEmpty
            ? null
            : _preferredPriestController.text.trim(),
        additionalNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (success && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Booking Submitted"),
            content: const Text(
                "Your wedding booking request has been submitted. Parish will confirm availability."),
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
          SnackBar(content: Text(weddingProvider.errorMessage ?? "Failed to submit booking.")),
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
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wedding Booking"),
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
                "Subject to availability. Parish will confirm your booking and selected priest.",
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Couple Info
              _buildSection(title: "Couple Information", children: [
                TextFormField(
                  controller: _groomNameController,
                  decoration: const InputDecoration(
                    labelText: "Groom's Full Name *",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _brideNameController,
                  decoration: const InputDecoration(
                    labelText: "Bride's Full Name *",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? "Required" : null,
                ),
              ]),

              // Booking Preferences
              _buildSection(title: "Booking Preferences", children: [
                Consumer<ParishProvider>(
                  builder: (context, parishProvider, _) {
                    return DropdownButtonFormField<int>(
                      value: parishProvider.selectedParish?.id,
                      decoration: const InputDecoration(
                        labelText: "Preferred Parish *",
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
                      validator: (value) => value == null ? "Please select a parish" : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _preferredDateController,
                  decoration: const InputDecoration(
                    labelText: "Preferred Wedding Date *",
                    hintText: "YYYY-MM-DD",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? "Required" : null,
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
                  validator: (value) => value == null || value.isEmpty ? "Required" : null,
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
                TextFormField(
                  controller: _seminarScheduleController,
                  decoration: const InputDecoration(
                    labelText: "Seminar Schedule *",
                    hintText: "YYYY-MM-DD",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? "Required" : null,
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (pickedDate != null) {
                      _seminarScheduleController.text =
                          "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _preferredPriestController,
                  decoration: const InputDecoration(
                    labelText: "Preferred Priest (Optional) - Subject to availability",
                    border: OutlineInputBorder(),
                  ),
                ),
              ]),

              // Godparents & Contact
              _buildSection(title: "Contact Information", children: [
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(
                    labelText: "Contact Number / Email *",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _godparentsController,
                  decoration: const InputDecoration(
                    labelText: "Godparents' Details *",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? "Required" : null,
                ),
              ]),

              // Documents
              _buildSection(title: "Required Documents", children: [
                ElevatedButton.icon(
                  onPressed: _pickDocuments,
                  icon: const Icon(Icons.upload_file),
                  label: const Text(
                      "Upload Documents (CENOMAR, Birth, Baptismal, Confirmation) *"),
                ),
                const SizedBox(height: 8),
                if (_documents.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _documents
                        .map((file) => Text("• ${file.name}", style: const TextStyle(color: Colors.green)))
                        .toList(),
                  ),
              ]),

              // Notes
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
              Consumer<WeddingProvider>(
                builder: (context, weddingProvider, _) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: weddingProvider.isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: weddingProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text("Submit Booking", style: TextStyle(fontSize: 16)),
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
