import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../providers/reconciliation_provider.dart';

class ReconciliationScreen extends StatefulWidget {
  const ReconciliationScreen({super.key});

  @override
  State<ReconciliationScreen> createState() => _ReconciliationScreenState();
}

class _ReconciliationScreenState extends State<ReconciliationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _penitentNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _preferredDateController = TextEditingController();
  final TextEditingController _preferredTimeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _confessionType = 'Regular';

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

      // Default contact email to current user's email if available
      if (authProvider.currentUser?.email != null) {
        _contactEmailController.text = authProvider.currentUser!.email;
      }
    });
  }

  @override
  void dispose() {
    _penitentNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final reconciliationProvider = Provider.of<ReconciliationProvider>(context, listen: false);
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

      final token = authProvider.token;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication token not found. Please login again.")),
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

      final success = await reconciliationProvider.createReconciliationBooking(
        token: token,
        parishId: parishProvider.selectedParish!.id!,
        penitentName: _penitentNameController.text.trim(),
        contactEmail: _contactEmailController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),

        //QA Fix: Add the trim method inside the format Date
        preferredDate: formatDate(_preferredDateController.text.trim()),
        preferredTimeSlot: _preferredTimeController.text.trim(),
        notes: notesToAdd,
      );

      if (success && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Booking Submitted"),
            content: const Text(
                "Your reconciliation booking request has been submitted. The parish will contact you to confirm availability."),
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
          SnackBar(content: Text(reconciliationProvider.errorMessage ?? "Failed to submit booking.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sacrament of Reconciliation"),
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
                "Fill out the form below to submit your reconciliation booking request. All fields marked with * are required.",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 5),
              const Text(
                "Subject to availability. Parish will confirm your booking.",
                style: TextStyle(
                    fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              _buildSection(title: "Confession Request", children: [
                const Text(
                  "The Sacrament of Penance is the method by which individual men and women may confess sins committed after baptism and have them absolved by a priest.",
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _confessionType,
                  decoration: const InputDecoration(
                    labelText: "Type of Confession",
                    border: OutlineInputBorder(),
                  ),
                  items: ['Regular', 'First Confession', 'Spiritual Direction']
                      .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                      .toList(),
                  onChanged: (val) => setState(() => _confessionType = val!),
                ),
              ]),

              // Penitent Information
              _buildSection(title: "Penitent Information", children: [
                TextFormField(
                  controller: _penitentNameController,
                  decoration: const InputDecoration(
                    labelText: "Penitent Name *",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactEmailController,
                  decoration: const InputDecoration(
                    labelText: "Contact Email *",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Required";
                    if (!value.contains('@')) return "Invalid email";
                    return null;
                  },
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
              ]),

              // Schedule Note
              _buildSection(title: "Schedule Note", children: [
                const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.blue),
                  title: Text("Regular Confession Hours"),
                  subtitle: Text("Mon-Sat: 5:00 PM - 6:00 PM\nSundays: During all Masses"),
                ),
                const SizedBox(height: 12),
                const Text("For private confession appointments, the parish office will contact you after submission."),
              ]),

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

              const SizedBox(height: 24),
              Consumer<ReconciliationProvider>(
                builder: (context, reconciliationProvider, _) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: reconciliationProvider.isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: reconciliationProvider.isLoading
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
}