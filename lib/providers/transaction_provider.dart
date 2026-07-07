import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  List<String> _selectedCategories = [];
  String? _userEmail;
  bool _isLoading = false;

  List<Transaction> get transactions => _transactions;
  List<String> get selectedCategories => _selectedCategories;
  String? get userEmail => _userEmail;
  bool get isLoading => _isLoading;

  /// Replaces the old Firestore realtime listener. There's no push/stream
  /// with a plain REST API, so this is called explicitly: on screen load,
  /// and again after any add/edit/delete that isn't already handled
  /// optimistically below.
  Future<void> fetchTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.getTransactions();
      _transactions = data.map((json) => Transaction.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    _isLoading = true;
    notifyListeners();

    try {
      final created = await ApiService.addTransaction(
        title: transaction.title,
        expenditureCategory:
            transaction.type == TransactionType.expense ? 'expense' : 'income',
        amount: transaction.amount,
        category: transaction.category,
        date: transaction.date,
        note: transaction.note,
      );
      _transactions.insert(0, Transaction.fromJson(created));
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    if (transaction.id == null) {
      throw Exception('Cannot update a transaction with no id');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final updated = await ApiService.editTransaction(
        id: transaction.id!,
        title: transaction.title,
        expenditureCategory:
            transaction.type == TransactionType.expense ? 'expense' : 'income',
        amount: transaction.amount,
        category: transaction.category,
        date: transaction.date,
        note: transaction.note,
      );
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = Transaction.fromJson(updated);
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Optimistic delete — removes locally immediately (for swipe
  /// responsiveness, matching the old behavior), rolls back on failure.
  Future<void> deleteTransaction(String? id) async {
    if (id == null) return;

    final index = _transactions.indexWhere((t) => t.id == id);
    final removed = index != -1 ? _transactions[index] : null;

    if (index != -1) {
      _transactions.removeAt(index);
      notifyListeners();
    }

    try {
      await ApiService.deleteTransaction(id);
    } catch (e) {
      if (removed != null && index != -1) {
        _transactions.insert(index, removed);
        notifyListeners();
      }
      rethrow;
    }
  }

  /// "Undo" for a delete. The backend has no way to restore a specific
  /// deleted document, so this recreates it as a brand new transaction
  /// (it will get a new id — acceptable for an undo-within-a-few-seconds
  /// UX, but note it, since it's a behavior change from Firestore).
  Future<void> restoreTransaction(Transaction transaction) async {
    await addTransaction(transaction);
  }

  // ---- Local calculation helpers — unchanged, operate on cached data ----

  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _transactions.where((t) {
      return t.date.isAfter(start.subtract(const Duration(days: 1))) &&
          t.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  List<Transaction> getTransactionsByCategory(String category) {
    return _transactions.where((t) => t.category == category).toList();
  }

  double getTotalForDateRange(DateTime start, DateTime end,
      {TransactionType? type}) {
    final filtered = getTransactionsByDateRange(start, end);
    return filtered
        .where((t) => type == null || t.type == type)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getTotalByCategory(String category, {TransactionType? type}) {
    return _transactions
        .where((t) =>
            t.category == category && (type == null || t.type == type))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

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

  /// Fetches categories AND email in one call (both come from /auth/me) —
  /// used by category_selection_page.dart, and now also usable by any
  /// screen that needs to display the user's email.
  Future<void> loadUserCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final me = await ApiService.getMe();
      _selectedCategories = List<String>.from(me['categories'] ?? []);
      _userEmail = me['email'] as String?;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveUserCategories(List<String> categories) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.updateCategories(categories);
      _selectedCategories = categories;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}