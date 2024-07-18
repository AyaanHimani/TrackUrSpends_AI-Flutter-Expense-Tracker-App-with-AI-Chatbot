import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';


class TransactionDetailsPage extends StatelessWidget {
  final TransactionModel transaction;


  const TransactionDetailsPage({super.key, required this.transaction});

  Future<List<PhotoModel>> _fetchTransactionPhotos(String userId, String transactionId) async {
    if (!transaction.havePhotos) {
      return [];
    }
    QuerySnapshot photoQuery = await FirebaseFirestore.instance
        .collection('photos')
        .where('userId', isEqualTo: userId)
        .where('transactionId', isEqualTo: transactionId)
        .get();

    return photoQuery.docs.map((doc) => PhotoModel.fromDocument(doc)).toList();
  }

  Future<void> _deleteTransaction(BuildContext context) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Transaction', style: TextStyle(color: Color(0xFFEF6C06), fontWeight: FontWeight.bold)),
          content: const Text(
              'Deleting this transaction can cause inconsistency to the respective account, are you sure you want to delete?', style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFEF6C06))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Color(0xFFEF6C06))),
            ),
          ],
        );
      },
    );

    if (confirmed) {
      await FirebaseFirestore.instance.collection('transactions').doc(transaction.id).delete();
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _editTransaction(BuildContext context) async {
    final TextEditingController detailsController = TextEditingController(text: transaction.details);
    final TextEditingController dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(transaction.date.toDate()));

    // List of available categories
    final List<String> categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Other'];

    String selectedCategory = transaction.category;

    bool edited = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Transaction', style: TextStyle(color: Color(0xFFEF6C06), fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField(
                value: selectedCategory,
                icon: const Icon(Icons.arrow_drop_down),
                items: categories.map((String category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                )).toList(),
                onChanged: (String? newValue) {
                  selectedCategory = newValue!;
                },
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(labelText: 'Details'),
              ),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date (dd/mm/yyyy)'),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: transaction.date.toDate(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );

                  if (pickedDate != null) {
                    dateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFEF6C06))),
            ),
            TextButton(
              onPressed: () async {
                String newDetails = detailsController.text;
                DateTime newDate = DateFormat('dd/MM/yyyy').parse(dateController.text);

                await FirebaseFirestore.instance.collection('transactions').doc(transaction.id).update({
                  'category': selectedCategory,
                  'details': newDetails,
                  'date': Timestamp.fromDate(newDate),
                });

                Navigator.of(context).pop(true);
              },
              child: const Text('Save', style: TextStyle(color: Color(0xFFEF6C06))),
            ),
          ],
        );
      },
    );

    if (edited) {
      Navigator.of(context).pop(true);
    }
  }


  Future<void> _downloadImage(BuildContext context, String url) async {
    try {
      // Format the current date and time
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);
      final filePath = "/storage/emulated/0/DCIM/TrackUrSpends/transaction_photo_$formattedDate.jpg";

      // Download the file
      await Dio().download(url, filePath);

      // Notify the user of the successful download
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image downloaded to $filePath')),
      );
    } catch (e) {
      // Handle any errors during the download
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading image: $e')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Transaction Details', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFEF6C06),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildTransactionDetails(),
              const SizedBox(height: 16),
              _buildPhotosSection(),
              transaction.havePhotos ? const SizedBox(height: 100) : const SizedBox(height: 193),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await _editTransaction(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF6C06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(150, 40),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await _deleteTransaction(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(150, 40),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(_getCategoryIcon(transaction.category), color: _getCategoryColor(transaction.category), size: 36),
        const SizedBox(width: 10),
        Text(
          transaction.category,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionDetails() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow("Category", transaction.category),
            const Divider(),
            _buildDetailRow("Amount", "₹${transaction.amount.toString()}"),
            const Divider(),
            _buildDetailRow("Date", DateFormat('dd/MM/yyyy').format(transaction.date.toDate())),
            const Divider(),
            _buildDetailRow("Type", transaction.type),
            const Divider(),
            _buildDetailRow("Account", transaction.account),
            const Divider(),
            _buildDetailRow("Details", transaction.details ?? "No additional details"),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Photos",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<PhotoModel>>(
          future: _fetchTransactionPhotos(transaction.userId, transaction.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFEF6C06),
                ),
              );
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Error fetching photos'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No photos added'));
            }

            List<PhotoModel> photos = snapshot.data!;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Image.network(
                      photos[index].imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () async {
                          await _downloadImage(context, photos[index].imageUrl);
                        },
                        child: const Icon(
                          Icons.download,
                          color: Color(0xFFEF6C06),
                        ),
                      ),
                    ),
                  ],
                );
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
