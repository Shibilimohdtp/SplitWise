import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Privacy Policy',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
          iconSize: 20,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Introduction'),
            _buildParagraph(
              context,
              'Welcome to Splitwise. We respect your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our application.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Information We Collect'),
            _buildParagraph(
              context,
              'We collect information you provide directly to us, such as:',
            ),
            _buildBulletPoint(
                context, 'Account information (name, email, profile picture)'),
            _buildBulletPoint(context,
                'Transaction data (expenses, payments, group activities)'),
            _buildBulletPoint(context, 'Communications with other users'),
            _buildBulletPoint(
                context, 'Device information and usage statistics'),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'How We Use Your Information'),
            _buildParagraph(
              context,
              'We use the information we collect to:',
            ),
            _buildBulletPoint(
                context, 'Provide, maintain, and improve our services'),
            _buildBulletPoint(
                context, 'Process transactions and send related information'),
            _buildBulletPoint(
                context, 'Send notifications, updates, and support messages'),
            _buildBulletPoint(
                context, 'Personalize your experience and content'),
            _buildBulletPoint(
                context, 'Monitor and analyze usage patterns and trends'),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Data Sharing and Disclosure'),
            _buildParagraph(
              context,
              'We may share your information with:',
            ),
            _buildBulletPoint(context,
                'Other users (as necessary for the functionality of the app)'),
            _buildBulletPoint(context,
                'Service providers who perform services on our behalf'),
            _buildBulletPoint(
                context, 'As required by law or to protect rights and safety'),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Data Security'),
            _buildParagraph(
              context,
              'We implement appropriate security measures to protect your personal information from unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the Internet or electronic storage is 100% secure, so we cannot guarantee absolute security.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Your Rights'),
            _buildParagraph(
              context,
              'Depending on your location, you may have rights regarding your personal data, including:',
            ),
            _buildBulletPoint(context, 'Access to your personal data'),
            _buildBulletPoint(context, 'Correction of inaccurate data'),
            _buildBulletPoint(context, 'Deletion of your data'),
            _buildBulletPoint(context, 'Restriction of processing'),
            _buildBulletPoint(context, 'Data portability'),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Changes to This Policy'),
            _buildParagraph(
              context,
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Contact Us'),
            _buildParagraph(
              context,
              'If you have any questions about this Privacy Policy, please contact us at:',
            ),
            const SizedBox(height: 8),
            _buildContactInfo(context, 'Email', 'support@splitwise.com'),
            _buildContactInfo(context, 'Address',
                '123 Finance Street, San Francisco, CA 94107'),
            const SizedBox(height: 24),
            Text(
              'Last Updated: June 1, 2023',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.5,
            ),
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
