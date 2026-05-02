// lib/presentation/features/settings/privacy_screen.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      title: Text('Privacy Policy',
          style: AppTextStyles.heading(size: 17)),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _Section(
          title: 'Effective Date: January 1, 2026',
          body:
          'PointCalc ("we", "our", "us") is committed to protecting your privacy. This Privacy Policy explains what data we collect, how we use it, and your rights regarding your personal information.',
        ),
        _Section(
          title: '1. Information We Collect',
          body:
          'Account Information:\n• Email address (used for login and communication)\n• Display name and profile picture (optional)\n\nTournament Data:\n• Tournament names, match results, team names, player names\n• Match images uploaded for AI processing (not stored permanently)\n\nUsage Data:\n• App interactions, feature usage, error logs\n• Device type, OS version, app version',
        ),
        _Section(
          title: '2. How We Use Your Information',
          body:
          '• To provide and improve the tournament management service\n• To process match images and extract data via AI\n• To display leaderboards and match statistics\n• To send important service notifications\n• To investigate and prevent fraudulent activity\n• To respond to support requests',
        ),
        _Section(
          title: '3. Image Processing & AI',
          body:
          'When you upload images for match processing:\n\n• Images are sent to Google Gemini AI for data extraction\n• On-device processing is performed using Google ML Kit (no data leaves your device for this step)\n• Uploaded images are processed in real-time and are NOT stored on our servers\n• Extracted text data (player names, scores) is stored in your tournament records',
        ),
        _Section(
          title: '4. Data Storage',
          body:
          'Your tournament data is stored securely using Supabase, a cloud database provider. Data is stored in encrypted form. We retain your data for as long as your account is active. Upon account deletion, all your data is permanently removed within 30 days.',
        ),
        _Section(
          title: '5. Data Sharing',
          body:
          'We do not sell, trade, or rent your personal information to third parties. We may share data with:\n\n• Supabase (database provider)\n• Google (AI processing via Gemini API)\n• Law enforcement when required by law\n\nAll third-party providers are bound by their own privacy policies and data protection agreements.',
        ),
        _Section(
          title: '6. Data Security',
          body:
          'We implement industry-standard security measures including:\n\n• Encrypted data transmission (HTTPS/TLS)\n• Secure authentication via Supabase Auth\n• Row-level security on all database tables\n• No plaintext password storage',
        ),
        _Section(
          title: '7. Your Rights',
          body:
          'You have the right to:\n\n• Access your personal data at any time\n• Correct inaccurate information\n• Request deletion of your account and data\n• Export your tournament data\n• Opt out of non-essential communications\n\nTo exercise these rights, use the Settings section in the App or contact us directly.',
        ),
        _Section(
          title: '8. Children\'s Privacy',
          body:
          'PointCalc is not intended for users under the age of 13. We do not knowingly collect personal information from children. If we become aware that a child has provided personal information, we will delete it immediately.',
        ),
        _Section(
          title: '9. Notifications',
          body:
          'We may send push notifications for match reminders and app updates. You can control notification preferences in the App Settings or your device settings at any time.',
        ),
        _Section(
          title: '10. Changes to This Policy',
          body:
          'We may update this Privacy Policy from time to time. We will notify you of significant changes via the App. Your continued use of PointCalc after changes constitutes acceptance of the updated policy.',
        ),
        _Section(
          title: '11. Contact Us',
          body:
          'If you have questions or concerns about this Privacy Policy:\n\nEmail: privacy@pointcalc.app\nApp: Settings → Contact Support',
        ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTextStyles.subheading(
                color: AppColors.yellow, size: 14)),
        const SizedBox(height: 8),
        Text(body,
            style: AppTextStyles.body(
                color: AppColors.grey, size: 13),
            textAlign: TextAlign.justify),
      ],
    ),
  );
}