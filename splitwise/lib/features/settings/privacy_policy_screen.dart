import 'package:flutter/material.dart';
import 'package:splitwise/widgets/common/animated_wrapper.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          'Privacy Policy',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionCard(
            context,
            index: 0,
            icon: Icons.shield_outlined,
            title: 'Introduction',
            children: [
              _buildParagraph(
                context,
                'Welcome to Splitwise. We respect your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our application.',
              ),
            ],
          ),
          _buildSectionCard(
            context,
            index: 1,
            icon: Icons.inventory_2_outlined,
            title: 'Information We Collect',
            children: [
              _buildParagraph(
                context,
                'We collect information you provide directly to us, such as:',
              ),
              _buildBulletPoint(context,
                  'Account information (name, email, profile picture)'),
              _buildBulletPoint(context,
                  'Transaction data (expenses, payments, group activities)'),
              _buildBulletPoint(context, 'Communications with other users'),
              _buildBulletPoint(
                  context, 'Device information and usage statistics'),
            ],
          ),
          _buildSectionCard(
            context,
            index: 2,
            icon: Icons.rule_rounded,
            title: 'How We Use Your Information',
            children: [
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
            ],
          ),
          _buildSectionCard(
            context,
            index: 3,
            icon: Icons.share_outlined,
            title: 'Data Sharing and Disclosure',
            children: [
              _buildParagraph(
                context,
                'We may share your information with:',
              ),
              _buildBulletPoint(context,
                  'Other users (as necessary for the functionality of the app)'),
              _buildBulletPoint(context,
                  'Service providers who perform services on our behalf'),
              _buildBulletPoint(context,
                  'As required by law or to protect rights and safety'),
            ],
          ),
          _buildSectionCard(
            context,
            index: 4,
            icon: Icons.security_rounded,
            title: 'Data Security',
            children: [
              _buildParagraph(
                context,
                'We implement appropriate security measures to protect your personal information from unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the Internet or electronic storage is 100% secure, so we cannot guarantee absolute security.',
              ),
            ],
          ),
          _buildSectionCard(
            context,
            index: 5,
            icon: Icons.fact_check_outlined,
            title: 'Your Rights',
            children: [
              _buildParagraph(
                context,
                'Depending on your location, you may have rights regarding your personal data, including:',
              ),
              _buildBulletPoint(context, 'Access to your personal data'),
              _buildBulletPoint(context, 'Correction of inaccurate data'),
              _buildBulletPoint(context, 'Deletion of your data'),
              _buildBulletPoint(context, 'Restriction of processing'),
              _buildBulletPoint(context, 'Data portability'),
            ],
          ),
          _buildSectionCard(
            context,
            index: 6,
            icon: Icons.change_history_rounded,
            title: 'Changes to This Policy',
            children: [
              _buildParagraph(
                context,
                'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
              ),
            ],
          ),
          _buildSectionCard(
            context,
            index: 7,
            icon: Icons.contact_mail_outlined,
            title: 'Contact Us',
            children: [
              _buildParagraph(
                context,
                'If you have any questions about this Privacy Policy, please contact us at:',
              ),
              const SizedBox(height: 8),
              _buildContactInfo(context, 'Email', 'support@splitwise.com'),
              _buildContactInfo(context, 'Address',
                  '123 Finance Street, San Francisco, CA 94107'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Text(
              'Last Updated: June 1, 2023',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = colorScheme.primary;

    return AnimatedWrapper.staggered(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withValues(alpha: 0.05),
                    primaryColor.withValues(alpha: 0.02),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, size: 20, color: primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Icon(
              Icons.arrow_right_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      padding: const EdgeInsets.only(bottom: 4),
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
