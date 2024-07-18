import 'package:expense_tracker/screens/transaction_list_page.dart';
import 'package:expense_tracker/screens/turs_ai_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models.dart';
import 'account_page.dart';
import 'add_transaction_page.dart';
import 'charts_page.dart';
import 'transaction_details_page.dart';
import 'reminder_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;

  User? user;
  UserModel? userModel;
  Account? selectedAccount;

  // Variables for overview section
  String _selectedPeriod = 'This Week'; // Default period
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  Map<String, double> expenseByCategory = {};
  bool totalDataFetched = false; // Flag to indicate if all data has been fetched
  List<TransactionModel> recentTransactions = [];
  List<TransactionModel> allTransactions = [];

  final TUrSAiPage _tursAiPage = const TUrSAiPage();

  @override
  void initState() {
    super.initState();
    getUser();
  }

  Future<void> getUser() async {
    user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user!.uid).get();

      if (userDoc.exists) {
        setState(() {
          userModel = UserModel.fromDocument(userDoc);
        });

        if (userModel!.username.isEmpty) {
          promptUsernameInput(user!.uid);
        }

        // Fetch data for the default period (This Week)
        _fetchTransactionsForPeriod(_selectedPeriod);
      } else {
        await _createUserDocument(user!.uid);
        getUser();
      }
    }
  }

  Future<void> _createUserDocument(String userId) async {
    await _firestore.collection('users').doc(userId).set({
      'username': '',
      'email': user?.email,
      'accounts': [Account(name: 'Main', balance: 0.0).toMap()],
      'haveReminders': false,
    });
  }

  promptUsernameInput(String userId) async {
    String username = await showDialog(
      context: context,
      builder: (context) => UsernameInputDialog(userId: userId),
    ) ?? '';

    if (username.isNotEmpty) {
      await _firestore.collection('users').doc(userId).update({'username': username});
      getUser(); // Refresh user data after updating username
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  void _showAccountsDialog() {
    if (userModel != null && userModel!.accounts != null) {
      showDialog(
        context: context,
        builder: (context) => AccountsDialog(
          accounts: userModel!.accounts,
          onAddAccount: _addAccount,
          onUpdateBalance: _updateBalance,
          onSelectAccount: _selectAccount,
          onSelectTotalBalance: _selectTotalBalance,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Accounts not available')));
    }
  }

  Future<void> _addAccount(String name, double balance) async {
    bool accountExists = userModel!.accounts.any((account) => account.name.toLowerCase() == name.toLowerCase());

    if (accountExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account with the same name already exists!')),
      );
      return;
    }

    userModel!.accounts.add(Account(name: name, balance: balance));
    await _firestore.collection('users').doc(user!.uid).update({
      'accounts': userModel!.accounts.map((account) => account.toMap()).toList(),
    });
    getUser();
  }

  Future<void> _updateBalance(String accountName, double newBalance) async {
    var account = userModel!.accounts.firstWhere((acc) => acc.name == accountName);
    account.balance = newBalance;
    await _firestore.collection('users').doc(user!.uid).update({
      'accounts': userModel!.accounts.map((account) => account.toMap()).toList(),
    });
    getUser();
  }

  void _selectAccount(Account account) {
    setState(() {
      selectedAccount = account;
    });
    Navigator.of(context).pop();
  }

  void _selectTotalBalance() {
    setState(() {
      selectedAccount = null;
    });
    Navigator.of(context).pop();
  }

  Future<void> _fetchTransactionsForPeriod(String period) async {
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, now.day, 0, 0, 0, 0);

    switch (period) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'This Week':
        startDate = startDate.subtract(Duration(days: now.weekday - 1));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Overall':
        if (totalDataFetched) {
          return;
        }
        startDate = DateTime(1970);
        break;
      default:
        startDate = startDate.subtract(Duration(days: now.weekday - 1));
    }

    QuerySnapshot transactionDocs = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: user!.uid)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .orderBy('date', descending: true)
        .get();


    List<TransactionModel> transactions = transactionDocs.docs
        .map((doc) => TransactionModel.fromDocument(doc))
        .toList();

    _calculateOverviewData(transactions);

    if (period == 'Overall') {
      totalDataFetched = true;
      setState(() {
        allTransactions = transactions.toList();
      });
    }

    // Fetch the recent three transactions
    setState(() {
      recentTransactions = transactions.take(3).toList();
    });
  }

  void _ifPresentFilter(List<TransactionModel> transactions, String period) {
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, now.day, 0, 0, 0, 0);
    switch (period) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'This Week':
        startDate = startDate.subtract(Duration(days: now.weekday - 1));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Overall':
        startDate = DateTime(1970);
        break;
      default:
        startDate = startDate.subtract(Duration(days: now.weekday - 1));
    }
    // Filter transactions using where
    if(period != "Overall"){
    List<TransactionModel> filteredTransactions = transactions.where((transaction) {
      final transactionDate = transaction.date.toDate();
      return transactionDate.isAfter(startDate) || transactionDate.isAtSameMomentAs(startDate);
    }).toList();
    _calculateOverviewData(filteredTransactions);
    setState(() {
      recentTransactions = filteredTransactions.take(3).toList();
    });
    }
    else{
      _calculateOverviewData(transactions);
      setState(() {
        recentTransactions = transactions.take(3).toList();
      });
    }


  }

  void _calculateOverviewData(List<TransactionModel> transactions) {
    double income = 0.0;
    double expense = 0.0;
    Map<String, double> categoryExpenses = {};

    for (var transaction in transactions) {
      if (transaction.type == 'Income') {
        income += transaction.amount;
      } else {
        expense += transaction.amount;
        categoryExpenses.update(transaction.category, (value) => value + transaction.amount,
            ifAbsent: () => transaction.amount);
      }
    }

    setState(() {
      totalIncome = income;
      totalExpense = expense;
      expenseByCategory = categoryExpenses;
    });
  }

  Future<void> _initializeTransactions() async {
    if (allTransactions.isEmpty) {
      _selectedPeriod = "Overall";
      await _fetchTransactionsForPeriod("Overall");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvoked: (canPop){
        if (!canPop) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: userModel == null
            ? const Center(
          child: CircularProgressIndicator(color: Color(0xFFEF6C06)),
        )
            : _buildBody(),
        bottomNavigationBar: CustomNavigationBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFEF6C06),
          onPressed: () async {
            bool? result = await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => AddTransactionPage(userModel: userModel!),
            ));

            if (result == true) {
              totalDataFetched = false;
              getUser();
            }
          },
          child: const Icon(Icons.add, size: 40, color: Colors.white),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    switch (_selectedIndex) {
      case 0:
        return AppBar(
          toolbarHeight: 73.0,
          shadowColor: Colors.black,
          surfaceTintColor: Colors.white,
          title: Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 16.0),
            child: Text(
              'Hi ${userModel?.username ?? ''},',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 18.0),
              child: IconButton(
                icon: const Icon(Icons.account_circle_rounded,
                    size: 50, color: Color(0xFFEF6C06)),
                onPressed: () {
                  String? currentUserId = user?.uid;
                  if (currentUserId != null && userModel != null) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => AccountPage(userModel: userModel!),
                    ));
                  }
                },
              ),
            ),
          ],
        );
      case 1:
        return AppBar(
          backgroundColor: const Color(0xFFEF6C06),
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Charts',
            style: TextStyle(color: Colors.white),
          ),
        );
      case 2:
        return AppBar(
          backgroundColor: const Color(0xFFEF6C06),
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Reminders',
            style: TextStyle(color: Colors.white),
          ),
        );
      case 3:
        return AppBar(
          backgroundColor: const Color(0xFFEF6C06),
          title: const Text(
            'TrackUrSpends AI',
            style: TextStyle(color: Colors.white),
          ),
        );
      default:
        return AppBar();
    }
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        _selectedIndex == 0 ? _buildHomeContent() : Container(),
        _selectedIndex == 1 ? _buildChartsContent() : Container(),
        _selectedIndex == 2 ? _buildRemindersContent() : Container(),
        _tursAiPage,
      ],
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22.0, 16.0, 22.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _showAccountsDialog,
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF6C06),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Colors.white),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedAccount != null ? selectedAccount!.name : 'Total Balance',
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₹${selectedAccount != null ? selectedAccount!.balance.toString() : userModel!.totalBalance}',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildOverviewSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsContent() {
    return FutureBuilder<void>(
      future: _initializeTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFEF6C06)));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return ChartsPage(
            allTransactions: allTransactions,
            userId: user!.uid,
          );
        }
      },
    );
  }

  Widget _buildRemindersContent() {
    return ReminderPage(userId: user!.uid, haveReminders: userModel!.haveReminders);
  }


  Widget _buildOverviewSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: const Color(0xE4FF7105)),
                  color: const Color(0xDDFFD9C4),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  dropdownColor: const Color(0xDDFFD9C4),
                  borderRadius: BorderRadius.circular(8.0),
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xE4FF7105)),
                  underline: const SizedBox(),
                  items: ['Today', 'This Week', 'This Month', 'Overall']
                      .map((period) => DropdownMenuItem<String>(
                    value: period,
                    child: Text(period, style: const TextStyle(color: Color(
                        0xFFF35805))),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPeriod = value;
                      });
                      if (!totalDataFetched) {
                        _fetchTransactionsForPeriod(value);
                      }
                      else {
                        _ifPresentFilter(allTransactions, value);
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIncomeExpenseBox('Expense', totalExpense, false),
              const SizedBox(width: 10), // Gap between boxes
              _buildIncomeExpenseBox('Income', totalIncome, true),
            ],
          ),
          const SizedBox(height: 20),
          _buildPieChart(),
          const SizedBox(height: 20),
          _buildTransactionList(),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseBox(String title, double amount, bool isIncome) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(7.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 0.4,
              blurRadius: 3,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotatedBox(
              quarterTurns: -1,
              child: Icon(
                isIncome ? Icons.arrow_circle_right : Icons.arrow_circle_left,
                size: 45,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              '₹${amount.toString()}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildPieChart() {
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(7.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            const Text('Expenses by Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(),
                        centerSpaceRadius: 50,
                        sectionsSpace: 0,
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                              return;
                            }
                            final touchedSection = pieTouchResponse.touchedSection!;
                            final touchedIndex = touchedSection.touchedSectionIndex;
                            setState(() {
                              _touchedIndex = touchedIndex;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: expenseByCategory.keys.map((category) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            color: _getCategoryColor(category),
                          ),
                          const SizedBox(width: 5),
                          Text(category, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _touchedIndex = -1;

  List<PieChartSectionData> _buildPieChartSections() {
    if (expenseByCategory.isEmpty) {
      return [PieChartSectionData(color: Colors.grey)];
    }

    List<PieChartSectionData> sections = [];
    final totalAmount = expenseByCategory.values.fold(0.0, (sum, amount) => sum + amount);

    expenseByCategory.forEach((category, amount) {
      final percentage = (amount / totalAmount) * 100;
      sections.add(PieChartSectionData(
        value: amount,
        title: _touchedIndex == expenseByCategory.keys.toList().indexOf(category)
            ? '${percentage.toStringAsFixed(1)}%'
            : '',
        color: _getCategoryColor(category),
      ));
    });

    return sections;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.yellow;
      case 'Bills':
        return Colors.purpleAccent;
      case 'Transport':
        return Colors.pink;
      case 'Shopping':
        return Colors.green;
      case 'Entertainment':
        return Colors.cyan;
      case 'Other':
        return const Color(0xFFEF6C06);
      default :
        return Colors.grey;
    }
  }

  Widget _buildTransactionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Transactions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () async{
                await _initializeTransactions();
                bool? result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TransactionListPage(
                      userId: user!.uid,
                      transactions: totalDataFetched ? allTransactions : [],
                    ),
                  ),
                );
                if (result == true) {
                  totalDataFetched = false;
                  getUser();
                }
              },
              child: const Text('View all', style: TextStyle(color: Color(0xFFEF6C06), fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        recentTransactions.isEmpty
            ? const Text('No Transactions Yet', style: TextStyle(fontSize: 16))
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentTransactions.length,
          itemBuilder: (context, index) {
            TransactionModel transaction = recentTransactions[index];
            return ListTile(
              leading: Icon(
                _getCategoryIcon(transaction.category),
                color: _getCategoryColor(transaction.category),
              ),
              title: Text(transaction.category, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                "${transaction.date.toDate().toLocal().day}/${transaction.date.toDate().toLocal().month}/${transaction.date.toDate().toLocal().year}", // Format date as dd-mm-yyyy
              ),
              trailing: Text(
                '₹${transaction.amount.toString()}',
                style: TextStyle(
                  color: transaction.type == 'Income' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async{
                bool? result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TransactionDetailsPage(transaction: transaction),
                  ),
                );
                if (result == true) {
                  totalDataFetched = false;
                  getUser();
                }
              },
            );
          },
        ),
      ],
    );
  }


  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.fastfood;
      case 'Bills':
        return Icons.receipt;
      case 'Transport':
        return Icons.directions_car;
      case 'Shopping':
        return Icons.shopping_cart;
      case 'Entertainment':
        return Icons.movie;
      case 'Other':
        return Icons.category;
      default:
        return Icons.help_outline;
    }
  }
}

