enum TransactionType { expense, income }

class Transaction {
  /// Null until the backend assigns one on create (Mongo generates _id
  /// server-side — there's no more client-side UUID generation).
  final String? id;
  final String title;
  final double amount;
  final String category;
  final TransactionType type;
  final DateTime date;
  final String? note;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.note,
  });

  /// Body sent to the API. Note: no `id`, no `userId` — the backend
  /// generates the id and scopes ownership from the JWT automatically.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'expenditureCategory':
          type == TransactionType.expense ? 'expense' : 'income',
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] as String?,
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      type: json['expenditureCategory'] == 'expense'
          ? TransactionType.expense
          : TransactionType.income,
      date: DateTime.parse(json['date'] as String),
      note: json['note'],
    );
  }

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    TransactionType? type,
    DateTime? date,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}