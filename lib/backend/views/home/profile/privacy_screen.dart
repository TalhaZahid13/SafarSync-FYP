import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final appBarColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final headingColor = isDarkMode ? Colors.white : Colors.black;
    final textColor = isDarkMode ? Colors.white70 : Colors.black87;

    final textStyle = GoogleFonts.poppins(
      fontSize: 14,
      height: 1.6,
      color: textColor,
    );

    final headingStyle = GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: headingColor,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Privacy & Security',
          style: GoogleFonts.poppins(
            color: headingColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: appBarColor,
        elevation: 1,
        iconTheme: IconThemeData(color: headingColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Introduction',
              'At SMAC, your personal information is essential to us. This Privacy Policy outlines how we collect, use, store, and protect your data while providing a platform for professional connections, services, product listings, and course transactions. By using SMAC, you agree to the terms outlined in this policy.',
              headingStyle,
              textStyle,
            ),
            _buildSection(
              'Information We Collect',
              'We gather specific information to improve your experience:\n\n'
                  '• Personal details: Name, email, contact information, and profile data during sign-up.\n'
                  '• Payment details: Credit/debit card, PayPal, or bank account information for transactions.\n'
                  '• Geo-location data: (if allowed) to provide localized services and listings.\n'
                  '• Activity data: Courses bought, sold, or completed, including their performance metrics.',
              headingStyle,
              textStyle,
            ),
            _buildSection(
              'How We Use User Information',
              'The collected data helps us:\n\n'
                  '• Facilitate account creation, manage logins, and enhance user experience.\n'
                  '• Process payments, complete transactions, and provide customer support.\n'
                  '• Recommend services, products, or courses based on user preferences.\n'
                  '• Analyze trends to improve platform performance.\n'
                  '• Enable user communication for services or course-related queries.\n'
                  '• Ensure compliance with laws and safeguard against fraud.',
              headingStyle,
              textStyle,
            ),
            _buildSection(
              'Information Sharing and Disclosure',
              'SMAC does not sell or rent your personal data. Your data may be shared only under these circumstances:\n\n'
                  '• With Service Providers: For payment processing, storage, or marketing.\n'
                  '• For Legal Reasons: When mandated by law or to protect user and platform rights.\n'
                  '• User Transactions: Limited information (e.g., email, address) is shared for service/product transactions.',
              headingStyle,
              textStyle,
            ),
            _buildSection(
              'Data Security',
              'We employ industry-standard measures to protect your data from unauthorized access. However, no digital storage or transmission method is entirely secure.',
              headingStyle,
              textStyle,
            ),
            _buildSection(
              'Your Privacy Rights',
              '• Access & Update: Modify or review your data through your account settings.\n'
                  '• Delete Information: Request data deletion, subject to legal obligations.',
              headingStyle,
              textStyle,
            ),
            _buildSection(
              'Cookies & Tracking Technologies',
              'We use cookies to enhance your browsing experience and monitor user behavior. You can manage your cookie preferences via browser settings.',
              headingStyle,
              textStyle,
            ),
            _buildSection(
              'Third-Party Links',
              'Our platform may include links to third-party websites or services. SMAC is not responsible for their content or privacy practices.',
              headingStyle,
              textStyle,
            ),
            _buildSection(
              "Children's Privacy",
              'SMAC is designed for users above 18. Minors are welcome but prohibited from posting explicit content.',
              headingStyle,
              textStyle,
            ),
            _buildSection(
              'Marketplace & Subscription Plans',
              'SMAC offers a feature-rich marketplace for product listings and subscriptions to enhance visibility.\n\n'
                  '• Transaction Fee: A 5% transaction fee applies to all services but not on marketplace product listings.\n'
                  '• Featured Ads in Marketplace: Marketplace users can promote their product listings with a subscription-based Featured Ads option.\n\n'
                  'Subscription Plans:\n'
                  '• Basic: PKR 300/month\n'
                  '• Regular: PKR 500/month\n'
                  '• Enterprise: PKR 1000/month\n\n'
                  'Note: SMAC does not provide services directly but serves as a platform for users to connect, transact, and grow.',
              headingStyle,
              textStyle,
            ),
            _buildSection(
              'Changes to This Policy',
              'We may revise this policy periodically to reflect changes. Notifications will be sent via email or posted on our platform.',
              headingStyle,
              textStyle,
            ),
            _buildSection(
              'Contact Us',
              'If you have any questions or issues about our Privacy Policy, please feel free to contact us at:\n\n'
                  'Email: support@smac.com\n'
                  'Phone: +92-3441932822',
              headingStyle,
              textStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    String content,
    TextStyle heading,
    TextStyle text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: heading),
          const SizedBox(height: 6),
          Text(content, style: text),
        ],
      ),
    );
  }
}
