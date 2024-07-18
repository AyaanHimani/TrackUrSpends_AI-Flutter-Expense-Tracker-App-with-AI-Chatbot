import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/get_started_page.dart';
import 'screens/home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool? isLoggedIn;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getAuthFlag();
  }

  Future<void> _getAuthFlag() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (isLoggedIn == null) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFEF6C06)));
          }

          // User logged in
          if (snapshot.hasData && isLoggedIn == true) {
            return const HomePage();
          }

          // User not logged in
          return const GetStartedPage();
        },
      ),
    );
  }
}