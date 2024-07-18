import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsConditionsPage extends StatelessWidget {
  TermsConditionsPage({super.key});

  final Uri _url = Uri.parse('https://github.com/AyaanHimani/TrackUrSpends_AI-Flutter-Expense-Tracker-App-with-AI-Chatbot.git');

  Future<void> _launchUrl() async {
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFEF6C06),
        surfaceTintColor: Colors.transparent,
        title: const Text('Terms and Conditions', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terms and Conditions',
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20.0),
              const Text(
                '1. Introduction\n\n'
                    'Welcome to TrackUrSpends AI. By accessing our app, you agree to these terms and conditions. If you do not agree, please do not use our app.\n\n'

                    '2. Accounts\n\n'
                    'When you create an account with us, you must provide us with accurate and complete information. You are responsible for safeguarding the password that you use to access the Service and for any activities or actions under your password.\n\n'

                    '3. Termination\n\n'
                    'We may terminate or suspend your account and bar access to the Service immediately, without prior notice or liability, under our sole discretion, for any reason whatsoever and without limitation, including but not limited to a breach of the Terms.\n\n'

                    '4. Use of the Service\n\n'
                    'You agree not to misuse the Service or help anyone else to do so. This includes but is not limited to the following actions:\n'
                    'a. Using the Service for unlawful purposes or activities.\n'
                    'b. Uploading viruses or other malicious code.\n'
                    'c. Interfering with or disrupting the integrity or performance of the Service.\n\n'

                    '5. Limitation of Liability\n\n'
                    'In no event shall TrackUrSpends AI, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from (i) your use or inability to use the Service; (ii) any unauthorized access to or use of our servers and/or any personal information stored therein; (iii) any interruption or cessation of transmission to or from the Service; (iv) any bugs, viruses, trojan horses, or the like that may be transmitted to or through our Service by any third party; and/or (v) any errors or omissions in any content or for any loss or damage incurred as a result of the use of any content posted, emailed, transmitted, or otherwise made available through the Service, whether based on warranty, contract, tort (including negligence) or any other legal theory, whether or not we have been informed of the possibility of such damage.\n\n'

                    '6. Governing Law\n\n'
                    'These Terms shall be governed and construed in accordance with the laws of Gujarat, India, without regard to its conflict of law provisions.\n\n'

                    '7. Changes to Terms\n\n'
                    'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material we will try to provide at least 30 days\' notice prior to any new terms taking effect. What constitutes a material change will be determined at our sole discretion.\n\n'

                    '8. Contact Us\n\n'
                    'If you have any questions about these Terms, please contact us by visiting this page on our website:',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(width: 10.0),
              GestureDetector(
                onTap: _launchUrl,
                child: const Text(
                  'https://github.com/AyaanHimani/TrackUrSpends_AI-Flutter-Expense-Tracker-App-with-AI-Chatbot.git',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
