import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  // Add Transaction
  Future<void> addTransaction(Transaction transaction) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toMap());
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  // Update Transaction
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transaction.id)
          .update(transaction.toMap());
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  // Delete Transaction
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transactionId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  // Get All Transactions
  Stream<List<Transaction>> getTransactions() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Transaction.fromMap(doc.data())).toList());
  }

  // Get Transactions by Date Range
  Stream<List<Transaction>> getTransactionsByDateRange(
      DateTime start, DateTime end) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Transaction.fromMap(doc.data())).toList());
  }

  // Get Transactions by Category
  Stream<List<Transaction>> getTransactionsByCategory(String category) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('category', isEqualTo: category)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Transaction.fromMap(doc.data())).toList());
  }

  // Save User Categories
  Future<void> saveUserCategories(List<String> categories) async {
    try {
      await _db.collection('users').doc(userId).set({
        'selectedCategories': categories,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save categories: $e');
    }
  }

  // Get User Categories
  Future<List<String>> getUserCategories() async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists && doc.data()?['selectedCategories'] != null) {
        return List<String>.from(doc.data()!['selectedCategories']);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }
}