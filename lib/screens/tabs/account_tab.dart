import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/auth_provider.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            auth.user?.email ?? 'Guest',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          // Role picker with Firestore persistence via AuthProvider.setRole
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Role:'),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: auth.role,
                items: const [
                  DropdownMenuItem(value: 'buyer', child: Text('Buyer')),
                  DropdownMenuItem(value: 'seller', child: Text('Seller')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    context.read<AuthProvider>().setRole(v);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Language dropdown (kept from your version)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<String>(
                value: context.locale.languageCode,
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'si', child: Text('සිංහල')),
                  DropdownMenuItem(value: 'ta', child: Text('தமிழ்')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  context.setLocale(Locale(v));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: auth.signedIn ? () => auth.signOut() : null,
            child: Text('sign_out'.tr()),
          ),
        ],
      ),
    );
  }
}
