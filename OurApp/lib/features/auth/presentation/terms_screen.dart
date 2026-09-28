import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Privacy Policy'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms of Service & Privacy Policy',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Age Requirement (18+ Only)\n'
                'Rishta App is exclusively intended for adults seeking lawful, respectful matrimonial connections. You must be at least 18 years of age to register or use this platform.\n\n'
                '2. User-Generated Content & Moderation\n'
                'We enforce a strict zero-tolerance policy for abusive language, vulgar photos, harassment, or fake identities. Accounts violating community standards will be immediately suspended.\n\n'
                '3. Privacy & Photo Control\n'
                'Your phone number and contact details are private and never shown publicly. You retain full control over photo visibility settings.\n\n'
                '4. Account Deletion\n'
                'You may delete your account at any time from the app menu. Deletion permanently removes your profile, photos, and messages.',
                style: TextStyle(fontSize: 14, height: 1.6, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('I Understand & Agree'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
