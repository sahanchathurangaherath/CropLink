import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/local_storage_service.dart';

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
  File? _selectedImage;
  bool _isLoading = false;
  String? _editingSubcategoryId;
  String? _existingImagePath;

  @override
  void dispose() {
    _subcategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked == null) return;

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

  Future<void> _saveSubcategory(BuildContext dialogContext) async {
    if (!_formKey.currentState!.validate()) return;

    // Only require image for new subcategories
    if (_editingSubcategoryId == null && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final subcategoryName = _subcategoryController.text.trim();
      final docId = subcategoryName.toLowerCase();

      // Check if subcategory already exists (only for new subcategories)
      if (_editingSubcategoryId == null) {
        final existingDoc = await FirebaseFirestore.instance
            .collection('categories')
            .doc(widget.category)
            .collection('subcategories')
            .doc(docId)
            .get();

        if (existingDoc.exists) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subcategory already exists')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      String? imagePath = _existingImagePath;

      // Save new image if selected
      if (_selectedImage != null) {
        // Delete old image if updating
        if (_existingImagePath != null) {
          await LocalStorageService.deleteImage(_existingImagePath!);
        }

        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${widget.category}_${subcategoryName.replaceAll(' ', '_')}.jpg';
        imagePath = await LocalStorageService.saveImage(
            'subcategories', fileName, _selectedImage!);
      }

      final Map<String, dynamic> subcategoryData = {
        'name': subcategoryName,
        'imagePath': imagePath,
      };

      if (_editingSubcategoryId == null) {
        // Add new subcategory
        subcategoryData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(widget.category)
            .collection('subcategories')
            .doc(docId)
            .set(subcategoryData);
      } else {
        // Update existing subcategory
        subcategoryData['updatedAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(widget.category)
            .collection('subcategories')
            .doc(_editingSubcategoryId!)
            .update(subcategoryData);
      }

      if (!mounted) return;
      Navigator.pop(dialogContext); // Close dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_editingSubcategoryId == null
                ? 'Subcategory added successfully'
                : 'Subcategory updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteSubcategory(
      String subcategoryId, String? imagePath) async {
    // Check if subcategory has items
    final itemsSnapshot = await FirebaseFirestore.instance
        .collection('categories')
        .doc(widget.category)
        .collection('subcategories')
        .doc(subcategoryId)
        .collection('items')
        .limit(1)
        .get();

    if (itemsSnapshot.docs.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Cannot delete subcategory with items. Delete all items first.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subcategory'),
        content:
            const Text('Are you sure you want to delete this subcategory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Delete image if exists
      if (imagePath != null) {
        await LocalStorageService.deleteImage(imagePath);
      }

      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.category)
          .collection('subcategories')
          .doc(subcategoryId)
          .delete();

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subcategory deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting subcategory: $e')),
      );
    }
  }

  void _clearForm() {
    _subcategoryController.clear();
    setState(() {
      _selectedImage = null;
      _editingSubcategoryId = null;
      _existingImagePath = null;
    });
  }

  void _showSubcategoryDialog([DocumentSnapshot? subcategoryDoc]) {
    _clearForm();

    // If editing, populate fields
    if (subcategoryDoc != null) {
      final data = subcategoryDoc.data() as Map<String, dynamic>;
      _editingSubcategoryId = subcategoryDoc.id;
      _existingImagePath = data['imagePath'];
      _subcategoryController.text = data['name'] ?? '';
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _editingSubcategoryId == null
                            ? 'Add Subcategory'
                            : 'Edit Subcategory',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF17904A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _clearForm();
                          Navigator.pop(dialogContext);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await _pickImage();
                            setDialogState(() {});
                          },
                          child: Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (_selectedImage != null ||
                                        _existingImagePath != null)
                                    ? const Color(0xFF17904A)
                                    : Color(0xFF17904A).withOpacity(0.5),
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
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Color(0xFF17904A)),
                                            onPressed: () async {
                                              await _pickImage();
                                              setDialogState(() {});
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : _existingImagePath != null
                                    ? FutureBuilder<File?>(
                                        future: LocalStorageService.getImage(
                                            _existingImagePath!),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }
                                          if (snapshot.hasData &&
                                              snapshot.data != null) {
                                            return Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: Image.file(
                                                    snapshot.data!,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.9),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: IconButton(
                                                      icon: const Icon(
                                                          Icons.edit,
                                                          color: Color(
                                                              0xFF17904A)),
                                                      onPressed: () async {
                                                        await _pickImage();
                                                        setDialogState(() {});
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }
                                          return Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons
                                                    .add_photo_alternate_outlined,
                                                size: 50,
                                                color: Color(0xFF17904A),
                                              ),
                                              const SizedBox(height: 12),
                                              const Text(
                                                'Add Subcategory Image',
                                                style: TextStyle(
                                                  color: Color(0xFF17904A),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Tap to select',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 50,
                                            color: Color(0xFF17904A),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Add Subcategory Image',
                                            style: TextStyle(
                                              color: Color(0xFF17904A),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Tap to select',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _subcategoryController,
                          enabled: _editingSubcategoryId == null,
                          decoration: InputDecoration(
                            labelText: 'Subcategory Name',
                            hintText: 'Enter the subcategory name',
                            prefixIcon: const Icon(Icons.category,
                                color: Color(0xFF17904A)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF17904A)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF17904A), width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Color(0xFF17904A).withOpacity(0.5)),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[400]!),
                            ),
                            filled: true,
                            fillColor: _editingSubcategoryId == null
                                ? Colors.grey[50]
                                : Colors.grey[200],
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a subcategory name';
                            }
                            return null;
                          },
                        ),
                        if (_editingSubcategoryId != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Note: Subcategory name cannot be changed',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        _clearForm();
                                        Navigator.pop(dialogContext);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        side: const BorderSide(
                                            color: Color(0xFF17904A)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        'Cancel',
                                        style:
                                            TextStyle(color: Color(0xFF17904A)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _saveSubcategory(dialogContext),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF17904A),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(_editingSubcategoryId == null
                                          ? 'Add'
                                          : 'Update'),
                                    ),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSubcategoryOptions(DocumentSnapshot subcategoryDoc) {
    final data = subcategoryDoc.data() as Map<String, dynamic>;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.visibility, color: Color(0xFF17904A)),
              title: const Text('View Items'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/seller/items',
                  arguments: {
                    'category': widget.category,
                    'subcategory': subcategoryDoc.id,
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF17904A)),
              title: const Text('Edit Subcategory'),
              onTap: () {
                Navigator.pop(context);
                _showSubcategoryDialog(subcategoryDoc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Subcategory'),
              onTap: () {
                Navigator.pop(context);
                _deleteSubcategory(subcategoryDoc.id, data['imagePath']);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSubcategoryImage(String? imagePath,
      {BoxFit fit = BoxFit.cover}) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Icon(Icons.category, size: 50, color: Colors.grey[600]),
        ),
      );
    }

    return FutureBuilder<File?>(
      future: LocalStorageService.getImage(imagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Container(
            color: Colors.grey[300],
            child: Center(
              child: Icon(Icons.image_not_supported,
                  size: 50, color: Colors.grey[600]),
            ),
          );
        }
        return Image.file(
          snapshot.data!,
          fit: fit,
          width: double.infinity,
        );
      },
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
                hintText: 'Search for subcategories',
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

                if (subcategories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category_outlined,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No subcategories yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add your first subcategory',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showSubcategoryDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Subcategory'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF17904A),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

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
                          onTap: () => _showSubcategoryDialog(),
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
                                  color: Color(0xFF17904A),
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
                      onTap: () => _showSubcategoryOptions(doc),
                      onLongPress: () => _showSubcategoryOptions(doc),
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
                                child: SizedBox(
                                  width: double.infinity,
                                  child: _buildSubcategoryImage(
                                    data['imagePath'] as String?,
                                    fit: BoxFit.cover,
                                  ),
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                        return Text(
                                          'Loading...',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        );
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubcategoryDialog(),
        backgroundColor: const Color(0xFF17904A),
        child: const Icon(Icons.add),
      ),
    );
  }
}
