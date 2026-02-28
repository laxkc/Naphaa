class Expense {
  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.note,
    required this.createdAt,
    this.expenseDateAd,
  });

  final String id;
  final String category;
  final double amount;
  final String? note;
  final DateTime createdAt;
  final String? expenseDateAd;

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      expenseDateAd: map['expense_date_ad']?.toString(),
    );
  }
}
