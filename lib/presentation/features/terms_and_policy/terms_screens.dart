// lib/presentation/features/settings/terms_screen.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      title: Text('Terms & Conditions',
          style: AppTextStyles.heading(size: 17)),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _Section(
          title: 'Effective Date: January 1, 2026',
          body:
          'Welcome to PointCalc ("App", "we", "our"). By using this application, you agree to the following Terms & Conditions. Please read them carefully before using our services.',
        ),
        _Section(
          title: '1. Acceptance of Terms',
          body:
          'By creating an account or using PointCalc, you confirm that you are at least 13 years of age and agree to be bound by these Terms. If you do not agree, please discontinue use of the App immediately.',
        ),
        _Section(
          title: '2. Description of Service',
          body:
          'PointCalc is a tournament management application designed for BGMI and PUBG Mobile esports organizers. The App allows users to create tournaments, upload match data via image processing, track leaderboards, and manage team results.',
        ),
        _Section(
          title: '3. User Accounts',
          body:
          'You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized use of your account. We reserve the right to suspend or terminate accounts that violate these Terms.',
        ),
        _Section(
          title: '4. Image Upload & AI Processing',
          body:
          'By uploading images to PointCalc, you grant us a limited, non-exclusive license to process those images solely for the purpose of extracting tournament data. Images are processed using Google Gemini AI and Google ML Kit. We do not store your uploaded images on our servers permanently. Image data is processed in transit and discarded after extraction.',
        ),
        _Section(
          title: '5. Data Accuracy',
          body:
          'PointCalc uses AI-assisted image recognition which may produce errors. It is the user\'s responsibility to verify all extracted data before confirming match results. We are not liable for incorrect point calculations resulting from unverified AI output.',
        ),
        _Section(
          title: '6. Prohibited Conduct',
          body:
          'You agree not to:\n\n• Use the App to manipulate tournament results fraudulently\n• Upload images containing inappropriate, offensive, or illegal content\n• Attempt to reverse engineer, hack, or disrupt the App\n• Create multiple accounts for the purpose of gaining unfair advantages\n• Share your account credentials with unauthorized third parties',
        ),
        _Section(
          title: '7. Intellectual Property',
          body:
          'All content, design, code, and features of PointCalc are the intellectual property of the developers. You may not copy, reproduce, distribute, or create derivative works from any part of this App without explicit written permission.',
        ),
        _Section(
          title: '8. Third-Party Services',
          body:
          'PointCalc integrates with third-party services including Supabase (database), Google Gemini AI (image processing), and Google ML Kit (on-device OCR). Use of these services is subject to their respective terms of service and privacy policies.',
        ),
        _Section(
          title: '9. Limitation of Liability',
          body:
          'To the maximum extent permitted by law, PointCalc and its developers shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the App, including but not limited to loss of data, tournament disputes, or service interruptions.',
        ),
        _Section(
          title: '10. Service Availability',
          body:
          'We do not guarantee uninterrupted access to the App. We may suspend, modify, or discontinue the service at any time without prior notice. We are not liable for any loss resulting from service downtime.',
        ),
        _Section(
          title: '11. Changes to Terms',
          body:
          'We reserve the right to update these Terms at any time. Changes will be communicated via the App. Continued use after changes constitutes acceptance of the revised Terms.',
        ),
        _Section(
          title: '12. Contact',
          body:
          'For questions regarding these Terms, please contact us at:\nsupport@pointcalc.app',
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