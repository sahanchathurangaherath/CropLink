import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/storage_service.dart';

class SellerSubcategoryScreen extends StatefulWidget {
  final String category;

  const SellerSubcategoryScreen({
    super.key,
    required this.category,
  });

  @override
  State<SellerSubcategoryScreen> createState() =>
      _SellerSubcategoryScreenState();
}

class _SellerSubcategoryScreenState extends State<SellerSubcategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subcategoryController = TextEditingController();
  final _storageService = StorageService();
  File? _selectedImage;

  @override
  void dispose() {
    _subcategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final File? image = await _storageService.pickImage();
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _addSubcategory() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final subcategoryName = _subcategoryController.text.trim();
      String? imageUrl;

      if (_selectedImage != null) {
        imageUrl = await _storageService.uploadSubcategoryImage(
          _selectedImage!,
          widget.category,
          subcategoryName,
        );
      }

      // Add the subcategory to Firestore
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.category)
          .collection('subcategories')
          .doc(subcategoryName.toLowerCase())
          .set({
        'name': subcategoryName,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subcategory added successfully')),
        );
        _subcategoryController.clear();
        Navigator.pop(context); // Close the dialog
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showAddSubcategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subcategory'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _subcategoryController,
                decoration: const InputDecoration(
                  labelText: 'Subcategory Name',
                  hintText: 'Enter the subcategory name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a subcategory name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _selectedImage != null
                  ? Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.file(
                          _selectedImage!,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                        ),
                      ],
                    )
                  : OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add Image'),
                    ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _addSubcategory,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} Categories'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for products',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('categories')
                  .doc(widget.category)
                  .collection('subcategories')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final subcategories = snapshot.data!.docs;

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  padding: const EdgeInsets.all(16),
                  itemCount: subcategories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: _showAddSubcategoryDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_circle_outline,
                                    size: 40, color: Color(0xFF17904A)),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Add',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final doc = subcategories[index - 1];
                    final data = doc.data() as Map<String, dynamic>;
                    return InkWell(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/seller/items',
                          arguments: {
                            'category': widget.category,
                            'subcategory': doc.id,
                          },
                        );
                      },
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.network(
                                  data['imageUrl'] ??
                                      'https://via.placeholder.com/150',
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? doc.id,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('categories')
                                        .doc(widget.category)
                                        .collection('subcategories')
                                        .doc(doc.id)
                                        .collection('items')
                                        .snapshots(),
                                    builder: (context, itemSnapshot) {
                                      if (!itemSnapshot.hasData) {
                                        return const Text('Loading...');
                                      }
                                      final itemCount =
                                          itemSnapshot.data!.docs.length;
                                      return Text(
                                        '$itemCount items',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
