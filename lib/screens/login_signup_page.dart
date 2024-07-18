import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/screens/forgot_password_page.dart';
import 'package:expense_tracker/screens/terms_conditions_page.dart';
import 'package:expense_tracker/screens/privacy_policy_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth.dart';


class LoginSignupPage extends StatefulWidget {
  const LoginSignupPage({super.key});

  @override
  _LoginSignupPageState createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers for login
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();

  // Controllers for signup
  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupPasswordController = TextEditingController();
  final TextEditingController _signupConfirmPasswordController = TextEditingController();

  // State variables for password visibility
  bool _isLoginPasswordObscured = true;
  bool _isSignupPasswordObscured = true;
  bool _isSignupConfirmPasswordObscured = true;

  // State variable for remember me and agree terms checkbox
  bool _rememberMe = false;
  bool _agreeTerms = false;

  // State variable for loading
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _loginEmailController.text,
        password: _loginPasswordController.text,
      );

      User? user = userCredential.user;

      if (user != null && !user.emailVerified) {
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Email not verified. Please check your email and verify.',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
            (route) => false,
      );

    } on FirebaseAuthException catch (e) {

      String errorMessage = 'Error occurred, Email or Password incorrect. If this error persists, Please Sign Up!';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided for that user.';
      } else if (e.code == 'email-not-verified') {
        errorMessage = 'Email not verified. Please check your email and verify.';
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Error', style: TextStyle(color: Color(0xFFEF6C06))),
          content: Text(errorMessage),
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

  Future<void> _signup() async {
    // Check if passwords match
    if (_signupPasswordController.text != _signupConfirmPasswordController.text) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Password Mismatch', style: TextStyle(color: Color(0xFFEF6C06))),
          content: const Text('The passwords do not match. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Color(0xFFEF6C06))),
            ),
          ],
        ),
      );
      return;
    }

    // Check if terms are agreed
    if (!_agreeTerms) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Terms Agreement', style: TextStyle(color: Color(0xFFEF6C06))),
          content: const Text('Please agree to the Terms and Conditions and Privacy Policy.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Color(0xFFEF6C06))),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _signupEmailController.text,
        password: _signupPasswordController.text,
      );

      User? user = userCredential.user;

      // Send email verification
      await user?.sendEmailVerification();

      // Show dialog for email verification
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Verify Your Email', style: TextStyle(color: Color(0xFFEF6C06))),
          content: const Text(
              'A verification link has been sent to your email. Please verify your account to continue.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Show success message after email verification
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Up Successful', style: TextStyle(color: Color(0xFFEF6C06))),
                    content: const Text(
                        'You have Signed Up successfully. Please verify your email and login with your credentials.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close success dialog
                          _tabController.animateTo(0); // Switch to the login tab
                        },
                        child: const Text('OK', style: TextStyle(color: Color(0xFFEF6C06))),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('OK', style: TextStyle(color: Color(0xFFEF6C06))),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {

      String errorMessage = 'Error occurred while signing up.';
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Signup Error', style: TextStyle(color: Color(0xFFEF6C06))),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Color(0xFFEF6C06))),
            ),
          ],
        ),
      );

      if (e.code == 'email-already-in-use') {
        _tabController.animateTo(0);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showComingSoonDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFEF6C06),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "Coming Soon...",
            style: TextStyle(fontSize: 16.0),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFFEF6C06)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150.0),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          flexibleSpace: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Image.asset(
                'assets/images/logo.png',
                height: 80.0,
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFEF6C06),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFEF6C06),
            labelStyle: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16.0,
            ),
            tabs: const [
              Tab(text: 'Login'),
              Tab(text: 'Sign up'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLoginForm(),
          _buildSignupForm(),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 45.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _loginEmailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
            ),
            const SizedBox(height: 25.0),
            TextField(
              controller: _loginPasswordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                      _isLoginPasswordObscured ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _isLoginPasswordObscured = !_isLoginPasswordObscured;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              obscureText: _isLoginPasswordObscured,
            ),
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFFEF6C06),
                    ),
                    const Text('Remember me'),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Color(0xFAFF8B35),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF6C06),
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 26.0,
                  width: 26.0,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                )
                    : const Text(
                  'Login',
                  style: TextStyle(fontSize: 18.0, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            const Text('OR', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Image.asset('assets/icons/google.png'),
                  iconSize: 40.0,
                  onPressed: () {
                    _showComingSoonDialog(context, 'Google Login');
                  },
                ),
                const SizedBox(width: 20.0),
                IconButton(
                  icon: Image.asset('assets/icons/facebook.png'),
                  iconSize: 40.0,
                  onPressed: () {
                    _showComingSoonDialog(context, 'Facebook Login');
                  },
                ),
                const SizedBox(width: 20.0),
                IconButton(
                  icon: Image.asset('assets/icons/apple.png'),
                  iconSize: 40.0,
                  onPressed: () {
                    _showComingSoonDialog(context, 'Apple Login');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 45.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _signupEmailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
            ),
            const SizedBox(height: 25.0),
            TextField(
              controller: _signupPasswordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                      _isSignupPasswordObscured ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _isSignupPasswordObscured = !_isSignupPasswordObscured;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              obscureText: _isSignupPasswordObscured,
            ),
            const SizedBox(height: 25.0),
            TextField(
              controller: _signupConfirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_isSignupConfirmPasswordObscured
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _isSignupConfirmPasswordObscured =
                      !_isSignupConfirmPasswordObscured;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              obscureText: _isSignupConfirmPasswordObscured,
            ),
            const SizedBox(height: 10.0),
            Row(
              children: [
                Checkbox(
                  value: _agreeTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreeTerms = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFFEF6C06),
                ),
                Flexible(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16.0, color: Colors.black),
                      children: [
                        const TextSpan(
                          text: 'I agree with the ',
                        ),
                        TextSpan(
                          text: 'T&C',
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            color: Colors.blue,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                  TermsConditionsPage(),
                                ),
                              );
                            },
                        ),
                        const TextSpan(
                          text: ' & ',
                        ),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            color: Colors.blue,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                  PrivacyPolicyPage(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF6C06),
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 26.0,
                  width: 26.0,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                )
                    : const Text(
                  'Sign Up',
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