class UsernameInputDialog extends StatefulWidget {
  final String userId;

  const UsernameInputDialog({super.key, required this.userId});

  @override
  _UsernameInputDialogState createState() => _UsernameInputDialogState();
}

class _UsernameInputDialogState extends State<UsernameInputDialog> {
  final TextEditingController _usernameController = TextEditingController();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Username', style: TextStyle(color: Color(0xFFEF6C06))),
      content: Column(
        mainAxisSize: MainAxisSize.min, // Avoid unnecessary space
        children: [
          TextField(
            controller: _usernameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Username',
              errorText: _errorMessage, // Display error message below the field
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('OK', style: TextStyle(color: Color(0xFFEF6C06))),
          onPressed: () async {
            String username = _usernameController.text.trim();
            setState(() { // Update UI for error message
              if (username.isEmpty) {
                _errorMessage = 'Username cannot be empty';
              } else if (username.length > 25) {
                _errorMessage = 'Username should be smaller than 25 characters';
              } else {
                _errorMessage = null;
              }
            });

            if (username.isNotEmpty && username.length <= 25) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .update({'username': username});
              Navigator.of(context).pop(username);
            }
          },
        ),
      ],
    );
  }
}

class AccountsDialog extends StatefulWidget {
  final List<Account> accounts;
  final Function(String, double) onAddAccount;
  final Function(String, double) onUpdateBalance;
  final Function(Account) onSelectAccount;
  final VoidCallback onSelectTotalBalance;

