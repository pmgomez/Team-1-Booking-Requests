import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../providers/anointing_sick_provider.dart';
import '../providers/priest_provider.dart';

class AnointingTheSickScreen extends StatefulWidget {
  static const routeName = '/anointing-the-sick';

  const AnointingTheSickScreen({super.key});

  @override
  State<AnointingTheSickScreen> createState() => _AnointingTheSickScreenState();
}

class _AnointingTheSickScreenState extends State<AnointingTheSickScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for required fields
  final _sickPersonNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _locationController = TextEditingController();

  // Controllers for optional fields
  final _locationAddressController = TextEditingController();
  final _preferredDateController = TextEditingController();
  final _preferredTimeController = TextEditingController();
  final _additionalNotesController = TextEditingController();

  // Priest selection state
  int? _selectedPriestId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final parishProvider = Provider.of<ParishProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final priestProvider = Provider.of<PriestProvider>(context, listen: false);
      
      await parishProvider.loadAllParishes();
      
      final userParishId = authProvider.currentUser?.preferredParishId;

      // Default to user's preferred parish if available
      if (userParishId != null) {
        // This will be set once parishes are loaded
        final userParish = parishProvider.parishes
            .where((p) => p.id == userParishId)
            .firstOrNull;
        if (userParish != null) {
          parishProvider.selectParish(userParish);
          await priestProvider.loadPriestsByParish(userParishId, token: authProvider.token);
        }
      }

      // Set default contact email and person to current user's info
      if (authProvider.currentUser?.email != null) {
        _contactEmailController.text = authProvider.currentUser!.email;
      }
      if (authProvider.currentUser?.fullName != null) {
        _contactPersonController.text = authProvider.currentUser!.fullName;
      }
    });
  }

  @override
  void dispose() {
    _sickPersonNameController.dispose();
    _contactPersonController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _locationController.dispose();
    _locationAddressController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmission() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final anointingSickProvider = Provider.of<AnointingSickProvider>(context, listen: false);
      final parishProvider = Provider.of<ParishProvider>(context, listen: false);
      final priestProvider = Provider.of<PriestProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to submit a booking.")),
        );
        return;
      }

      if (parishProvider.selectedParish == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a parish.")),
        );
        return;
      }

      final token = authProvider.token;
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication token not available.")),
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

      // Prepare notes array if additional notes were provided
      List<Map<String, dynamic>>? notesToAdd;
      if (_additionalNotesController.text.trim().isNotEmpty) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        notesToAdd = [
          {
            'author': 'parishioner',
            'content': _additionalNotesController.text.trim(),
            'authorId': currentUser?.id,
            'timestamp': DateTime.now().toIso8601String(),
          }
        ];
      }

      final success = await anointingSickProvider.createAnointingSickBooking(
        token: token,
        parishId: parishProvider.selectedParish!.id!,
        sickPersonName: _sickPersonNameController.text.trim(),
        contactPersonName: _contactPersonController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        location: _locationController.text.trim(),
        locationAddress: _locationAddressController.text.trim().isEmpty
            ? null
            : _locationAddressController.text.trim(),

        //QA FIX: Added trim method inside formatDate
        preferredDate: _preferredDateController.text.isEmpty
            ? null
            : formatDate(_preferredDateController.text.trim()),
        preferredTimeSlot: _preferredTimeController.text.trim().isEmpty
            ? null
            : _preferredTimeController.text.trim(),
        priestId: _selectedPriestId,
        notes: notesToAdd,
      );

      if (success && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Booking Submitted"),
            content: const Text(
                "Your Anointing of the Sick booking request has been submitted. The parish will contact you to confirm arrangements."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back
                },
                child: const Text("OK"),
              )
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(anointingSickProvider.errorMessage ?? "Failed to submit booking.")),
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
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
        title: const Text("Anointing of the Sick"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
                "Subject to availability. Parish will confirm your booking arrangements.",
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),

              // Urgent Notice
              Card(
                color: Colors.red[50],
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.priority_high, color: Colors.red),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "For urgent cases requiring immediate attention, please call the Parish office directly.",
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Patient Information Section
              _buildSection(
                title: "Patient Information",
                children: [
                  TextFormField(
                    controller: _sickPersonNameController,
                    decoration: const InputDecoration(
                      labelText: "Patient Full Name *",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: "Location (Hospital Name / Home Address) *",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (value) =>
                        value == null || value.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _locationAddressController,
                    decoration: const InputDecoration(
                      labelText: "Detailed Address (Optional)",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),

              // Contact Information Section
              _buildSection(
                title: "Contact Information",
                children: [
                  TextFormField(
                    controller: _contactPersonController,
                    decoration: const InputDecoration(
                      labelText: "Contact Person Name (Relative/Guardian) *",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Contact Email *",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Required";
                      }
                      if (!value.contains('@')) {
                        return "Enter a valid email";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Contact Phone Number *",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Required" : null,
                  ),
                ],
              ),

              // Booking Preferences Section
              _buildSection(
                title: "Booking Preferences",
                children: [
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
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          final parish = parishProvider.parishes
                              .firstWhere((p) => p.id == value);
                          // Clear any previously selected priest
                          setState(() {
                            _selectedPriestId = null;
                          });
                          parishProvider.selectParish(parish);
                          Provider.of<PriestProvider>(
                              context,
                              listen: false,
                            ).loadPriestsByParish(parish.id!, token: authProvider.token);
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
                      labelText: "Preferred Date (Optional)",
                      hintText: "YYYY-MM-DD",
                      border: OutlineInputBorder(),
                    ),
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
                      labelText: "Preferred Time Slot (Optional)",
                      hintText: "HH:MM",
                      border: OutlineInputBorder(),
                    ),
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
                  Consumer<PriestProvider>(
                    builder: (context, priestProvider, _) {
                      final validPriestId = _selectedPriestId != null && 
                          priestProvider.priests.any((p) => p.id == _selectedPriestId) 
                          ? _selectedPriestId : null;
                      return DropdownButtonFormField<int>(
                        value: validPriestId,
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
                ],
              ),

              // Additional Notes Section
              _buildSection(
                title: "Additional Information",
                children: [
                  TextFormField(
                    controller: _additionalNotesController,
                    decoration: const InputDecoration(
                      labelText: "Additional Notes (Patient Condition, Special Requests)",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Submit Button with loading state
              Consumer<AnointingSickProvider>(
                builder: (context, anointingSickProvider, _) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: anointingSickProvider.isLoading ? null : _handleSubmission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: anointingSickProvider.isLoading
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
