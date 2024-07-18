import 'package:flutter/material.dart';
import 'login_signup_page.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80.0),
              Image.asset(
                'assets/images/logo.png',
                height: 150.0,
              ),
              const SizedBox(height: 20.0),
              const Text(
                'TrackUrSpends AI',
                style: TextStyle(
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF6C06),
                ),
              ),
              const Spacer(flex: 1),
              const SizedBox(height: 20.0),
              const Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 36.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF6C06),
                ),
              ),
              const SizedBox(height: 10.0),
              const SizedBox(
                width: 250.0, // Matching the width with the button width
                child: Text(
                  'Track your expenses, set budgets, and gain AI insights into your spending habits.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey,
                  ),
                ),
              ),
              const Spacer(flex: 3),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginSignupPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF6C06),
                  padding: const EdgeInsets.symmetric(horizontal: 100.0, vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.open_in_new,
                      color: Colors.white,
                    ),
                    SizedBox(width: 5.0),
                    Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}