import 'package:expense_tracker/auth.dart';
import 'package:expense_tracker/screens/forgot_password_page.dart';
import 'package:expense_tracker/screens/login_signup_page.dart';
import 'package:expense_tracker/screens/privacy_policy_page.dart';
import 'package:expense_tracker/screens/terms_conditions_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrackUrSpends',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const AuthPage(),
      routes: {
        '/login': (context) => const LoginSignupPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/terms-conditions': (context) => TermsConditionsPage(),
        '/privacy-policy': (context) => PrivacyPolicyPage(),
      },
    );
  }
}