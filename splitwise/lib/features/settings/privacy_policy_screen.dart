import 'package:flutter/material.dart';
import 'package:splitwise/widgets/common/animated_wrapper.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        scrolledUnderElevation: 2,
        title: Text(
          'Privacy Policy',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
          style: IconButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(12),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildSectionCard(
                    context,
                    index: index,
                    icon: _sectionData[index]['icon'] as IconData,
                    title: _sectionData[index]['title'] as String,
                    children: _sectionData[index]['content'] as List<Widget>,
                  );
                },
                childCount: _sectionData.length,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Last Updated: June 1, 2023',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> _sectionData = [
    {
      'icon': Icons.shield_outlined,
      'title': 'Introduction',
      'content': [
        _buildParagraph(
          'Welcome to Splitwise. We respect your privacy and are committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our application.',
        ),
      ],
    },
    {
      'icon': Icons.inventory_2_outlined,
      'title': 'Information We Collect',
      'content': [
        _buildParagraph(
          'We collect information you provide directly to us, such as:',
        ),
        const SizedBox(height: 8),
        _buildBulletPoint('Account information (name, email, profile picture)'),
        _buildBulletPoint(
            'Transaction data (expenses, payments, group activities)'),
        _buildBulletPoint('Communications with other users'),
        _buildBulletPoint('Device information and usage statistics'),
      ],
    },
    {
      'icon': Icons.rule_rounded,
      'title': 'How We Use Your Information',
      'content': [
        _buildParagraph(
          'We use the information we collect to:',
        ),
        const SizedBox(height: 8),
        _buildBulletPoint('Provide, maintain, and improve our services'),
        _buildBulletPoint('Process transactions and send related information'),
        _buildBulletPoint('Send notifications, updates, and support messages'),
        _buildBulletPoint('Personalize your experience and content'),
        _buildBulletPoint('Monitor and analyze usage patterns and trends'),
      ],
    },
    {
      'icon': Icons.share_outlined,
      'title': 'Data Sharing and Disclosure',
      'content': [
        _buildParagraph(
          'We may share your information with:',
        ),
        const SizedBox(height: 8),
        _buildBulletPoint(
            'Other users (as necessary for the functionality of the app)'),
        _buildBulletPoint(
            'Service providers who perform services on our behalf'),
        _buildBulletPoint('As required by law or to protect rights and safety'),
      ],
    },
    {
      'icon': Icons.security_rounded,
      'title': 'Data Security',
      'content': [
        _buildParagraph(
          'We implement appropriate security measures to protect your personal information from unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the Internet or electronic storage is 100% secure, so we cannot guarantee absolute security.',
        ),
      ],
    },
    {
      'icon': Icons.fact_check_outlined,
      'title': 'Your Rights',
      'content': [
        _buildParagraph(
          'Depending on your location, you may have rights regarding your personal data, including:',
        ),
        const SizedBox(height: 8),
        _buildBulletPoint('Access to your personal data'),
        _buildBulletPoint('Correction of inaccurate data'),
        _buildBulletPoint('Deletion of your data'),
        _buildBulletPoint('Restriction of processing'),
        _buildBulletPoint('Data portability'),
      ],
    },
    {
      'icon': Icons.change_history_rounded,
      'title': 'Changes to This Policy',
      'content': [
        _buildParagraph(
          'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
        ),
      ],
    },
    {
      'icon': Icons.contact_mail_outlined,
      'title': 'Contact Us',
      'content': [
        _buildParagraph(
          'If you have any questions about this Privacy Policy, please contact us at:',
        ),
        const SizedBox(height: 12),
        _buildContactInfo(
            'Email', 'support@splitwise.com', Icons.email_outlined),
        const SizedBox(height: 8),
        _buildContactInfo(
            'Address',
            '123 Finance Street, San Francisco, CA 94107',
            Icons.location_on_outlined),
      ],
    },
  ];

  Widget _buildSectionCard(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedWrapper.staggered(
      index: index,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        color: colorScheme.surfaceContainerLowest,
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
                    colorScheme.primary.withValues(alpha: 0.05),
                    colorScheme.primary.withValues(alpha: 0.02),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, size: 20, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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

  static Widget _buildParagraph(String text) {
    return Builder(builder: (context) {
      final textTheme = Theme.of(context).textTheme;
      final colorScheme = Theme.of(context).colorScheme;

      return Text(
        text,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      );
    });
  }

  static Widget _buildBulletPoint(String text) {
    return Builder(builder: (context) {
      final textTheme = Theme.of(context).textTheme;
      final colorScheme = Theme.of(context).colorScheme;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Icon(
                Icons.circle,
                size: 6,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  static Widget _buildContactInfo(String label, String value, IconData icon) {
    return Builder(builder: (context) {
      final textTheme = Theme.of(context).textTheme;
      final colorScheme = Theme.of(context).colorScheme;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
