import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';

class AdminRecordsScreen extends StatefulWidget {
  const AdminRecordsScreen({super.key});

  @override
  State<AdminRecordsScreen> createState() => _AdminRecordsScreenState();
}

class _AdminRecordsScreenState extends State<AdminRecordsScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<dynamic> _records = [];
  String _selectedType = 'all';

  final List<Map<String, String>> _typeOptions = [
    {'value': 'all', 'label': 'All Types'},
    {'value': 'baptism', 'label': 'Baptism'},
    {'value': 'wedding', 'label': 'Wedding'},
    {'value': 'confirmation', 'label': 'Confirmation'},
    {'value': 'eucharist', 'label': 'Eucharist'},
    {'value': 'reconciliation', 'label': 'Reconciliation'},
    {'value': 'anointing_sick', 'label': 'Anointing Sick'},
    {'value': 'funeral_mass', 'label': 'Funeral Mass'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() => _isLoading = true);

    final response = await _adminService.getSacramentalRecords(
      token,
      sacramentType: _selectedType == 'all' ? null : _selectedType,
    );

    if (response.success && response.data != null) {
      setState(() {
        _records = response.data!['records'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to load records')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sacramental Records'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Sacrament Type',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _typeOptions
                  .map((option) => DropdownMenuItem(
                        value: option['value'],
                        child: Text(option['label']!),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedType = value ?? 'all');
                _loadRecords();
              },
            ),
          ),

          // Records List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? const Center(child: Text('No sacramental records found'))
                    : RefreshIndicator(
                        onRefresh: _loadRecords,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _records.length,
                          itemBuilder: (context, index) {
                            final record = _records[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.indigo,
                                  child: const Icon(Icons.description, color: Colors.white),
                                ),
                                title: Text(
                                  record['personName'] ?? 
                                  record['fullName'] ?? 
                                  'Record #${record['id']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      (record['sacramentType'] ?? 'record')
                                          .toString()
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                    ),
                                    Text(
                                      'Date: ${record['sacramentDate']?.toString().substring(0, 10) ?? 'N/A'}',
                                    ),
                                    if (record['parishName'] != null)
                                      Text('Parish: ${record['parishName']}'),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  // TODO: Show record details
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