  const AccountsDialog({
    super.key,
    required this.accounts,
    required this.onAddAccount,
    required this.onUpdateBalance,
    required this.onSelectAccount,
    required this.onSelectTotalBalance,
  });

  @override
  _AccountsDialogState createState() => _AccountsDialogState();
}

class _AccountsDialogState extends State<AccountsDialog> {
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  bool _showAddAccountFields = false;
  String _errorMessage = "";

  void _saveAccount() {
    setState(() {
      _errorMessage = "";

      if (_accountNameController.text.isEmpty) {
        _errorMessage = 'Account name cannot be empty';
      } else if (_accountNameController.text.length > 50) {
        _errorMessage = 'Account name too long';
      }else if (_balanceController.text.isEmpty) {
        _errorMessage = 'Balance cannot be empty';
      } else if (widget.accounts.length == 5) {
        _errorMessage = 'Cannot add more than 5 accounts';
      } else {
        double? balance = double.tryParse(_balanceController.text);
        if (balance == null) {
          _errorMessage = 'Invalid balance amount';
        } else {
          bool accountExists = widget.accounts.any(
                  (account) => account.name.toLowerCase() == _accountNameController.text.toLowerCase().trim());
          if (accountExists) {
            _errorMessage = 'Account with the same name already exists!';
          } else {
            widget.onAddAccount(_accountNameController.text, balance);
            _accountNameController.clear();
            _balanceController.clear();
            Navigator.of(context).pop();
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Accounts'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            ListBody(
              children: [
                ListTile(
                  title: const Text('Total Balance', style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.account_balance_wallet),
                  onTap: widget.onSelectTotalBalance,
                ),
                ...widget.accounts.map(
                      (account) => ListTile(
                    title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('₹${account.balance.toString()}', style: const TextStyle(color: Color(0xFFEF6C06), fontSize: 12.0)),
                        IconButton(
                          padding: const EdgeInsets.fromLTRB(28.0, 0.0, 0.0, 0.0),
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _balanceController.text = account.balance.toString();
                            _showUpdateBalanceDialog(account.name);
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      widget.onSelectAccount(account);
                    },
                  ),
                ),
              ],
            ),
            const Divider(),
            _showAddAccountFields
                ? Column(
              children: [
                const SizedBox(height: 10),
                TextField(
                  controller: _accountNameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _balanceController,
                  decoration: const InputDecoration(
                    labelText: 'Initial Balance',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            )
                : const SizedBox.shrink(),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton.icon(
          icon: Icon(
            _showAddAccountFields ? Icons.remove : Icons.add,
            color: const Color(0xFFEF6C06),
          ),
          label: Text(
            _showAddAccountFields ? 'Cancel' : 'Add Account',
            style: const TextStyle(color: Color(0xFFEF6C06)),
          ),
          onPressed: () {
            setState(() {
              _showAddAccountFields = !_showAddAccountFields;
            });
          },
        ),
        if (_showAddAccountFields)
          TextButton(
            onPressed: _saveAccount,
            child: const Text('Save Account', style: TextStyle(color: Color(0xFFEF6C06))),
          ),
        TextButton(
          child: const Text('Close', style: TextStyle(color: Color(0xFFEF6C06))),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  void _showUpdateBalanceDialog(String accountName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Balance for $accountName account'),
        content: TextField(
          controller: _balanceController,
          decoration: const InputDecoration(
            labelText: 'New Balance',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            child: const Text('Update', style: TextStyle(color: Color(0xFFEF6C06))),
            onPressed: () {
              double? newBalance = double.tryParse(_balanceController.text);
              if (newBalance != null) {
                widget.onUpdateBalance(accountName, newBalance);
                _balanceController.clear();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            },
          ),
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFEF6C06))),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class CustomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const CustomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xE8FFFFFF),
      selectedItemColor: const Color(0xFFEF6C06),
      unselectedItemColor: const Color(0xFF2C2C2C),
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(Icons.home),
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(Icons.bar_chart),
          ),
          label: 'Charts',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Icon(Icons.notifications),
          ),
          label: 'Reminder',
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Icon(Icons.all_inclusive),
          ),
          label: 'TUrS AI',
        ),
      ],
    );
  }
}

