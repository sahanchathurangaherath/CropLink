import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_items.dart';
import '../widgets/add_item_sheet.dart';

class SellerItemPage extends StatefulWidget {
  final String category;

  const SellerItemPage({
    super.key,
    required this.category,
  });

  @override
  State<SellerItemPage> createState() => _SellerItemPageState();
}

class _SellerItemPageState extends State<SellerItemPage> {
  @override
  Widget build(BuildContext context) {
    // Controllers for form fields
    final TextEditingController nameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    String? selectedItem;
    String? selectedUnit;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF17904A),
        title: Text(widget.category),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Add new subcategory button
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Add New Subcategory'),
                  content: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Subcategory Name',
                      hintText: 'Enter new subcategory name',
                    ),
                    onSubmitted: (value) async {
                      if (value.trim().isNotEmpty) {
                        await FirebaseFirestore.instance
                            .collection('subcategories')
                            .add({
                          'category': widget.category,
                          'name': value.trim(),
                          'createdAt': DateTime.now(),
                        });
                      }
                      Navigator.pop(dialogContext);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Add Item Form
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.add_circle, color: Color(0xFF17904A)),
                title: const Text('Add New Item'),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) =>
                        AddItemSheet(category: widget.category),
                  );
                },
              ),
            ),
            // Existing Items List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image picker placeholder
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.add_photo_alternate, size: 50),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Item selection dropdown
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Select Item',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items:
                              CategoryItems.getItemsForCategory(widget.category)
                                  .map((item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(item),
                                      ))
                                  .toList(),
                          initialValue: selectedItem,
                          onChanged: (value) {
                            setState(() {
                              selectedItem = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Company/Person name field
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Company/Person Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Quantity and Unit
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: quantityController,
                                decoration: InputDecoration(
                                  labelText: 'Quantity',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Unit',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'g', child: Text('g')),
                                  DropdownMenuItem(
                                      value: 'kg', child: Text('kg')),
                                ],
                                initialValue: selectedUnit,
                                onChanged: (value) {
                                  setState(() {
                                    selectedUnit = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Price field
                        TextField(
                          controller: priceController,
                          decoration: InputDecoration(
                            labelText: 'Price (Rs.)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),

                        // Location field
                        TextField(
                          controller: locationController,
                          decoration: InputDecoration(
                            labelText: 'Current Location',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Post button
                        ElevatedButton(
                          onPressed: () async {
                            // Validate input
                            if (selectedItem == null ||
                                nameController.text.trim().isEmpty ||
                                quantityController.text.trim().isEmpty ||
                                selectedUnit == null ||
                                priceController.text.trim().isEmpty ||
                                locationController.text.trim().isEmpty) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Please fill all fields.')),
                                );
                              }
                              return;
                            }

                            // Print the current user's UID for debugging
                            print(FirebaseAuth.instance.currentUser?.uid);

                            // Save to Firestore (nested path, include sellerUid)
                            final sellerUid =
                                FirebaseAuth.instance.currentUser?.uid;
                            await FirebaseFirestore.instance
                                .collection('categories')
                                .doc(widget.category)
                                .collection('subcategories')
                                .doc(selectedItem ?? 'unknown_subcat')
                                .collection('items')
                                .add({
                              'category': widget.category,
                              'subcategory': selectedItem,
                              'name': nameController.text.trim(),
                              'quantity': double.tryParse(
                                      quantityController.text.trim()) ??
                                  0,
                              'unit': selectedUnit,
                              'price': double.tryParse(
                                      priceController.text.trim()) ??
                                  0,
                              'location': locationController.text.trim(),
                              'sellerUid':
                                  sellerUid, // Must match authenticated user's UID
                              'createdAt': DateTime.now(),
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Item posted successfully!')),
                              );
                              // Optionally clear fields
                              setState(() {
                                selectedItem = null;
                                nameController.clear();
                                quantityController.clear();
                                selectedUnit = null;
                                priceController.clear();
                                locationController.clear();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF17904A),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Post Item',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
