import 'package:flutter/material.dart';
import 'package:new_project/services/productService.dart';

class SponsorshipModal extends StatefulWidget {
  final String productId;
  final String token;

  const SponsorshipModal({
    Key? key,
    required this.productId,
    required this.token,
  }) : super(key: key);

  @override
  _SponsorshipModalState createState() => _SponsorshipModalState();
}

class _SponsorshipModalState extends State<SponsorshipModal> {
  final TextEditingController _amountController = TextEditingController();
  bool _isNationwide = false;
  bool isLoading = false;
  List<String> selectedCities = [];
  String selectedPriority = "Low"; // Default priority level

  // Priority levels mapped to numeric values for backend
  final Map<String, int> priorityLevels = {
    "Low": 1,
    "Medium": 2,
    "High": 3,
    "Very High": 4,
    "Critical": 5,
  };

  final List<String> palestinianCities = [
    'Ramallah',
    'Hebron',
    'Nablus',
    'Jericho',
    'Jenin',
    'Bethlehem',
    'Gaza',
    'Tulkarm',
    'Qalqilya',
    'Rafah',
    'Khan Yunis',
    'Deir al-Balah',
  ];

  Future<void> _submitSponsorship() async {
    final double? amountPaid = double.tryParse(_amountController.text.trim());
    final int priorityValue = priorityLevels[selectedPriority]!;

    if (amountPaid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid sponsorship amount')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final productService = ProductService(baseUrl: 'http://172.16.0.68:5000');
      await productService.addSponsorship(
        productId: widget.productId,
        amountPaid: amountPaid,
        targetLocations: selectedCities,
        nationwide: _isNationwide,
        token: widget.token,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sponsorship added successfully')),
      );
      Navigator.pop(context, true); // Indicate success to parent screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add sponsorship: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Sponsorship',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Sponsorship Amount',
                labelStyle: const TextStyle(color: Colors.black),
                prefixIcon: const Icon(Icons.money, color: Colors.black),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedPriority,
              items: priorityLevels.keys
                  .map((level) => DropdownMenuItem(
                        value: level,
                        child: Text(
                          level,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedPriority = value!;
                });
              },
              decoration: InputDecoration(
                labelText: 'Priority Level',
                labelStyle: const TextStyle(color: Colors.black),
                prefixIcon:
                    const Icon(Icons.priority_high, color: Colors.black),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final List<String>? result = await showDialog<List<String>>(
                  context: context,
                  builder: (_) => MultiSelectDialog(
                    items: palestinianCities,
                    selectedItems: selectedCities,
                  ),
                );
                if (result != null) {
                  setState(() => selectedCities = result);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedCities.isEmpty
                          ? 'Select Target Locations'
                          : selectedCities.join(', '),
                      style: const TextStyle(color: Colors.black),
                    ),
                    const Icon(Icons.location_on, color: Colors.black),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _isNationwide,
                  onChanged: (value) {
                    setState(() => _isNationwide = value ?? false);
                  },
                ),
                const Text(
                  'Nationwide',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : _submitSponsorship,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Sponsorship'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MultiSelectDialog extends StatefulWidget {
  final List<String> items;
  final List<String> selectedItems;

  const MultiSelectDialog({
    Key? key,
    required this.items,
    required this.selectedItems,
  }) : super(key: key);

  @override
  State<MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  late List<String> _tempSelectedItems;

  @override
  void initState() {
    super.initState();
    _tempSelectedItems = List.from(widget.selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Cities', style: TextStyle(color: Colors.black)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.items
              .map((city) => CheckboxListTile(
                    title:
                        Text(city, style: const TextStyle(color: Colors.black)),
                    value: _tempSelectedItems.contains(city),
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _tempSelectedItems.add(city);
                        } else {
                          _tempSelectedItems.remove(city);
                        }
                      });
                    },
                  ))
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, widget.selectedItems),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _tempSelectedItems),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
