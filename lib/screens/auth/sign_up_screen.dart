import 'dart:io';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _postalCodeController = TextEditingController();
  String _role = 'buyer';
  bool _loading = false;
  String? _error;
  File? _imageFile;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _saveImageLocally(File imageFile) async {
    try {
      final directory = await path_provider.getApplicationDocumentsDirectory();
      final fileName = path.basename(imageFile.path);
      final savedImage = await imageFile.copy('${directory.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      String? localImagePath;
      if (_imageFile != null) {
        localImagePath = await _saveImageLocally(_imageFile!);
      }

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'uid': cred.user!.uid,
        'email': _emailController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'district': _districtController.text.trim(),
        'postalCode': _postalCodeController.text.trim(),
        'role': _role,
        'createdAt': FieldValue.serverTimestamp(),
        'profileImage': localImagePath, // Store local path instead of URL
      });
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Wavy green header with logo
              Stack(
                children: [
                  ClipPath(
                    clipper: _TopWaveClipper(),
                    child: Container(
                      height: 180,
                      color: Color(0xFF17904A),
                    ),
                  ),
                  Positioned(
                    top: 32,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 60,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              SizedBox(height: 60),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'CROP LINK',
                          style: TextStyle(
                            color: Colors.yellow[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'Sign Up',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Role toggle
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFF3F5D8),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          margin: EdgeInsets.only(bottom: 16),
                          padding: EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _role = 'buyer'),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _role == 'buyer'
                                          ? Color(0xFF17904A)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Buyer',
                                      style: TextStyle(
                                        color: _role == 'buyer'
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _role = 'seller'),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _role == 'seller'
                                          ? Color(0xFF17904A)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Seller',
                                      style: TextStyle(
                                        color: _role == 'seller'
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Email
                        _buildTextField(
                          _emailController,
                          'Email',
                          TextInputType.emailAddress,
                        ),
                        // Full Name
                        _buildTextField(
                          _fullNameController,
                          'Full Name',
                          TextInputType.name,
                        ),
                        // Phone Number
                        _buildTextField(
                          _phoneController,
                          'Phone Number',
                          TextInputType.phone,
                        ),
                        // Address
                        _buildTextField(
                          _addressController,
                          'Address',
                          TextInputType.streetAddress,
                        ),
                        // City
                        _buildTextField(
                          _cityController,
                          'City',
                          TextInputType.text,
                        ),
                        // District
                        _buildTextField(
                          _districtController,
                          'District',
                          TextInputType.text,
                        ),
                        // Postal Code
                        _buildTextField(
                          _postalCodeController,
                          'Postal Code',
                          TextInputType.number,
                        ),
                        // Password
                        _buildTextField(
                          _passwordController,
                          'Password',
                          TextInputType.text,
                          isPassword: true,
                        ),
                        // Confirm Password
                        _buildTextField(
                          _confirmPasswordController,
                          'Confirm Password',
                          TextInputType.text,
                          isPassword: true,
                        ),
                        if (_error != null) ...[
                          SizedBox(height: 8),
                          Text(_error!, style: TextStyle(color: Colors.red)),
                        ],
                        SizedBox(height: 16),
                        // Create Account Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF17904A),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              textStyle: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            onPressed: _loading ? null : _signUp,
                            child: _loading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Text('Create Account'),
                          ),
                        ),
                        SizedBox(height: 24),
                        // Sign in link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("I Have an Account, ",
                                style: TextStyle(color: Colors.black54)),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Text('Sign in',
                                  style: TextStyle(
                                      color: Color(0xFF17904A),
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              // Add image picker and preview widget
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Color(0xFFF3F5D8),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Color(0xFF17904A), width: 2),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _imageFile!,
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 40,
                                    color: Color(0xFF17904A),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Add Image',
                                    style: TextStyle(
                                      color: Color(0xFF17904A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    TextInputType keyboardType, {
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF3F5D8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      margin: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        keyboardType: keyboardType,
        obscureText: isPassword,
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'This field is required' : null,
      ),
    );
  }
}

// Custom clipper for the wavy header
class _TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
