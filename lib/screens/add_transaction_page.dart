import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../models.dart';

class AddTransactionPage extends StatefulWidget {
  final UserModel userModel;

  const AddTransactionPage({super.key, required this.userModel});

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _detailsController = TextEditingController();
  String _selectedType = 'Expense';
  String _selectedCategory = 'Bills';
  String _selectedAccount = 'Main';
  final List<File> _selectedPhotos = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedPhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limit Reached: You can add upto 3 images per transaction.')),
      );
      return;
    }

    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final compressedImage = await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        path.join(
          path.dirname(pickedFile.path),
          '${path.basenameWithoutExtension(pickedFile.path)}_compressed.jpg',
        ),
        quality: 70,
      );

      if (compressedImage != null) {
        setState(() {
          _selectedPhotos.add(File(compressedImage.path));
        });
      }
    }
  }

  Future<String> _uploadImage(File image) async {
    final storageRef = FirebaseStorage.instance.ref().child('transaction_photos/${path.basename(image.path)}');
    await storageRef.putFile(image);
    return await storageRef.getDownloadURL();
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final double amount = double.parse(_amountController.text);
    final String details = _detailsController.text;

    if (_selectedType == 'Expense') {
      final selectedAccount = widget.userModel.accounts.firstWhere((account) => account.name == _selectedAccount);
      if (selectedAccount.balance < amount) {
        _showAlertDialog('Insufficient Balance', 'The selected account has insufficient balance for this expense. Please add balance or select another account.');
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    List<String> photoUrls = [];
    for (var photo in _selectedPhotos) {
      final photoUrl = await _uploadImage(photo);
      photoUrls.add(photoUrl);
    }

    final transaction = TransactionModel(
      id: '',
      userId: widget.userModel.id,
      amount: amount,
      type: _selectedType,
      category: _selectedCategory,
      details: details,
      account: _selectedAccount,
      havePhotos: photoUrls.isNotEmpty,
    );

    final transactionRef = await FirebaseFirestore.instance.collection('transactions').add(transaction.toDocument());
    await _addPhotos(transactionRef.id, photoUrls);

    if (_selectedType == 'Expense') {
      _updateAccountBalance(_selectedAccount, -amount);
    } else {
      _updateAccountBalance(_selectedAccount, amount);
    }

    Navigator.of(context).pop(true); // Return true to indicate a successful transaction
  }

  Future<void> _addPhotos(String transactionId, List<String> photoUrls) async {
    for (var url in photoUrls) {
      final photo = PhotoModel(
        id: '',
        userId: widget.userModel.id,
        transactionId: transactionId,
        imageUrl: url,
      );
      await FirebaseFirestore.instance.collection('photos').add(photo.toDocument());
    }
  }

  Future<void> _updateAccountBalance(String accountName, double amount) async {
    final account = widget.userModel.accounts.firstWhere((acc) => acc.name == accountName);
    account.balance += amount;
    await FirebaseFirestore.instance.collection('users').doc(widget.userModel.id).update({
      'accounts': widget.userModel.accounts.map((account) => account.toMap()).toList(),
    });
    // widget.userModel.updateTotalBalance();
  }

  void _showAlertDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Color(0xFFEF6C06)),),
        content: Text(content),
        actions: [
          TextButton(
            child: const Text('OK',style: TextStyle(color: Color(0xFFEF6C06))),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFEF6C06),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _detailsController,
                  decoration: const InputDecoration(labelText: 'Details', border: OutlineInputBorder()),
                  maxLines: 2,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  validator: (value) {
                    if (value!.length > 50) {
                      return 'Details should be less than 50 words';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  value: _selectedType,
                  items: ['Expense', 'Income'].map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedType = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  value: _selectedCategory,
                  items: ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Other'].map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Account', border: OutlineInputBorder()),
                  value: _selectedAccount,
                  items: widget.userModel.accounts.map((Account account) {
                    return DropdownMenuItem<String>(
                      value: account.name,
                      child: Text(account.name),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedAccount = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Photos',
                      style: TextStyle(color: Colors.grey[700], fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.photo_camera, color: Color(0xFFEF6C06)),
                          onPressed: () => _pickImage(ImageSource.camera),
                        ),
                        IconButton(
                          icon: const Icon(Icons.photo_library, color: Color(0xFFEF6C06)),
                          onPressed: () => _pickImage(ImageSource.gallery),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _selectedPhotos.isNotEmpty
                    ? Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _selectedPhotos.map((photo) {
                    return Stack(
                      children: [
                        Image.file(photo, width: 100, height: 100, fit: BoxFit.cover),
                        Positioned(
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPhotos.remove(photo);
                                if (_selectedPhotos.isEmpty) {
                                  // Reset havePhotos flag if no photos are selected
                                  FirebaseFirestore.instance
                                      .collection('transactions')
                                      .doc(widget.userModel.id)
                                      .update({'havePhotos': false});
                                }
                              });
                            },
                            child: const Icon(Icons.remove_circle, color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                )
                    : const SizedBox.shrink(),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF6C06),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  onPressed: _submitTransaction,
                  child: const Text('Submit', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
