import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/local_storage_service.dart';

class SellerItemScreen extends StatefulWidget {
  final String category;
  final String subcategory;

  const SellerItemScreen({
    super.key,
    required this.category,
    required this.subcategory,
  });

  @override
  State<SellerItemScreen> createState() => _SellerItemScreenState();
}

class _SellerItemScreenState extends State<SellerItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _imageFile;
  String? _editingItemId;
  String? _existingImagePath;

  static const int _pageSize = 10;
  final List<DocumentSnapshot> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _imageFile = File(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _saveItem(BuildContext dialogContext) async {
    if (!_formKey.currentState!.validate()) return;

    // Only require image for new items
    if (_editingItemId == null && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image for the item')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save items')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    final quantity = int.tryParse(_quantityController.text.trim());

    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String? localImagePath = _existingImagePath;

      // Save new image if selected
      if (_imageFile != null) {
        // Delete old image if updating
        if (_existingImagePath != null) {
          await LocalStorageService.deleteImage(_existingImagePath!);
        }

        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${_nameController.text.trim().replaceAll(' ', '_')}.jpg';
        localImagePath = await LocalStorageService.saveImage(
          'items',
          fileName,
          _imageFile!,
        );
      }

      final itemData = {
        'name': _nameController.text.trim(),
        'price': price,
        'quantity': quantity,
        'description': _descriptionController.text.trim(),
        'localImagePath': localImagePath,
        'sellerUid': user.uid,
      };

      if (_editingItemId == null) {
        // Add new item
        itemData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(widget.category)
            .collection('subcategories')
            .doc(widget.subcategory)
            .collection('items')
            .add(itemData);
      } else {
        // Update existing item
        itemData['updatedAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(widget.category)
            .collection('subcategories')
            .doc(widget.subcategory)
            .collection('items')
            .doc(_editingItemId!)
            .update(itemData);
      }

      if (!mounted) return;

      Navigator.pop(context); // Close loading
      Navigator.pop(dialogContext); // Close dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingItemId == null
              ? 'Item added successfully'
              : 'Item updated successfully'),
        ),
      );

      // Refresh list
      setState(() {
        _items.clear();
        _hasMore = true;
        _lastDocument = null;
      });
      await _loadItems();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteItem(String itemId, String? imagePath) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
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
          .doc(widget.subcategory)
          .collection('items')
          .doc(itemId)
          .delete();

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted successfully')),
      );

      // Refresh list
      setState(() {
        _items.clear();
        _hasMore = true;
        _lastDocument = null;
      });
      await _loadItems();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting item: $e')),
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _priceController.clear();
    _quantityController.clear();
    _descriptionController.clear();
    setState(() {
      _imageFile = null;
      _editingItemId = null;
      _existingImagePath = null;
    });
  }

  void _showItemDialog([DocumentSnapshot? itemDoc]) {
    _clearForm();

    // If editing, populate fields
    if (itemDoc != null) {
      final data = itemDoc.data() as Map<String, dynamic>;
      _editingItemId = itemDoc.id;
      _existingImagePath = data['localImagePath'];
      _nameController.text = data['name'] ?? '';
      _priceController.text = (data['price'] ?? 0).toString();
      _quantityController.text = (data['quantity'] ?? 0).toString();
      _descriptionController.text = data['description'] ?? '';
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _editingItemId == null
                                ? 'Add New Item'
                                : 'Edit Item',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
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
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          await _pickImage();
                          setDialogState(() {});
                        },
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (_imageFile != null ||
                                      _existingImagePath != null)
                                  ? const Color(0xFF17904A)
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: _imageFile != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        _imageFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
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
                                                    icon: const Icon(Icons.edit,
                                                        color:
                                                            Color(0xFF17904A)),
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
                                          children: const [
                                            Icon(Icons.add_photo_alternate,
                                                size: 64,
                                                color: Color(0xFF17904A)),
                                            SizedBox(height: 8),
                                            Text(
                                              'Add Product Image',
                                              style: TextStyle(
                                                color: Color(0xFF17904A),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.add_photo_alternate,
                                            size: 64, color: Color(0xFF17904A)),
                                        SizedBox(height: 8),
                                        Text(
                                          'Add Product Image',
                                          style: TextStyle(
                                            color: Color(0xFF17904A),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Tap to select',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Item Name',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.shopping_bag_outlined),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Please enter an item name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: InputDecoration(
                                labelText: 'Price (Rs)',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.attach_money),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(v) == null) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon:
                                    const Icon(Icons.inventory_2_outlined),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(v) == null) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.description_outlined),
                        ),
                        maxLines: 3,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Please enter a description'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => _saveItem(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF17904A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _editingItemId == null ? 'Add Item' : 'Update Item',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showItemOptions(DocumentSnapshot itemDoc) {
    final data = itemDoc.data() as Map<String, dynamic>;
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
              leading: const Icon(Icons.edit, color: Color(0xFF17904A)),
              title: const Text('Edit Item'),
              onTap: () {
                Navigator.pop(context);
                _showItemDialog(itemDoc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Item'),
              onTap: () {
                Navigator.pop(context);
                _deleteItem(itemDoc.id, data['localImagePath']);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _loadItems() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
        return;
      }

      var query = FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.category)
          .collection('subcategories')
          .doc(widget.subcategory)
          .collection('items')
          .where('sellerUid', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshots = await query.get();

      if (snapshots.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _lastDocument = snapshots.docs.last;
        _items.addAll(snapshots.docs);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading items: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subcategory} Items'),
        backgroundColor: const Color(0xFF17904A),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            _loadItems();
          }
          return true;
        },
        child: _items.isEmpty && !_isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No items yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to add your first item',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showItemDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
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
              )
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                padding: const EdgeInsets.all(16),
                itemCount: _items.length + 1 + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _showItemDialog(),
                        borderRadius: BorderRadius.circular(12),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline,
                                size: 48, color: Color(0xFF17904A)),
                            SizedBox(height: 8),
                            Text(
                              'Add New Item',
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

                  if (index == _items.length + 1 && _isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final itemDoc = _items[index - 1];
                  final data = itemDoc.data() as Map<String, dynamic>;
                  final num price = (data['price'] ?? 0) as num;
                  final int qty = (data['quantity'] ?? 0) is int
                      ? data['quantity'] as int
                      : int.tryParse('${data['quantity']}') ?? 0;

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => _showItemOptions(itemDoc),
                      onLongPress: () => _showItemOptions(itemDoc),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: data['localImagePath'] != null
                                ? FutureBuilder<File?>(
                                    future: LocalStorageService.getImage(
                                        data['localImagePath']),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                    top: Radius.circular(12)),
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      if (snapshot.hasError ||
                                          !snapshot.hasData ||
                                          snapshot.data == null) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                    top: Radius.circular(12)),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                                Icons.image_not_supported,
                                                size: 48,
                                                color: Colors.grey),
                                          ),
                                        );
                                      }
                                      return ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(12)),
                                        child: Image.file(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.image_not_supported,
                                          size: 48, color: Colors.grey),
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? 'Unnamed Item',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rs. ${price.toDouble().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Stock: $qty',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
