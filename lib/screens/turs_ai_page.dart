import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models.dart';

class TUrSAiPage extends StatefulWidget {
  const TUrSAiPage({super.key});

  @override
  _TUrSAiPageState createState() => _TUrSAiPageState();
}

class _TUrSAiPageState extends State<TUrSAiPage> {
  late DialogFlowtter dialogFlowtter;
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final int _maxMessageLength = 250;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _warning;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;


  @override
  void initState() {
    super.initState();
    DialogFlowtter.fromFile(
      path: "assets/dialog_flow_auth.json",
    ).then((instance) {
      dialogFlowtter = instance;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void sendMessage(String text) async {
    if (text.isEmpty || text.length > _maxMessageLength) {
      setState(() {
        _warning = text.length > _maxMessageLength
            ? "Message cannot exceed $_maxMessageLength characters."
            : null;
      });
      return;
    }

    setState(() {
      _warning = null;
      _isLoading = true;
      _messages.add({
        "message": Message(text: DialogText(text: [text])),
        "isUserMessage": true
      });
    });

    _controller.clear();
    _scrollToBottom();

    DetectIntentResponse response = await dialogFlowtter.detectIntent(
      queryInput: QueryInput(text: TextInput(text: text)),
    );

    if (response.message != null) {
      setState(() {
        _messages.add({"message": response.message, "isUserMessage": false});
        _isLoading = false;
      });
    }

    // Handle the intent responses here
    if (response.queryResult?.intent?.displayName == "Add Transaction") {
      final parameters = response.queryResult?.parameters;
      var amount = parameters?['amount'] ?? 0.0;
      final type = parameters?['type'] ?? 'Expense';
      final category = parameters?['category'] ?? 'Other';
      final account = parameters?['account'] ?? 'Main';

      if (amount is int) {
        amount = amount.toDouble();
      }

      try {
        User? user = FirebaseAuth.instance.currentUser;
        final transaction = TransactionModel(
          id: '',
          userId: user!.uid,
          amount: amount,
          type: type,
          category: category,
          details: '',
          account: account,
          havePhotos: false,
        );

        await FirebaseFirestore.instance
            .collection('transactions')
            .add(transaction.toDocument());

        if (type == 'Expense') {
          _updateAccountBalance(account, -amount);
        } else {
          _updateAccountBalance(account, amount);
        }

        setState(() {
          _messages.add({
            "message": Message(
                text: DialogText(text: const [
                  "Transaction added successfully. Please restart the app after adding all transactions to view changes."
                ])),
            "isUserMessage": false
          });
        });
      } catch (e) {
        setState(() {
          _messages.add({
            "message": Message(
                text: DialogText(
                    text: const ["Failed to add transaction. Please try again."])),
            "isUserMessage": false
          });
        });
      }
    } else if (response.queryResult?.intent?.displayName == "Expense Guidance") {
      String userId = await getCurrentUserId();
      fetchTopTransactions(userId).then((transactions) {
        if (transactions.isEmpty) {
          setState(() {
            _messages.add({
              "message": Message(text: DialogText(text: const [
                "You have no recent transactions. Please add some transactions to get personalized expense reduction advice."
              ])),
              "isUserMessage": false
            });
          });
        } else {
          String advice = generateExpenseReductionAdvice(transactions);
          setState(() {
            _messages.add({
              "message": Message(text: DialogText(text: [
                "Here are some personalized tips to help you reduce your expenses:\n$advice"
              ])),
              "isUserMessage": false
            });
          });
        }
      });
    }
    _scrollToBottom();
  }

  Future<String> getCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? '';
  }

  Future<List<Map<String, dynamic>>> fetchTopTransactions(String userId) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: "Expense")
        .orderBy('date', descending: true)
        .limit(5)
        .get();

    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  String generateExpenseReductionAdvice(
      List<Map<String, dynamic>> transactions) {
    // Analyze the top transactions and generate expense reduction advice
    double totalSpending = transactions.fold(
        0, (sum, item) => sum + item['amount']);
    String highestCategory = transactions.fold<Map<String, double>>(
        {}, (map, item) {
      String category = item['category'];
      map[category] = (map[category] ?? 0) + item['amount'];
      return map;
    }).entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return """
  1. Your total spending in the last few transactions is ₹${totalSpending.toStringAsFixed(2)}. Try to keep a budget to monitor and control your expenses.
  2. You spend the most on $highestCategory. Consider looking for cheaper alternatives or reducing the frequency of such expenses.
  3. Plan your purchases and avoid impulsive buying. Make a list of essentials and stick to it.
  4. Utilize discounts, cashback offers, and reward points to save on your regular expenses.
  5. Track your spending regularly using TrackUrSpends to identify and eliminate unnecessary expenses.
  """;
  }

  Future<void> _updateAccountBalance(String accountName, double amount) async {
    final user = FirebaseAuth.instance.currentUser;

    final userRef =
    FirebaseFirestore.instance.collection('users').doc(user?.uid);
    final userDoc = await userRef.get();

    if (userDoc.exists) {
      UserModel userModel = UserModel.fromDocument(userDoc);
      Account? accountToUpdate = userModel.accounts.firstWhere(
            (account) => account.name == accountName,
        orElse: () => Account(name: accountName, balance: 0),
      );

      accountToUpdate.balance += amount;

      await userRef.update({
        'accounts': userModel.accounts.map((account) => account.toMap()).toList()
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return _messages.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Welcome to TUrS AI!",
            style: GoogleFonts.roboto(fontSize: 18.0, color: Colors.black54),
          ),
          const SizedBox(height: 10.0),
          Text(
            "Try adding an expense: 'Add expense of 50'",
            style: GoogleFonts.roboto(fontSize: 16.0, color: Colors.black45),
          ),
          const SizedBox(height: 5.0),
          Text(
            "Or learn more: 'About App'",
            style: GoogleFonts.roboto(fontSize: 16.0, color: Colors.black45),
          ),
          const SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Hold mic to talk",
                style: GoogleFonts.roboto(fontSize: 14.0, color: Colors.black45),
              ),
              const SizedBox(width: 2.0),
              const Icon(
                Icons.mic,
                color: Colors.black45,
                size: 20
              ),
            ],
          ),
        ],
      ),
    )
        : ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return _buildLoadingIndicator();
        }
        var message = _messages[index];
        return _buildMessageItem(
            message["message"] as Message, message["isUserMessage"] as bool);
      },
    );
  }

  Widget _buildMessageItem(Message message, bool isUserMessage) {
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: isUserMessage ? const EdgeInsets.fromLTRB(35, 7, 2, 7) : const EdgeInsets.fromLTRB(2, 7, 35, 7),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isUserMessage ? const Color(0xFFFFA726) : const Color(0xFFE0E0E0),
          borderRadius: isUserMessage
              ? const BorderRadius.only(
            topLeft: Radius.circular(16.0),
            bottomLeft: Radius.circular(16.0),
            bottomRight: Radius.circular(16.0),
          )
              : const BorderRadius.only(
            topRight: Radius.circular(16.0),
            bottomLeft: Radius.circular(16.0),
            bottomRight: Radius.circular(16.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message.text?.text?.first ?? '',
          style: GoogleFonts.roboto(
            fontSize: 16.0,
            color: isUserMessage ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Future<void> _checkPermissionAndListen() async {
    if (Platform.isAndroid || Platform.isIOS) {
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        _startListening();
      } else {
        setState(() {
          _warning = 'Microphone permission not granted';
        });
      }
    }
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        // onStatus: (val) => print('onStatus: $val'),
        // onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _controller.text = val.recognizedWords;
              if (val.finalResult) {
                _isListening = false;
              }
            });
          },
        );
      } else {
        setState(() => _isListening = false);
      }
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }


  Widget _buildInputField() {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isKeyboardOpen = viewInsets.bottom > 0;

    // Adjust padding based on keyboard visibility
    final transform = isKeyboardOpen
        ? Matrix4.translationValues(0.0, 60.0, 0.0) : Matrix4.translationValues(0.0, 0.0, 0.0);

    return Container(
      transform: transform,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: const Color(0xF0D7D5D5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_warning != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                _warning!,
                style: GoogleFonts.roboto(color: Colors.red, fontSize: 14.0),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLength: _maxMessageLength,
                  cursorColor: const Color(0xFFEF6C06),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 20.0),
                    hintText: _isListening ? "Listening..." : "Type your message...",
                    hintStyle: GoogleFonts.roboto(color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF6F6F6),
                    suffixIcon: GestureDetector(
                      onLongPressStart: (_) => _checkPermissionAndListen(),
                      onLongPressEnd: (_) => _stopListening(),
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        child: Icon(
                          _isListening ? Icons.mic_off : Icons.mic,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                margin: const EdgeInsets.fromLTRB(2, 2, 4, 22),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA726), Color(0xFFF57C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () => sendMessage(_controller.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitThreeBounce(
            color: Color(0xFFFFA726),
            size: 20.0,
          ),
        ],
      ),
    );
  }
}
