import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tabs/models/expense_split.dart';
import 'package:tabs/models/user.dart';

part 'expense.freezed.dart';
part 'expense.g.dart';

@freezed
class Expense with _$Expense {
  const factory Expense({
    required String id,
    required String groupId,
    required String title,
    String? notes,
    required double amount,
    required String currency,
    required double convertedAmount,
    required double exchangeRate,
    @TimestampConverter() required DateTime date,
    required String paidBy,
    required Map<String, ExpenseSplit> splits,
    required String createdBy,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _Expense;

  factory Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);

  factory Expense.fromFirestore(DocumentSnapshot doc, String groupId) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse splits map
    final splitsData = data['splits'] as Map<String, dynamic>? ?? {};
    final splits = splitsData.map((key, value) => MapEntry(
      key,
      ExpenseSplit.fromJson(value as Map<String, dynamic>),
    ));

    return Expense(
      id: doc.id,
      groupId: groupId,
      title: data['title'] as String,
      notes: data['notes'] as String?,
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] as String,
      convertedAmount: (data['convertedAmount'] as num).toDouble(),
      exchangeRate: (data['exchangeRate'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      paidBy: data['paidBy'] as String,
      splits: splits,
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
