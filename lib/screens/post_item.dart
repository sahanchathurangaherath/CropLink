import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../models/product.dart';

class PostItemScreen extends StatefulWidget {
  final String category;
  const PostItemScreen({super.key, required this.category});

  @override
  State<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends State<PostItemScreen> {
  final _name = TextEditingController();
  late String _category;

  final _company = TextEditingController();
  final _quantity = TextEditingController(text: '1 kg');
  final _price = TextEditingController();
  final _location = TextEditingController();
  File? _image;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
  }

  Future<void> _pick() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (x != null) setState(() => _image = File(x.path));
  }

  Future<void> _submit() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    String imageUrl = '';
    if (_image != null) {
      imageUrl = await StorageService().uploadProductImage(_image!, user.uid);
    }
    final prod = Product(
      id: '',
      name: _name.text,
      category: _category,
      company: _company.text,
      quantity: _quantity.text,
      price: int.tryParse(_price.text) ?? 0,
      location: _location.text,
      imageUrl: imageUrl,
      sellerUid: user.uid,
      rating: 0,
      createdAt: Timestamp.now(),
    );
    await FirebaseFirestore.instance.collection('products').add(prod.toMap());
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post an Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: const [
                DropdownMenuItem(
                    value: 'vegetables', child: Text('Vegetables')),
                DropdownMenuItem(value: 'fruits', child: Text('Fruits')),
                DropdownMenuItem(value: 'grains', child: Text('Grains')),
                DropdownMenuItem(value: 'leafy', child: Text('Leafy')),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'vegetables'),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 8),
            TextField(
                controller: _company,
                decoration: const InputDecoration(labelText: 'Company')),
            const SizedBox(height: 8),
            TextField(
                controller: _quantity,
                decoration:
                    const InputDecoration(labelText: 'Unit (e.g. 1 kg)')),
            const SizedBox(height: 8),
            TextField(
                controller: _price,
                decoration: const InputDecoration(labelText: 'Price (Rs.)'),
                keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(
                controller: _location,
                decoration:
                    const InputDecoration(labelText: 'Location (City)')),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                    onPressed: _pick, child: const Text('Pick Image')),
                const SizedBox(width: 12),
                if (_image != null)
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _submit, child: const Text('Submit')),
          ],
        ),
      ),
    );
  }
}
