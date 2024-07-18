import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import '../models.dart';
import 'transaction_details_page.dart';

class TransactionListPage extends StatefulWidget {
  final String userId;
  final List<TransactionModel>? transactions;

  const TransactionListPage(
      {super.key, required this.userId, this.transactions});

  @override
  _TransactionListPageState createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  String _selectedPeriod = 'This Month';
  bool _isLoading = true;
  DateTimeRange? _customDateRange;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );

    if (widget.transactions != null && widget.transactions!.isNotEmpty) {
      _transactions = widget.transactions!;
      _filterTransactions(_selectedPeriod);
      _isLoading = false;
    } else {
      _fetchAllTransactions();
    }
  }

  Future<void> _fetchAllTransactions() async {
    QuerySnapshot transactionDocs = await FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: widget.userId)
        .orderBy('date', descending: true)
        .get();

    setState(() {
      _transactions = transactionDocs.docs
          .map((doc) => TransactionModel.fromDocument(doc))
          .toList();
      _filterTransactions(_selectedPeriod);
      _isLoading = false;
    });
  }

  void _filterTransactions(String period) {
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
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'Overall':
        startDate = DateTime(1970);
        break;
      case 'Custom':
        if (_customDateRange != null) {
          startDate = _customDateRange!.start;
          setState(() {
            _filteredTransactions = _transactions.where((transaction) {
              DateTime transactionDate = transaction.date.toDate();
              return transactionDate.isAfter(startDate) &&
                  transactionDate.isBefore(_customDateRange!.end
                      .add(const Duration(hours: 23, minutes: 59)));
            }).toList();
          });
          return;
        } else {
          startDate = DateTime(1970);
        }
        break;
      default:
        startDate = DateTime(1970);
    }

    setState(() {
      _selectedPeriod = period;
      _filteredTransactions = _transactions.where((transaction) {
        final transactionDate = transaction.date.toDate();
        return transactionDate.isAfter(startDate) || transactionDate.isAtSameMomentAs(startDate);
      }).toList();
    });
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _customDateRange) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = 'Custom';
        _filterTransactions('Custom');
      });
    }
  }

  Future<void> _showDownloadDialog() async {
    await Permission.notification.request();
    var notificationStatus = await Permission.notification.status;
    await Permission.manageExternalStorage.request();
    var storageStatus = await Permission.manageExternalStorage.status;
    if (storageStatus.isDenied || notificationStatus.isDenied) {
      const SnackBar(
          content: Text("Please give permissions in order to download")
      );
    }
    String selectedDownloadPeriod = _selectedPeriod;
    String selectedOption = 'All Transactions';

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Download Transactions'),
          titleTextStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFEF6C06),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      border:
                          Border.all(width: 2, color: const Color(0xE4FF7105)),
                      color: const Color(0xEEFFD9C4),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: DropdownButton<String>(
                      value: selectedDownloadPeriod,
                      dropdownColor: const Color(0xDDFFD9C4),
                      borderRadius: BorderRadius.circular(8.0),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xE4FF7105)),
                      underline: const SizedBox(),
                      items: [
                        'Today',
                        'This Week',
                        'This Month',
                        'This Year',
                        'Overall',
                        'Custom'
                      ]
                          .map((period) => DropdownMenuItem<String>(
                                value: period,
                                child: Text(
                                  period,
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          if (value == 'Custom') {
                            _selectCustomDateRange(context).then((_) {
                              setState(() {
                                selectedDownloadPeriod = 'Custom';
                              });
                            });
                          } else {
                            setState(() {
                              selectedDownloadPeriod = value;
                            });
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: ['All Transactions', 'Income', 'Expense']
                        .map((String key) {
                      return RadioListTile<String>(
                        title: Text(key),
                        value: key,
                        activeColor: const Color(0xE4FF7105),
                        groupValue: selectedOption,
                        onChanged: (String? value) {
                          setState(() {
                            selectedOption = value ?? 'All Transactions';
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFFEF6C06))),
            ),
            TextButton(
              onPressed: () {
                _downloadTransactions(
                    selectedDownloadPeriod, selectedOption, 'CSV');
                Navigator.of(context).pop();
                const SnackBar(
                    content: Text("Downloading...")
                );
              },
              child: const Text('Download as CSV',
                  style: TextStyle(color: Color(0xFFEF6C06))),
            ),
            TextButton(
              onPressed: () {
                _downloadTransactions(
                    selectedDownloadPeriod, selectedOption, 'PDF');
                Navigator.of(context).pop();
                const SnackBar(
                    content: Text("Downloading...")
                );
              },
              child: const Text('Download as PDF',
                  style: TextStyle(color: Color(0xFFEF6C06))),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadTransactions(
      String period, String option, String format) async {
    List<TransactionModel> transactionsToDownload;

    // Filter transactions based on period
    if (period != 'Overall') {
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
        case 'This Year':
          startDate = DateTime(now.year, 1, 1);
          break;
        case 'Custom':
          if (_customDateRange != null) {
            startDate = _customDateRange!.start;
            transactionsToDownload = _transactions.where((transaction) {
              DateTime transactionDate = transaction.date.toDate();
              return transactionDate.isAfter(startDate) &&
                  transactionDate.isBefore(_customDateRange!.end
                      .add(const Duration(hours: 23, minutes: 59)));
            }).toList();
            break;
          } else {
            startDate = DateTime(1970);
          }
          break;
        default:
          startDate = DateTime(1970);
      }

      transactionsToDownload = _transactions
          .where((transaction) {
        final transactionDate = transaction.date.toDate();
        return transactionDate.isAfter(startDate) || transactionDate.isAtSameMomentAs(startDate);
      })
          .toList();
    } else {
      transactionsToDownload = List.from(_transactions);
    }

    // Further filter transactions based on option (All, Income, Expense)
    if (option != 'All Transactions') {
      transactionsToDownload = transactionsToDownload
          .where((transaction) => transaction.type == option)
          .toList();
    }

    if (transactionsToDownload.isEmpty) {
      const SnackBar(content: Text("No transactions for selected period"));
    } else {
      // Download in selected format
      if (format == 'CSV') {
        await _downloadCSV(transactionsToDownload);
      } else if (format == 'PDF') {
        await _downloadPDF(transactionsToDownload);
      }
    }
  }

  Future<void> _downloadCSV(List<TransactionModel> transactions) async {
    List<List<dynamic>> csvData = [
      ['Category', 'Date', 'Amount(in Rs.)', 'Type']
    ];

    for (var transaction in transactions) {
      csvData.add([
        transaction.category,
        "${transaction.date.toDate().toLocal().day.toString().padLeft(2, '0')}/${transaction.date.toDate().toLocal().month.toString().padLeft(2, '0')}/${transaction.date.toDate().toLocal().year}",
        (transaction.amount.toString()),
        transaction.type,
      ]);
    }

    String csvString = const ListToCsvConverter().convert(csvData);
    final path =
        "/storage/emulated/0/Download/transactions_TrackUrSpends_${DateTime.now().millisecondsSinceEpoch}.csv";
    final file = File(path);
    await file.writeAsString(csvString);

    _showNotification(
        "CSV Downloaded", "Your CSV file has been downloaded to $path", path);
  }

  Future<void> _downloadPDF(List<TransactionModel> transactions) async {
    final pdf = pw.Document();

    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/OpenSans-Regular.ttf'),
    );

    final img = await rootBundle.load('assets/images/logo.png');
    final imageBytes = img.buffer.asUint8List();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20.0),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(
                  pw.MemoryImage(imageBytes),
                  height: 50.0,
                ),
                pw.Text(
                  'TrackUrSpends Transaction Report',
                  style: pw.TextStyle(
                    fontSize: 24.0,
                    fontWeight: pw.FontWeight.bold,
                    font: font,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20.0),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Transactions',
                  style: pw.TextStyle(
                    fontSize: 16.0,
                    fontWeight: pw.FontWeight.bold,
                    font: font,
                  ),
                ),

                pw.Text(
                  'Downloaded on ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 10.0,
                    color: PdfColors.grey,
                    font: font,
                  ),
                ),
              ],
            ),

            pw.Divider(),

            pw.ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final formattedDate =
                    "${transaction.date.toDate().day.toString().padLeft(2, '0')}/${transaction.date.toDate().month.toString().padLeft(2, '0')}/${transaction.date.toDate().year} ${transaction.date.toDate().hour.toString().padLeft(2, '0')}:${transaction.date.toDate().minute.toString().padLeft(2, '0')}";
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10.0),
                  padding: const pw.EdgeInsets.all(10.0),
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(10.0),
                    color: transaction.type == 'Expense'
                        ? PdfColors.red100
                        : PdfColors.green100,
                    border: pw.Border.all(
                      color: transaction.type == 'Expense'
                          ? PdfColors.red900
                          : PdfColors.green900,
                      width: 1.0,
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            transaction.category,
                            style: pw.TextStyle(
                              fontSize: 16.0,
                              fontWeight: pw.FontWeight.bold,
                              font: font,
                            ),
                          ),
                          pw.Text(
                            'Rs. ${transaction.amount.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 16.0,
                              fontWeight: pw.FontWeight.bold,
                              color: transaction.type == 'Expense'
                                  ? PdfColors.red
                                  : PdfColors.green,
                              font: font,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8.0),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Date: ',
                            style: pw.TextStyle(
                              fontSize: 14.0,
                              fontWeight: pw.FontWeight.bold,
                              font: font,
                            ),
                          ),
                          pw.Text(
                            formattedDate,
                            style: pw.TextStyle(
                              fontSize: 14.0,
                              font: font,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4.0),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Account: ',
                            style: pw.TextStyle(
                              fontSize: 14.0,
                              fontWeight: pw.FontWeight.bold,
                              font: font,
                            ),
                          ),
                          pw.Text(
                            transaction.account,
                            style: pw.TextStyle(
                              fontSize: 14.0,
                              font: font,
                            ),
                          ),
                        ],
                      ),
                      if (transaction.details != null &&
                          transaction.details!.isNotEmpty)
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.SizedBox(height: 4.0),
                            pw.Text(
                              'Details: ',
                              style: pw.TextStyle(
                                fontSize: 14.0,
                                fontWeight: pw.FontWeight.bold,
                                font: font,
                              ),
                            ),
                            pw.Text(
                              transaction.details!,
                              style: pw.TextStyle(
                                fontSize: 14.0,
                                font: font,
                              ),
                            ),
                          ],
                        ),
                      pw.SizedBox(height: 4.0),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Photos Attached: ',
                            style: pw.TextStyle(
                              fontSize: 14.0,
                              fontWeight: pw.FontWeight.bold,
                              font: font,
                            ),
                          ),
                          pw.Text(
                            transaction.havePhotos ? 'Yes' : 'No',
                            style: pw.TextStyle(
                              fontSize: 14.0,
                              font: font,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ];
        },
      ),
    );

    final path =
        "/storage/emulated/0/Download/transactions_TrackUrSpends_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    _showNotification(
        "PDF Downloaded", "Your PDF file has been downloaded to $path", path);
  }

  Future<void> _showNotification(
      String title, String body, String filePath) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: filePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color(0xFFEF6C06),
        title:
            const Text('Transactions', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white), // White icons
        actions: [
          IconButton(
            highlightColor: Colors.transparent,
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            padding: const EdgeInsets.only(right: 12.0, bottom: 3.0),
            onPressed: _showDownloadDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFEF6C06)),
            )
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            border: Border.all(
                                width: 2, color: const Color(0xE4FF7105)),
                            color: const Color(0xEEFFD9C4),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedPeriod,
                            dropdownColor: const Color(0xDDFFD9C4),
                            borderRadius: BorderRadius.circular(8.0),
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Color(0xE4FF7105)),
                            underline: const SizedBox(),
                            items: [
                              'Today',
                              'This Week',
                              'This Month',
                              'This Year',
                              'Overall',
                              'Custom'
                            ]
                                .map((period) => DropdownMenuItem<String>(
                                      value: period,
                                      child: Text(
                                        period,
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                if (value == 'Custom') {
                                  _selectCustomDateRange(context);
                                } else {
                                  _filterTransactions(value);
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _filteredTransactions.isEmpty
                        ? const Center(
                            child: Text('No Transactions Yet',
                                style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.builder(
                            itemCount: _filteredTransactions.length,
                            itemBuilder: (context, index) {
                              TransactionModel transaction =
                                  _filteredTransactions[index];
                              return ListTile(
                                leading: Icon(
                                  _getCategoryIcon(transaction.category),
                                  color:
                                      _getCategoryColor(transaction.category),
                                ),
                                title: Text(transaction.category,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  "${transaction.date.toDate().toLocal().day.toString().padLeft(2, '0')}/${transaction.date.toDate().toLocal().month.toString().padLeft(2, '0')}/${transaction.date.toDate().toLocal().year}",
                                ),
                                trailing: Text(
                                  '₹${transaction.amount.toString()}',
                                  style: TextStyle(
                                    color: transaction.type == 'Income'
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () async {
                                  bool? result =
                                      await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TransactionDetailsPage(
                                              transaction: transaction),
                                    ),
                                  );
                                  if (result == true) {
                                    Navigator.of(context).pop(true);
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
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
      default:
        return Colors.grey;
    }
  }
}
