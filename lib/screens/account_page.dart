import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth.dart';
import '../models.dart';

class AccountPage extends StatefulWidget {
  final UserModel userModel;

  const AccountPage({super.key, required this.userModel});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmation",
              style: TextStyle(
                  color: Color(0xFFEF6C06), fontWeight: FontWeight.bold)),
          content: const Text("Are you sure you want to Sign Out?",
              style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel",
                  style: TextStyle(color: Color(0xFFEF6C06))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _signOut(context);
              },
              child: const Text("Sign Out",
                  style: TextStyle(color: Color(0xFFEF6C06))),
            ),
          ],
        );
      },
    );
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthPage()),
      (route) => false,
    );
  }

  void _confirmDeleteData(BuildContext context) {
    TextEditingController emailController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text("Confirmation",
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Are you sure you want to delete all your data from our database?",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "All your data (transactions, reminders, photos, etc.) will be deleted and cannot be recovered once you confirm this.",
                    style: TextStyle(fontSize: 14, color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Type your registered email",
                      border: const OutlineInputBorder(),
                      errorText: errorMessage, // Show error here
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child:
                      const Text("Cancel", style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () {
                    if (emailController.text.isEmpty) {
                      setState(() {
                        errorMessage = "Email cannot be empty.";
                      });
                    } else if (emailController.text != widget.userModel.email) {
                      setState(() {
                        errorMessage = "Incorrect email. Please try again.";
                      });
                    } else {
                      // Navigator.of(context).pop();
                      _deleteAllData(context, "onlyData");
                    }
                  },
                  child: const Text("Delete Data",
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    String? emailErrorMessage;
    String? passwordErrorMessage;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text("Confirmation",
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Are you sure you want to delete your Account?",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Account along with all your data (transactions, reminders, photos, etc.) will be deleted and cannot be recovered once you confirm this.\n"
                      "If you have signed in with this account in multiple devices, make sure to sign out from all other devices for proper deletion of the account.",
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Type your registered email",
                        border: const OutlineInputBorder(),
                        errorText: emailErrorMessage,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: "Type your password",
                        border: const OutlineInputBorder(),
                        errorText: passwordErrorMessage,
                      ),
                      obscureText: true,
                    ),
                    if (emailErrorMessage != null ||
                        passwordErrorMessage != null) ...[
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child:
                      const Text("Cancel", style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() {
                      emailErrorMessage = null;
                      passwordErrorMessage = null;
                    });

                    if (emailController.text.isEmpty) {
                      setState(() {
                        emailErrorMessage = "Email cannot be empty.";
                      });
                    } else if (emailController.text != widget.userModel.email) {
                      setState(() {
                        emailErrorMessage =
                            "Incorrect email. Please try again.";
                      });
                    } else if (passwordController.text.isEmpty) {
                      setState(() {
                        passwordErrorMessage = "Password cannot be empty.";
                      });
                    } else {
                      // Attempt to reauthenticate the user
                      bool isReauthenticated = await _reauthenticateUser(
                        emailController.text,
                        passwordController.text,
                      );

                      if (isReauthenticated) {
                        _deleteAllData(context, "Account");
                      } else {
                        setState(() {
                          passwordErrorMessage =
                              "Incorrect password. Please try again.";
                        });
                      }
                    }
                  },
                  child: const Text("Delete Account",
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _reauthenticateUser(String email, String password) async {
    try {
      User user = FirebaseAuth.instance.currentUser!;
      AuthCredential credentials =
          EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credentials);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _deleteAllData(BuildContext context, String toDelete) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF6C06)),
          ),
        );
      },
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("No user is currently signed in.");
      }

      final uid = user.uid;
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(uid);

      // Using WriteBatch to perform batched writes
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Delete transactions
      final transactions = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: uid)
          .get();
      if (transactions.docs.isNotEmpty) {
        for (var doc in transactions.docs) {
          batch.delete(doc.reference);
        }
      }

      // Delete reminders
      final reminders = await FirebaseFirestore.instance
          .collection('reminders')
          .where('userId', isEqualTo: uid)
          .get();
      if (reminders.docs.isNotEmpty) {
        for (var doc in reminders.docs) {
          batch.delete(doc.reference);
        }
      }

      // Delete photos from Firestore and Storage
      final photos = await FirebaseFirestore.instance
          .collection('photos')
          .where('userId', isEqualTo: uid)
          .get();
      if (photos.docs.isNotEmpty) {
        for (var doc in photos.docs) {
          final photoUrl = doc['imageUrl'] as String?;
          if (photoUrl != null) {
            await FirebaseStorage.instance.refFromURL(photoUrl).delete();
          }
          batch.delete(doc.reference);
        }
      }

      // Get user document to update the accounts and balance
      final userDoc = await userDocRef.get();
      if (!userDoc.exists) {
        throw Exception("User document does not exist.");
      }

      UserModel userModel = UserModel.fromDocument(userDoc);

      // Delete all accounts except the main one and set the balance of the main account to 0
      if (userModel.accounts.isNotEmpty) {
        userModel.accounts.removeWhere((account) => account.name != 'Main');
        if (userModel.accounts.isNotEmpty) {
          userModel.accounts[0].balance = 0;
        }
      }

      // Update haveReminders flag
      userModel.haveReminders = false;

      // Update user document
      batch.update(userDocRef, {
        'accounts':
            userModel.accounts.map((account) => account.toMap()).toList(),
        'haveReminders': userModel.haveReminders,
      });

      // Commit batch
      await batch.commit();

      if (toDelete == "Account") {
        await userDocRef.delete();
        await user.delete();
        Navigator.of(context).pop(); // Close the progress indicator

        _signOut(context);
      } else {
        // Only data deletion
        Navigator.of(context).pop(); // Close the progress indicator
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Data Deleted",
                  style: TextStyle(color: Colors.red)),
              content: const Text(
                "Please restart the app to view changes.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                  },
                  child: const Text("OK", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting data: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  final Uri _url = Uri.parse(
      'https://github.com/AyaanHimani/TrackUrSpends_AI-Flutter-Expense-Tracker-App-with-AI-Chatbot.git');

  Future<void> _launchUrl() async {
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Support",
              style: TextStyle(
                  color: Color(0xFFEF6C06), fontWeight: FontWeight.bold)),
          content: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 16, color: Colors.black),
              children: [
                const TextSpan(
                  text: "This will take you to the app's GitHub page.\n\n"
                      "You are welcome to raise your queries and write your opinions.\n\n"
                      "Click on the link below if the page does not redirect.\n\n",
                ),
                TextSpan(
                  text:
                      "https://github.com/AyaanHimani/TrackUrSpends_AI-Flutter-Expense-Tracker-App-with-AI-Chatbot.git",
                  style: const TextStyle(color: Colors.blue),
                  recognizer: TapGestureRecognizer()..onTap = _launchUrl,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel",
                  style: TextStyle(color: Color(0xFFEF6C06))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchUrl();
              },
              child: const Text("Go to GitHub",
                  style: TextStyle(color: Color(0xFFEF6C06))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double buttonWidth = 250.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFEFE0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEF6C06),
        surfaceTintColor: Colors.transparent,
        title: const Text('My Account', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    // Container for profile picture with background
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFF8954B),
                              Color(0xFFF67C1D),
                              Color(0xFFFFAA3C),
                              Color(0xFFFFB174),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28.0),
                        ),
                        width: 140.0,
                        height: 140.0,
                      ),
                      const CircleAvatar(
                        // Profile picture
                        radius: 70.0,
                        backgroundColor: Colors.transparent,
                        child: Icon(
                          Icons.person,
                          size: 105,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.userModel.username,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.userModel.email,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 55),
                  // Action Buttons - Above Divider
                  Column(
                    children: [
                      SizedBox(
                        width: buttonWidth,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context)
                              .pushNamed('/privacy-policy'),
                          icon: const Icon(Icons.privacy_tip,
                              color: Colors.white), // White icon
                          label: const Text('Privacy Policy',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF6C06),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: buttonWidth,
                        child: ElevatedButton.icon(
                          onPressed: () => _showSupportDialog(context),
                          icon: const Icon(Icons.support, color: Colors.white),
                          label: const Text('Support',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF6C06),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: buttonWidth,
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmSignOut(context),
                          icon: const Icon(Icons.exit_to_app,
                              color: Colors.white), // White icon
                          label: const Text('Sign Out',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF6C06),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),
                  const Divider(color: Colors.grey, thickness: 2),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      SizedBox(
                        width: buttonWidth,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            overlayColor: const Color(0xFFEF6C06),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28.0),
                            ),
                          ),
                          onPressed: () => _confirmDeleteData(context),
                          child: const Text(
                            'Delete All Data',
                            style: TextStyle(
                                fontSize: 18, color: Colors.redAccent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: buttonWidth,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            overlayColor: const Color(0xFFEF6C06),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28.0),
                            ),
                          ),
                          onPressed: () => _confirmDeleteAccount(context),
                          child: const Text(
                            'Delete Account',
                            style: TextStyle(
                                fontSize: 18, color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
