import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About App',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo and Name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.campaign,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sahayak',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your Voice for a Better India',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Version 1.0.1',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // App Description
            _buildInfoCard(
              title: 'About Sahayak',
              content:
                  'Sahayak is a comprehensive civic engagement platform designed '
                  'to empower citizens of India to report community issues, '
                  'track their progress, and directly connect with civic officers. '
                  'Our mission is to bridge the gap between citizens and government '
                  'services, making civic participation more accessible and effective.',
              icon: Icons.info_outline,
            ),

            const SizedBox(height: 16),

            // Key Features
            _buildInfoCard(
              title: 'Key Features',
              content:
                  '• Report civic issues with photos and location\n'
                  '• Real-time tracking of report status\n'
                  '• Direct communication with civic officers\n'
                  '• Interactive map of community issues\n'
                  '• Secure data handling and privacy protection\n'
                  '• Multi-language support (Hindi, English)\n'
                  '• Offline report creation capability',
              icon: Icons.star_outline,
            ),

            const SizedBox(height: 16),

            // Developer Information
            _buildInfoCard(
              title: 'Developed By',
              content:
                  'Naitik Behera\n'
                  'Innovation for Digital India\n\n'
                  'Designed with ❤️ for empowering citizens',
              icon: Icons.code,
            ),

            const SizedBox(height: 16),

            // Privacy & Legal
            _buildInfoCard(
              title: 'Privacy & Legal',
              content:
                  '• Your privacy is our priority\n'
                  '• All data is encrypted and stored securely\n'
                  '• Location data used only for issue reporting\n'
                  '• Photos processed locally and uploaded securely\n'
                  '• Compliant with Indian data protection laws\n'
                  '• No personal data shared without consent',
              icon: Icons.security,
            ),

            const SizedBox(height: 16),

            // Technical Information
            _buildInfoCard(
              title: 'Technical Information',
              content:
                  'Built with Flutter for cross-platform compatibility\n'
                  'Secure backend powered by Supabase\n'
                  'Real-time synchronization\n'
                  'Offline-first architecture\n'
                  'Progressive Web App support\n'
                  'Compatible with Android 6.0+ and iOS 12.0+',
              icon: Icons.settings,
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareApp,
                    icon: const Icon(Icons.share),
                    label: const Text('Share App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _rateApp,
                    icon: const Icon(Icons.star),
                    label: const Text('Rate App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Feedback Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _sendFeedback,
                icon: const Icon(Icons.feedback_outlined),
                label: const Text('Send Feedback'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4CAF50),
                  side: const BorderSide(color: Color(0xFF4CAF50)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Copyright
            Text(
              '© 2024 EcoNova Team - Smart India Hackathon\nBuilt for Digital India Initiative',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Project Info
            GestureDetector(
              onTap: () {
                Clipboard.setData(
                  const ClipboardData(
                    text: 'Smart India Hackathon 2024 - EcoNova',
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Project info copied to clipboard'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
              child: Text(
                'Smart India Hackathon 2024 - EcoNova',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF4CAF50),
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF4CAF50), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    // TODO: Implement app sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality will be implemented'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _rateApp() {
    // TODO: Implement app rating functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Sahayak'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How would you rate your experience with Sahayak?'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.orange, size: 32),
                Icon(Icons.star, color: Colors.orange, size: 32),
                Icon(Icons.star, color: Colors.orange, size: 32),
                Icon(Icons.star, color: Colors.orange, size: 32),
                Icon(Icons.star, color: Colors.orange, size: 32),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for rating Sahayak!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _sendFeedback() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('We value your feedback! Help us improve Sahayak.'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText:
                    'Share your thoughts, suggestions, or report issues...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Feedback sent! Thank you for helping us improve.',
                  ),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
