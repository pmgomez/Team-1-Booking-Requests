import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/parish_provider.dart';
import '../providers/mass_intention_provider.dart';

class MassIntentionScreen extends StatefulWidget {
  const MassIntentionScreen({super.key});

  @override
  State<MassIntentionScreen> createState() => _MassIntentionScreenState();
}

class _MassIntentionScreenState extends State<MassIntentionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _offeredByController = TextEditingController();
  final TextEditingController _intentionForController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _preferredTimeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedType = 'Thanksgiving'; // Default selection

  @override
  void initState() {
    super.initState();
    // Load parishes for selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ParishProvider>(context, listen: false).loadAllParishes();
    });
  }

  @override
  void dispose() {
    _offeredByController.dispose();
    _intentionForController.dispose();
    _dateController.dispose();
    _preferredTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final massIntentionProvider = Provider.of<MassIntentionProvider>(context, listen: false);
      final parishProvider = Provider.of<ParishProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to submit a mass intention.")),
        );
        return;
      }

      if (parishProvider.selectedParish == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a parish.")),
        );
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

      // Format date to ISO format
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

      final success = await massIntentionProvider.createMassIntention(
        type: mapType(_selectedType),
        intentionDetails: _intentionForController.text.trim(),
        donorName: _offeredByController.text.trim(),
        dateRequested: formatDate(_dateController.text),
        parishId: parishProvider.selectedParish!.id!,
        massSchedule: formatDate(_dateController.text),
        preferredTime: _preferredTimeController.text.trim().isEmpty ? null : _preferredTimeController.text.trim(),
        notes: notesToAdd,
      );

      if (success && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Mass Intention Submitted"),
            content: const Text("Your mass intention request has been submitted successfully."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(massIntentionProvider.errorMessage ?? "Failed to submit mass intention.")),
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
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
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
        title: const Text("Mass Intention"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSection(title: "Intention Details", children: [
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
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: "Intention Type *", border: OutlineInputBorder()),
                  items: ['Thanksgiving', 'Petition', 'Soul / Death Anniversary', 'Healing', 'Special Intention']
                      .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _intentionForController,
                  decoration: const InputDecoration(labelText: "Name of Person / Intention *", border: OutlineInputBorder()),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
              ]),

              _buildSection(title: "Schedule & Offering", children: [
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "Preferred Mass Date *", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2027));
                    if (picked != null) {
                      _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _preferredTimeController,
                  decoration: const InputDecoration(
                    labelText: "Preferred Time *",
                    hintText: "HH:MM (e.g., 08:00 or 14:30)",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? "Required" : null,
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
                  controller: _offeredByController,
                  decoration: const InputDecoration(labelText: "Offered By (Name/Family) *", border: OutlineInputBorder()),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: "Additional Notes", border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ]),

              const SizedBox(height: 20),
              Consumer<MassIntentionProvider>(
                builder: (context, provider, _) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: provider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text("Submit Mass Intention", style: TextStyle(fontSize: 16)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}