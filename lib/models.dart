import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String id;
  String username;
  String email;
  List<Account> accounts;
  bool haveReminders;

  UserModel({
    required this.id,
    this.username = '',
    this.email = '',
    List<Account>? accounts,
    this.haveReminders = false,
  })  : accounts = accounts ?? [Account(name: 'main', balance: 0.0)];

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    var accountList = (doc['accounts'] as List<dynamic>?)
        ?.map((account) => Account.fromMap(account))
        .toList() ?? [Account(name: 'main', balance: 0.0)];

    return UserModel(
      id: doc.id,
      username: doc['username'] ?? '',
      email: doc['email'] ,
      accounts: accountList,
      haveReminders: doc['haveReminders'] ?? false,
    );
  }


  Map<String, dynamic> toDocument() {
    return {
      'username': username,
      'email': email,
      'accounts': accounts.map((account) => account.toMap()).toList(),
      'haveReminders': haveReminders,
    };
  }

  double get totalBalance {
    return accounts.fold(0.0, (sum, account) => sum + account.balance);
  }
}

class Account {
  String name;
  double balance;

  Account({
    required this.name,
    required this.balance,
  });

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      name: map['name'],
      balance: map['balance']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'balance': balance,
    };
  }
}

class TransactionModel {
  String id;
  String userId;
  double amount;
  String type;
  String category;
  Timestamp date;
  bool havePhotos;
  String? details;
  String account;

  TransactionModel({
    required this.id,
    this.userId = '',
    this.amount = 0.0,
    this.type = '',
    this.category = '',
    Timestamp? date,
    this.havePhotos = false,
    this.details,
    this.account = 'main',
  }) : date = date ?? Timestamp.now();

  factory TransactionModel.fromDocument(DocumentSnapshot doc) {
    return TransactionModel(
      id: doc.id,
      userId: doc['userId'] ?? '',
      amount: doc['amount']?.toDouble() ?? 0.0,
      type: doc['type'] ?? '',
      category: doc['category'] ?? '',
      date: doc['date'] ?? Timestamp.now(),
      havePhotos: doc['havePhotos'] ?? false,
      details: doc['details'],
      account: doc['account'] ?? 'main',
    );
  }

  Map<String, dynamic> toDocument() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date,
      'havePhotos': havePhotos,
      'details': details,
      'account': account,
    };
  }
}

class PhotoModel {
  String id;
  String userId;
  String transactionId;
  String imageUrl;

  PhotoModel({
    required this.id,
    this.userId = '',
    this.transactionId = '',
    this.imageUrl = '',
  });

  factory PhotoModel.fromDocument(DocumentSnapshot doc) {
    return PhotoModel(
      id: doc.id,
      userId: doc['userId'] ?? '',
      transactionId: doc['transactionId'] ?? '',
      imageUrl: doc['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toDocument() {
    return {
      'userId': userId,
      'transactionId': transactionId,
      'imageUrl': imageUrl,
    };
  }
}

class ReminderModel {
  String id;
  String userId;
  Timestamp date;
  String message;
  String frequency;

  ReminderModel({
    required this.id,
    this.userId = '',
    Timestamp? date,
    this.message = '',
    this.frequency = 'Once',
  }) : date = date ?? Timestamp.now();

  factory ReminderModel.fromDocument(DocumentSnapshot doc) {
    return ReminderModel(
      id: doc.id,
      userId: doc['userId'] ?? '',
      date: doc['date'] ?? Timestamp.now(),
      message: doc['message'] ?? '',
      frequency: doc['frequency'] ?? 'Once',
    );
  }

  Map<String, dynamic> toDocument() {
    return {
      'userId': userId,
      'date': date,
      'message': message,
      'frequency': frequency,
    };
  }
}

