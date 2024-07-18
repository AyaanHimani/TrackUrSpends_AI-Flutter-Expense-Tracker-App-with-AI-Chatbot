import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_signup_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_emailController.text.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Email cannot be empty';
      });
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Password Reset', style: TextStyle(color: Color(0xFFEF6C06))),
          content: const Text('A password reset link has been sent to your email.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginSignupPage()),
                );
              },
              child: const Text('OK', style: TextStyle(color: Color(0xFFEF6C06))),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error', style: TextStyle(color: Color(0xFFEF6C06))),
          content: Text(e.message ?? 'An error occurred.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Color(0xFFEF6C06))),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Forgot Password', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFEF6C06),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter your email address to receive a password reset link.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 20.0),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                errorText: _errorMessage,
              ),
            ),
            const SizedBox(height: 20.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF6C06),
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Reset Password',
                  style: TextStyle(fontSize: 18.0, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
