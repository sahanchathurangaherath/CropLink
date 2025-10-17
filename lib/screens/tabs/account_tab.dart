import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF17904A),
        title: const Text('Account'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF17904A)),
            title: Text(auth.user?.email ?? 'Guest',
                style: Theme.of(context).textTheme.titleLarge),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFF17904A)),
            title: const Text('Settings'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF17904A)),
            title: const Text('Buyer'),
            onTap: () => context.read<AuthProvider>().setRole('buyer'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF17904A)),
            title: const Text('Seller'),
            onTap: () => context.read<AuthProvider>().setRole('seller'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language, color: Color(0xFF17904A)),
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: context.locale.languageCode,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'si', child: Text('සිංහල')),
                DropdownMenuItem(value: 'ta', child: Text('தமிழ்')),
              ],
              onChanged: (v) {
                if (v != null) {
                  context.setLocale(Locale(v));
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFF17904A)),
            title: Text('sign_out'.tr()),
            onTap: auth.signedIn ? () => auth.signOut() : null,
          ),
        ],
      ),
    );
  }
}
