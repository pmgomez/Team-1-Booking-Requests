import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/parish_provider.dart';
import '../widgets/custom_button.dart';

class ParishSelectionScreen extends StatefulWidget {
  static const routeName = '/parish-selection';

  const ParishSelectionScreen({super.key});

  @override
  _ParishSelectionScreenState createState() => _ParishSelectionScreenState();
}

class _ParishSelectionScreenState extends State<ParishSelectionScreen> {

  //1. ADDED: The state lock to prevent double-taps
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    // Load all parishes when the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ParishProvider>(context, listen: false).loadAllParishes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final parishProvider = context.watch<ParishProvider>();
    final parishes = parishProvider.parishes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Parish'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a parish for your sacramental service:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            if (parishProvider.isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (parishProvider.errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        parishProvider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Retry',
                        onPressed: () {
                          parishProvider.loadAllParishes();
                        },
                      ),
                    ],
                  ),
                ),
              )
            else if (parishes.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No parishes available'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: parishes.length,
                  itemBuilder: (context, index) {
                    final parish = parishes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          Icons.church,
                          color: Theme.of(context).primaryColor,
                        ),
                        title: Text(parish.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(parish.address),
                            if (parish.contactPhone != null)
                              Text('Phone: ${parish.contactPhone}'),
                            if (parish.contactEmail != null)
                              Text('Email: ${parish.contactEmail}'),
                            if (parish.servicesOffered != null && parish.servicesOffered!.isNotEmpty)
                              Wrap(
                                spacing: 4,
                                children: parish.servicesOffered!
                                    .map((service) => Chip(
                                          label: Text(
                                            service,
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                          backgroundColor: Colors.grey[200],
                                        ))
                                    .toList(),
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        //2. MODIFIED: The locked onTap function
                        // 2. MODIFIED: The locked onTap function
                        onTap: () async {
                          // If already processing a tap, ignore subsequent taps
                          if (_isSelecting) return;

                          // Lock the UI
                          setState(() {
                            _isSelecting = true;
                          });

                          // Update the provider state
                          parishProvider.selectParish(parish);

                          // 3. ADDED: Context safety check before navigation
                          if (!context.mounted) return;
                          Navigator.pop(context, parish);
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}