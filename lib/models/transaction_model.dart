import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { expense, income }

class Transaction {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String category;
  final TransactionType type;
  final DateTime date;
  final String? note;

  Transaction({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'type': type == TransactionType.expense ? 'expense' : 'income',
      'date': Timestamp.fromDate(date),
      'note': note,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      type: map['type'] == 'expense' 
          ? TransactionType.expense 
          : TransactionType.income,
      date: (map['date'] as Timestamp).toDate(),
      note: map['note'],
    );
  }

  Transaction copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    String? category,
    TransactionType? type,
    DateTime? date,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}