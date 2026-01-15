import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';

class TransactionProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Transaction> _transactions = [];
  List<String> _selectedCategories = [];
  bool _isLoading = false;

  List<Transaction> get transactions => _transactions;
  List<String> get selectedCategories => _selectedCategories;
  bool get isLoading => _isLoading;

  // Listen to transactions
  void listenToTransactions() {
    _firestoreService.getTransactions().listen((transactions) {
      _transactions = transactions;
      notifyListeners();
    });
  }

  // Add transaction
  Future<void> addTransaction(Transaction transaction) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _firestoreService.addTransaction(transaction);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update transaction
  Future<void> updateTransaction(Transaction transaction) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _firestoreService.updateTransaction(transaction);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _firestoreService.deleteTransaction(id);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get transactions by date range
  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _transactions.where((t) {
      return t.date.isAfter(start.subtract(const Duration(days: 1))) &&
          t.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Get transactions by category
  List<Transaction> getTransactionsByCategory(String category) {
    return _transactions.where((t) => t.category == category).toList();
  }

  // Calculate total for date range
  double getTotalForDateRange(DateTime start, DateTime end, {TransactionType? type}) {
    final filtered = getTransactionsByDateRange(start, end);
    return filtered
        .where((t) => type == null || t.type == type)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Calculate total by category
  double getTotalByCategory(String category, {TransactionType? type}) {
    return _transactions
        .where((t) => t.category == category && (type == null || t.type == type))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Get category breakdown
  Map<String, double> getCategoryBreakdown(DateTime start, DateTime end) {
    final filtered = getTransactionsByDateRange(start, end)
        .where((t) => t.type == TransactionType.expense);
    
    final Map<String, double> breakdown = {};
    for (var transaction in filtered) {
      breakdown[transaction.category] = 
          (breakdown[transaction.category] ?? 0) + transaction.amount;
    }
    return breakdown;
  }

  // Load user categories
  Future<void> loadUserCategories() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _selectedCategories = await _firestoreService.getUserCategories();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save user categories
  Future<void> saveUserCategories(List<String> categories) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _firestoreService.saveUserCategories(categories);
      _selectedCategories = categories;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}