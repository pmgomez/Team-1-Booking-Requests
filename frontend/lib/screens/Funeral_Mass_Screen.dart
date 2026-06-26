import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../providers/funeral_mass_provider.dart';
import '../providers/priest_provider.dart';
import '../widgets/custom_button.dart';

class FuneralMassScreen extends StatefulWidget {
  static const routeName = '/funeral-mass';

  const FuneralMassScreen({super.key});

  @override
  State<FuneralMassScreen> createState() => _FuneralMassScreenState();
}

class _FuneralMassScreenState extends State<FuneralMassScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _deceasedNameController = TextEditingController();
  final _dateOfDeathController = TextEditingController();
  final _wakeStartDateController = TextEditingController();
  final _wakeEndDateController = TextEditingController();
  final _wakeLocationController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
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
        _emailController.text = authProvider.currentUser!.email;
      }
      if (authProvider.currentUser?.fullName != null) {
        _contactPersonController.text = authProvider.currentUser!.fullName;
      }
    });
  }

  @override
  void dispose() {
    _deceasedNameController.dispose();
    _dateOfDeathController.dispose();
    _wakeStartDateController.dispose();
    _wakeEndDateController.dispose();
    _wakeLocationController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final funeralMassProvider = Provider.of<FuneralMassProvider>(context, listen: false);
      final parishProvider = Provider.of<ParishProvider>(context, listen: false);
      final priestProvider = Provider.of<PriestProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please login to submit a booking.")),
          );
        }
        return;
      }

      if (parishProvider.selectedParish == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please select a parish.")),
          );
        }
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

      final success = await funeralMassProvider.createFuneralMassBooking(
        token: authProvider.token!,
        parishId: parishProvider.selectedParish!.id!,
        deceasedFullName: _deceasedNameController.text.trim(),
        representativeName: _contactPersonController.text.trim(),
        contactEmail: _emailController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        preferredDate: formatDate(_preferredDateController.text),
        preferredTimeSlot: _preferredTimeController.text,
        dateOfDeath: _dateOfDeathController.text.trim().isEmpty
            ? null
            : formatDate(_dateOfDeathController.text),
        wakeStartDate: _wakeStartDateController.text.trim().isEmpty
            ? null
            : formatDate(_wakeStartDateController.text),
        wakeEndDate: _wakeEndDateController.text.trim().isEmpty
            ? null
            : formatDate(_wakeEndDateController.text),
        wakeLocation: _wakeLocationController.text.trim().isEmpty
            ? null
            : _wakeLocationController.text.trim(),
        priestId: _selectedPriestId,
        notes: notesToAdd,
      );

      if (success && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Booking Submitted"),
            content: const Text(
                "Your funeral mass booking request has been submitted. The parish will contact you to confirm details."),
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
          SnackBar(content: Text(funeralMassProvider.errorMessage ?? "Failed to submit booking.")),
        );
      }
    }
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
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
        title: const Text("Funeral Mass Booking"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
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
                "Fill out the form below to submit your funeral mass booking request. All fields marked with * are required.",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 5),
              const Text(
                "The Parish office will contact you immediately to coordinate the priest's schedule for the mass and interment.",
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Deceased Information Section
              _buildSection(
                title: "Deceased Information",
                children: [
                  TextFormField(
                    controller: _deceasedNameController,
                    decoration: const InputDecoration(
                      labelText: "Full Name of the Deceased *",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Enter deceased name" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dateOfDeathController,
                    decoration: const InputDecoration(
                      labelText: "Date of Death (Optional)",
                      hintText: "YYYY-MM-DD",
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      FocusScope.of(context).requestFocus(FocusNode());
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        _dateOfDeathController.text =
                            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                      }
                    },
                  ),
                ],
              ),

              // Wake Information Section
              _buildSection(
                title: "Wake Information",
                children: [
                  TextFormField(
                    controller: _wakeStartDateController,
                    decoration: const InputDecoration(
                      labelText: "Wake Start Date (Optional)",
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
                        _wakeStartDateController.text =
                            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _wakeEndDateController,
                    decoration: const InputDecoration(
                      labelText: "Wake End Date (Optional)",
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
                        _wakeEndDateController.text =
                            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _wakeLocationController,
                    decoration: const InputDecoration(
                      labelText: "Wake Location/Chapel (Optional)",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),

              // Contact Person Section
              _buildSection(
                title: "Contact Person",
                children: [
                  TextFormField(
                    controller: _contactPersonController,
                    decoration: const InputDecoration(
                      labelText: "Family Representative Name *",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
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
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Contact Number *",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Required" : null,
                  ),
                ],
              ),

              // Schedule & Requirements Section
              _buildSection(
                title: "Schedule & Requirements",
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
                      labelText: "Preferred Date *",
                      hintText: "YYYY-MM-DD",
                      border: OutlineInputBorder(),
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _additionalNotesController,
                    decoration: const InputDecoration(
                      labelText: "Additional Notes (Optional)",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Submit Button with loading state
              Consumer<FuneralMassProvider>(
                builder: (context, funeralMassProvider, _) {
                  return CustomButton(
                    text: "Submit Request",
                    onPressed: funeralMassProvider.isLoading ? null : _submitForm,
                    isLoading: funeralMassProvider.isLoading,
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
