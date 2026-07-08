import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/friends_api_service.dart';
import '../services/splitwise_api_service.dart';
import '../services/splitwise_service.dart';

class SplitwiseProvider with ChangeNotifier {
  final FriendsApiService _friendsApi = FriendsApiService();
  final SplitwiseService _firebaseService = SplitwiseService();

  List<Friend> _friends = [];
  List<FriendRequest> _incomingRequests = [];
  List<FriendRequest> _sentRequests = [];
  List<SplitExpense> _splitExpenses = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;

  List<Friend> get friends => _friends;
  List<FriendRequest> get incomingRequests => _incomingRequests;
  List<FriendRequest> get sentRequests => _sentRequests;
  List<SplitExpense> get splitExpenses => _splitExpenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get pendingRequestCount => _incomingRequests.length;

  // ─────────────────────────────────────────────
  // STREAM LISTENERS
  // ─────────────────────────────────────────────

  Future<void> startListening() async {
    await refreshFriendsData();
    await refreshSplitExpenses();
  }

  Future<void> refreshSplitExpenses() async {
    try {
      _isLoading = true;
      notifyListeners();

      _splitExpenses = await SplitwiseApiService.getSplitExpenses();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshFriendsData() async {
    try {
      _isLoading = true;
      notifyListeners();

      _friends = await FriendsApiService.getFriends();
      _incomingRequests = await FriendsApiService.getIncomingRequests();
      _sentRequests = await FriendsApiService.getOutgoingRequests();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      refreshFriendsData();
      refreshSplitExpenses();
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // FRIEND ACTIONS
  // ─────────────────────────────────────────────

  Future<void> sendFriendRequest(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await FriendsApiService.sendFriendRequest(email);
      await startListening();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptRequest(FriendRequest request) async {
    try {
      await FriendsApiService.acceptRequest(request.id);
      await startListening();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      await FriendsApiService.rejectRequest(requestId);
      await startListening();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeFriend(String friendUid) async {
    try {
      await _firebaseService.removeFriend(friendUid);
    } catch (e) {
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // SPLIT EXPENSE ACTIONS
  // ─────────────────────────────────────────────

  Future<void> createSplitExpense(SplitExpense expense) async {
    _isLoading = true;
    notifyListeners();
    try {
      await SplitwiseApiService.createSplitExpense(expense);
      await refreshSplitExpenses();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markPaid(String expenseId, String participantUid) async {
    try {
      await _firebaseService.markParticipantPaid(expenseId, participantUid);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> settleExpense(String expenseId) async {
    try {
      await _firebaseService.settleExpense(expenseId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSplitExpense(String expenseId) async {
    try {
      await _firebaseService.deleteSplitExpense(expenseId);
    } catch (e) {
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // BALANCE CALCULATIONS
  // ─────────────────────────────────────────────

  /// Returns a map of friendUid → net balance
  /// Positive = they owe you, Negative = you owe them
  Map<String, double> getBalances(String currentUid) {
    final Map<String, double> balances = {};

    for (final expense in _splitExpenses) {
      if (expense.isSettled) continue;

      if (expense.paidByUid == currentUid) {
        // Current user paid — everyone else owes them
        for (final p in expense.participants) {
          if (p.uid == currentUid || p.isPaid) continue;
          balances[p.uid] = (balances[p.uid] ?? 0) + p.amount;
        }
      } else {
        // Someone else paid — check if current user is a participant
        final myShare = expense.participants
            .where((p) => p.uid == currentUid && !p.isPaid)
            .fold(0.0, (sum, p) => sum + p.amount);

        if (myShare > 0) {
          balances[expense.paidByUid] =
              (balances[expense.paidByUid] ?? 0) - myShare;
        }
      }
    }

    return balances;
  }

  /// Total amount you are owed
  double totalOwedToYou(String currentUid) {
    return getBalances(
      currentUid,
    ).values.where((v) => v > 0).fold(0.0, (sum, v) => sum + v);
  }

  /// Total amount you owe others
  double totalYouOwe(String currentUid) {
    return getBalances(
      currentUid,
    ).values.where((v) => v < 0).fold(0.0, (sum, v) => sum + v.abs());
  }

  /// Net balance (positive = you're owed more, negative = you owe more)
  double netBalance(String currentUid) {
    return totalOwedToYou(currentUid) - totalYouOwe(currentUid);
  }

  /// Get friend name by UID
  String getFriendName(String uid) {
    try {
      return _friends.firstWhere((f) => f.uid == uid).displayName;
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Get friend email by UID
  String getFriendEmail(String uid) {
    try {
      return _friends.firstWhere((f) => f.uid == uid).email;
    } catch (_) {
      return '';
    }
  }

  /// Split expenses filtered by friend
  List<SplitExpense> expensesWithFriend(String friendUid, String currentUid) {
    return _splitExpenses.where((e) {
      final involvesFriend =
          e.paidByUid == friendUid ||
          e.participants.any((p) => p.uid == friendUid);
      final involvesMe =
          e.paidByUid == currentUid ||
          e.participants.any((p) => p.uid == currentUid);
      return involvesFriend && involvesMe && !e.isSettled;
    }).toList();
  }
}
