import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('app_title'.tr(), style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/signin'),
              child: Text('welcome_sign_in'.tr()),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: Text('welcome_sign_up'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
