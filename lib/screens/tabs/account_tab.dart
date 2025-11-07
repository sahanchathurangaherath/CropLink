import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_details.dart'; // Add this import

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _districtController;
  late TextEditingController _postalCodeController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _districtController = TextEditingController();
    _postalCodeController = TextEditingController();

    // Load user details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      auth.loadUserDetails().then((details) {
        if (details != null) {
          setState(() {
            _nameController.text = details.fullName;
            _emailController.text = details.email;
            _phoneController.text = details.phoneNumber;
            _addressController.text = details.address;
            _cityController.text = details.city;
            _districtController.text = details.district;
            _postalCodeController.text = details.postalCode;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    _emailController.text = auth.user?.email ?? 'Guest';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF17904A),
                      Color(0xFF117A3D),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          size: 50, color: Color(0xFF17904A)),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _nameController.text,
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(_isEditing ? Icons.save : Icons.edit),
                onPressed: () async {
                  if (_isEditing && _formKey.currentState!.validate()) {
                    final auth = context.read<AuthProvider>();
                    final details = UserDetails(
                      uid: auth.user?.uid ?? '',
                      email: _emailController.text,
                      fullName: _nameController.text,
                      phoneNumber: _phoneController.text,
                      address: _addressController.text,
                      city: _cityController.text,
                      district: _districtController.text,
                      postalCode: _postalCodeController.text,
                      role: auth.userDetails?.role ?? 'buyer',
                    );

                    final success = await auth.updateUserDetails(details);
                    if (!mounted) return; // Add mounted check

                    if (success) {
                      setState(() => _isEditing = false);
                    } else {
                      if (!mounted) return; // Add mounted check
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Failed to update profile')),
                      );
                    }
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileSection(),
                    SizedBox(height: 16),
                    _buildPreferencesSection(context, auth),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        // Personal Information Card
        _buildInfoCard(
          'Personal Information',
          Icons.person_outline,
          [
            _buildInfoRow('Full Name', _nameController.text, _nameController),
            _buildInfoRow('Email', _emailController.text, _emailController,
                enabled: false),
            _buildInfoRow('Phone', _phoneController.text, _phoneController),
          ],
        ),
        SizedBox(height: 16),
        // Address Information Card
        _buildInfoCard(
          'Address Details',
          Icons.location_on_outlined,
          [
            _buildInfoRow(
                'Address', _addressController.text, _addressController),
            _buildInfoRow('City', _cityController.text, _cityController),
            _buildInfoRow(
                'District', _districtController.text, _districtController),
            _buildInfoRow('Postal Code', _postalCodeController.text,
                _postalCodeController),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color(0xFF17904A), size: 24),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF17904A),
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      String label, String value, TextEditingController controller,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: _isEditing
          ? TextFormField(
              controller: controller,
              enabled: enabled && _isEditing,
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF17904A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF17904A), width: 2),
                ),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? '$label is required' : null,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context, AuthProvider auth) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.language, color: Color(0xFF17904A)),
            title: Text('Language'),
            trailing: DropdownButton<String>(
              value: context.locale.languageCode,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'si', child: Text('සිංහල')),
                DropdownMenuItem(value: 'ta', child: Text('தமிழ்')),
              ],
              onChanged: (v) {
                if (v != null) context.setLocale(Locale(v));
              },
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('sign_out'.tr()),
            onTap: auth.signedIn ? () => auth.signOut() : null,
          ),
        ],
      ),
    );
  }
}
