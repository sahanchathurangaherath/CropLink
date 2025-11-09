import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/local_storage_service.dart';

class AddItemScreen extends StatefulWidget {
  final String categoryId;
  final String subcategoryId;

  const AddItemScreen({
    super.key,
    required this.categoryId,
    required this.subcategoryId,
  });

  @override
  AddItemScreenState createState() => AddItemScreenState();
}

class AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;
  final _user = FirebaseAuth.instance.currentUser;

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked == null) return;

      if (!mounted) return;
      setState(() {
        _selectedImage = File(picked.path);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to add items')),
      );
      return;
    }

    // Validate price
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    // Validate quantity
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nameTrim = _nameController.text.trim();

      // Save image locally
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${nameTrim.replaceAll(' ', '_')}.jpg';
      final imagePath = await LocalStorageService.saveImage(
        'items',
        fileName,
        _selectedImage!,
      );

      // Save to Firestore in the correct path
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.categoryId)
          .collection('subcategories')
          .doc(widget.subcategoryId)
          .collection('items')
          .add({
        'name': nameTrim,
        'price': price,
        'quantity': quantity,
        'description': _descriptionController.text.trim(),
        'localImagePath': imagePath,
        'sellerUid': _user!.uid,
        'categoryId': widget.categoryId,
        'subcategoryId': widget.subcategoryId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added successfully')),
      );

      // Return to previous screen
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding item: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedImage != null
                                ? const Color(0xFF17904A)
                                : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: _selectedImage != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withAlpha(179),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: const Text(
                                        'Tap to change image',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 50,
                                    color: Color(0xFF17904A),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Add Item Image',
                                    style: TextStyle(
                                      color: Color(0xFF17904A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Item name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_bag_outlined),
                      ),
                      validator: (value) => value?.trim().isEmpty == true
                          ? 'Please enter item name'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Price field
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                        prefixText: 'Rs. ',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.trim().isEmpty == true) {
                          return 'Please enter price';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quantity field
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.trim().isEmpty == true) {
                          return 'Please enter quantity';
                        }
                        if (int.tryParse(value!) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      maxLines: 3,
                      validator: (value) => value?.trim().isEmpty == true
                          ? 'Please enter description'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17904A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save Item',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
