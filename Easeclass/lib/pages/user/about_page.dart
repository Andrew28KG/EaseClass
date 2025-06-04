import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About EaseClass'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'EaseClass',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Version 1.0.0', // Replace with your app version
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'About Us',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '''EaseClass is a classroom booking system designed to simplify the reservation process for both students and administrators. Our goal is to provide a seamless and efficient way to manage classroom resources, ensuring that everyone can easily find and book the spaces they need.

Key Features:
- Easy classroom search and filtering
- Quick and intuitive booking process
- Real-time availability updates
- User-friendly interface
- Dedicated sections for current bookings and history

We are committed to continuously improving EaseClass and adding new features based on user feedback. Thank you for using our application!''',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 