import '../services/api_service.dart';

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
    'createdAt': createdAt.toIso8601String(),
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

  Map<String, dynamic> toJson() => toMap();
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

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

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
      date: _parseDate(map['date']),
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
    // 'date': Timestamp.fromDate(date),
    'note': note,
    'isSettled': isSettled,
  };

  Map<String, dynamic> toJson() => {
    'title': title,
    'totalAmount': totalAmount,
    'category': category,
    'paidByUid': paidByUid,
    'paidByEmail': paidByEmail,
    'paidByName': paidByName,
    'participants': participants.map((p) => p.toMap()).toList(),
    'date': date.toIso8601String(),
    if (note != null) 'note': note,
    'isSettled': isSettled,
    'involvedUids': [paidByUid, ...participants.map((p) => p.uid).toSet()],
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
