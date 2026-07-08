import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';
import 'package:spendsense/models/transaction_model.dart' as app;

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get userId => ApiService.currentUser?['_id'];

  // Add Transaction
  Future<void> addTransaction(app.Transaction transaction) async {
    try {
      final uid = userId;
      if (uid == null) throw Exception('User not logged in');

      await _db
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toJson());
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  // Update Transaction
  Future<void> updateTransaction(app.Transaction transaction) async {
    try {
      final uid = userId;
      if (uid == null) throw Exception('User not logged in');

      await _db
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .doc(transaction.id)
          .update(transaction.toJson());
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  // Delete Transaction
  Future<void> deleteTransaction(String transactionId) async {
    try {
      final uid = userId;
      if (uid == null) throw Exception('User not logged in');

      await _db
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .doc(transactionId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  // RESTORE transaction (for undo functionality)
  Future<void> restoreTransaction(app.Transaction transaction) async {
    try {
      final uid = userId;
      if (uid == null) throw Exception('User not logged in');

      // Restore the transaction with its original ID
      await _db
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toJson());

      print('Transaction restored successfully: ${transaction.id}');
    } catch (e) {
      throw Exception('Failed to restore transaction: $e');
    }
  }

  // Get Transactions Stream
  Stream<List<app.Transaction>> getTransactions() {
    final uid = userId;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => app.Transaction.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  // Get Transactions by Category
  Stream<List<app.Transaction>> getTransactionsByCategory(String category) {
    final uid = userId;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('category', isEqualTo: category)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => app.Transaction.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  // Get Transactions by Date Range
  Stream<List<app.Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    final uid = userId;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => app.Transaction.fromJson(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  // Save user categories
  Future<void> saveUserCategories(List<String> categories) async {
    try {
      final uid = userId;
      if (uid == null) throw Exception('User not logged in');

      await _db.collection('users').doc(uid).set({
        'categories': categories,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save categories: $e');
    }
  }

  // Get user categories
  Future<List<String>> getUserCategories() async {
    try {
      final uid = userId;
      if (uid == null) return [];

      final doc = await _db.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('categories')) {
          return List<String>.from(data['categories'] as List);
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }
}
