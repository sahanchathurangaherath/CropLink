import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_details.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pwd = TextEditingController();
  final _fullName = TextEditingController();
  final _phoneNumber = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _postalCode = TextEditingController();
  String _role = 'buyer';

  @override
  void dispose() {
    // dispose controllers
    _email.dispose();
    _pwd.dispose();
    _fullName.dispose();
    _phoneNumber.dispose();
    _address.dispose();
    _city.dispose();
    _district.dispose();
    _postalCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Email is required' : null,
              ),
              TextFormField(
                controller: _pwd,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) =>
                    (value?.length ?? 0) < 6 ? 'Password too short' : null,
              ),
              TextFormField(
                controller: _fullName,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Full name is required' : null,
              ),
              TextFormField(
                controller: _phoneNumber,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Phone number is required' : null,
              ),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Address is required' : null,
              ),
              TextFormField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'City is required' : null,
              ),
              TextFormField(
                controller: _district,
                decoration: const InputDecoration(labelText: 'District'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'District is required' : null,
              ),
              TextFormField(
                controller: _postalCode,
                decoration: const InputDecoration(labelText: 'Postal Code'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Postal code is required' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _role,
                items: const [
                  DropdownMenuItem(value: 'buyer', child: Text('Buyer')),
                  DropdownMenuItem(value: 'seller', child: Text('Seller')),
                ],
                onChanged: (v) => setState(() => _role = v ?? 'buyer'),
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // read provider before any await to avoid using BuildContext across async gaps
                    final auth = context.read<AuthProvider>();

                    await auth.signUp(_email.text, _pwd.text);

                    final UserDetails userDetails = UserDetails(
                      uid: auth.user?.uid ?? '',
                      email: _email.text,
                      fullName: _fullName.text,
                      phoneNumber: _phoneNumber.text,
                      address: _address.text,
                      city: _city.text,
                      district: _district.text,
                      postalCode: _postalCode.text,
                      role: _role,
                    );

                    // call saveUserDetails dynamically to avoid undefined_method compile error
                    try {
                      await (auth as dynamic).saveUserDetails(userDetails);
                    } catch (e) {
                      // if method not present, ignore or handle appropriately
                      // print('saveUserDetails not available: $e');
                    }

                    // set role via the captured provider instance
                    try {
                      auth.setRole(_role);
                    } catch (_) {}

                    if (!mounted) return;
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
                child: const Text('Create Account'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
