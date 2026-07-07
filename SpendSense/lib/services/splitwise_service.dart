import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Enum for friend request status
enum FriendRequestStatus { pending, accepted, rejected }

/// Model for a Friend
class Friend {
  final String uid;
  final String email;
  final String displayName;

  Friend({required this.uid, required this.email, required this.displayName});

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? map['email']?.split('@')[0] ?? 'User',
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
  };
}

/// Model for a Friend Request
class FriendRequest {
  final String id;
  final String fromUid;
  final String fromEmail;
  final String toUid;
  final String toEmail;
  final FriendRequestStatus status;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromEmail,
    required this.toUid,
    required this.toEmail,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromMap(Map<String, dynamic> map, String docId) {
    return FriendRequest(
      id: docId,
      fromUid: map['fromUid'] ?? '',
      fromEmail: map['fromEmail'] ?? '',
      toUid: map['toUid'] ?? '',
      toEmail: map['toEmail'] ?? '',
      status: _statusFromString(map['status'] ?? 'pending'),
      createdAt: _parseCreatedAt(map['createdAt']),
    );
  }

  static DateTime _parseCreatedAt(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static FriendRequestStatus _statusFromString(String s) {
    switch (s) {
      case 'accepted':
        return FriendRequestStatus.accepted;
      case 'rejected':
        return FriendRequestStatus.rejected;
      default:
        return FriendRequestStatus.pending;
    }
  }

  Map<String, dynamic> toMap() => {
    'fromUid': fromUid,
    'fromEmail': fromEmail,
    'toUid': toUid,
    'toEmail': toEmail,
    'status': status.name,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

/// Split expense participant
class SplitParticipant {
  final String uid;
  final String email;
  final String displayName;
  final double amount;
  final bool isPaid;

  SplitParticipant({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.amount,
    this.isPaid = false,
  });

  factory SplitParticipant.fromMap(Map<String, dynamic> map) {
    return SplitParticipant(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? map['email']?.split('@')[0] ?? 'User',
      amount: (map['amount'] ?? 0).toDouble(),
      isPaid: map['isPaid'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'amount': amount,
    'isPaid': isPaid,
  };

  SplitParticipant copyWith({bool? isPaid, double? amount}) {
    return SplitParticipant(
      uid: uid,
      email: email,
      displayName: displayName,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}

/// Split Expense model
class SplitExpense {
  final String id;
  final String title;
  final double totalAmount;
  final String category;
  final String paidByUid;
  final String paidByEmail;
  final String paidByName;
  final List<SplitParticipant> participants;
  final DateTime date;
  final String? note;
  final bool isSettled;

  SplitExpense({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.category,
    required this.paidByUid,
    required this.paidByEmail,
    required this.paidByName,
    required this.participants,
    required this.date,
    this.note,
    this.isSettled = false,
  });

  factory SplitExpense.fromMap(Map<String, dynamic> map, String docId) {
    return SplitExpense(
      id: docId,
      title: map['title'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      category: map['category'] ?? 'other',
      paidByUid: map['paidByUid'] ?? '',
      paidByEmail: map['paidByEmail'] ?? '',
      paidByName: map['paidByName'] ?? '',
      participants: (map['participants'] as List<dynamic>? ?? [])
          .map((p) => SplitParticipant.fromMap(p as Map<String, dynamic>))
          .toList(),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: map['note'],
      isSettled: map['isSettled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'totalAmount': totalAmount,
    'category': category,
    'paidByUid': paidByUid,
    'paidByEmail': paidByEmail,
    'paidByName': paidByName,
    'participants': participants.map((p) => p.toMap()).toList(),
    'involvedUids': {paidByUid, ...participants.map((p) => p.uid)}.toList(),
    'date': Timestamp.fromDate(date),
    'note': note,
    'isSettled': isSettled,
  };

  /// Amount the current user owes (or is owed)
  double amountForUser(String uid) {
    try {
      return participants.firstWhere((p) => p.uid == uid).amount;
    } catch (_) {
      return 0;
    }
  }

  bool isParticipant(String uid) => participants.any((p) => p.uid == uid);
}

/// SplitwiseService — all Firestore operations for the split feature
class SplitwiseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;
  String? get _email => _auth.currentUser?.email;

  // ─────────────────────────────────────────────
  // FRIEND SYSTEM
  // ─────────────────────────────────────────────

  /// Check if email is registered in the app
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return {'uid': doc.id, ...doc.data()};
  }

  /// Send a friend request
  Future<void> sendFriendRequest(String toEmail) async {
    final uid = _uid;
    final email = _email;
    if (uid == null || email == null) throw Exception('Not logged in');

    // Find target user
    final targetUser = await findUserByEmail(toEmail);
    if (targetUser == null) throw Exception('No user found with that email');

    final toUid = targetUser['uid'] as String;
    if (toUid == uid) throw Exception('You cannot add yourself');

    // Check if already friends
    final existingFriend = await _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .doc(toUid)
        .get();
    if (existingFriend.exists) throw Exception('Already friends');

    // Check for existing pending request
    final existingRequest = await _db
        .collection('friendRequests')
        .where('fromUid', isEqualTo: uid)
        .where('toUid', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .get();
    if (existingRequest.docs.isNotEmpty) {
      throw Exception('Friend request already sent');
    }

    // Create request
    await _db.collection('friendRequests').add({
      'fromUid': uid,
      'fromEmail': email,
      'toUid': toUid,
      'toEmail': toEmail.trim().toLowerCase(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of incoming friend requests
  Stream<List<FriendRequest>> incomingRequestsStream() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('friendRequests')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => FriendRequest.fromMap(d.data(), d.id)).toList(),
        );
  }

  /// Stream of sent friend requests
  Stream<List<FriendRequest>> sentRequestsStream() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('friendRequests')
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => FriendRequest.fromMap(d.data(), d.id)).toList(),
        );
  }

  /// Accept a friend request
  Future<void> acceptFriendRequest(FriendRequest request) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not logged in');

    final batch = _db.batch();

    // Update request status
    batch.update(_db.collection('friendRequests').doc(request.id), {
      'status': 'accepted',
    });

    // Add both ways to friends subcollection
    batch.set(
      _db
          .collection('users')
          .doc(uid)
          .collection('friends')
          .doc(request.fromUid),
      {
        'uid': request.fromUid,
        'email': request.fromEmail,
        'displayName': request.fromEmail.split('@')[0],
        'addedAt': FieldValue.serverTimestamp(),
      },
    );

    batch.set(
      _db
          .collection('users')
          .doc(request.fromUid)
          .collection('friends')
          .doc(uid),
      {
        'uid': uid,
        'email': _email,
        'displayName': _email?.split('@')[0] ?? 'User',
        'addedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  /// Reject a friend request
  Future<void> rejectFriendRequest(String requestId) async {
    await _db.collection('friendRequests').doc(requestId).update({
      'status': 'rejected',
    });
  }

  /// Stream of friends list
  Stream<List<Friend>> friendsStream() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .snapshots()
        .map((s) => s.docs.map((d) => Friend.fromMap(d.data())).toList());
  }

  /// Remove a friend
  Future<void> removeFriend(String friendUid) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not logged in');

    final batch = _db.batch();
    batch.delete(
      _db.collection('users').doc(uid).collection('friends').doc(friendUid),
    );
    batch.delete(
      _db.collection('users').doc(friendUid).collection('friends').doc(uid),
    );
    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // SPLIT EXPENSES
  // ─────────────────────────────────────────────

  /// Create a split expense (writes to all participants' feeds)
  Future<void> createSplitExpense(SplitExpense expense) async {
    final docRef = _db.collection('splitExpenses').doc(expense.id);
    await docRef.set(expense.toMap());
  }

  /// Stream of split expenses involving the current user
  Stream<List<SplitExpense>> splitExpensesStream() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    // Fetch all expenses where the user is involved (as payer or participant)
    return _db
        .collection('splitExpenses')
        .where('involvedUids', arrayContains: uid)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => SplitExpense.fromMap(d.data(), d.id)).toList(),
        );
  }

  /// Mark a participant as paid in a split expense
  Future<void> markParticipantPaid(
    String expenseId,
    String participantUid,
  ) async {
    final doc = await _db.collection('splitExpenses').doc(expenseId).get();
    if (!doc.exists) throw Exception('Expense not found');

    final expense = SplitExpense.fromMap(doc.data()!, doc.id);
    final updatedParticipants = expense.participants.map((p) {
      if (p.uid == participantUid) return p.copyWith(isPaid: true);
      return p;
    }).toList();

    final allPaid = updatedParticipants.every((p) => p.isPaid);

    await _db.collection('splitExpenses').doc(expenseId).update({
      'participants': updatedParticipants.map((p) => p.toMap()).toList(),
      'isSettled': allPaid,
    });
  }

  /// Settle (fully close) a split expense
  Future<void> settleExpense(String expenseId) async {
    await _db.collection('splitExpenses').doc(expenseId).update({
      'isSettled': true,
    });
  }

  /// Delete a split expense
  Future<void> deleteSplitExpense(String expenseId) async {
    await _db.collection('splitExpenses').doc(expenseId).delete();
  }

  /// Get all split expenses for balance calculations (both as payer & participant)
  Future<List<SplitExpense>> getAllSplitExpensesForUser() async {
    final uid = _uid;
    if (uid == null) return [];

    final involvedQuery = await _db
        .collection('splitExpenses')
        .where('involvedUids', arrayContains: uid)
        .where('isSettled', isEqualTo: false)
        .get();

    return involvedQuery.docs
        .map((d) => SplitExpense.fromMap(d.data(), d.id))
        .toList();
  }
}
