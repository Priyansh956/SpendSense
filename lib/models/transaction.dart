class ExpenseTransaction {
  final double amount;
  final String title;
  final String category;
  final DateTime date;
  final String note;
  final String userId;

  ExpenseTransaction({
    required this.amount,
    required this.title,
    required this.category,
    required this.date,
    required this.note,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'title': title,
      'category': category,
      'date': date,
      'note': note,
      'userId': userId,
      'createdAt': DateTime.now(),
    };
  }
}
