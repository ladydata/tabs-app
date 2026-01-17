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
    String? category,
    String? notes,
    required double amount,
    required String currency,
    required double convertedAmount,
    required double exchangeRate,
    @TimestampConverter() required DateTime date,
    required String paidBy,
    required Map<String, double> payers, // userId -> amount in original currency
    required Map<String, ExpenseSplit> splits,
    required String createdBy,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _Expense;

  factory Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);

  factory Expense.fromFirestore(DocumentSnapshot doc, String groupId) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse splits map
    final splitsData = (data['splits'] as Map?)?.cast<String, dynamic>() ?? {};
    final splits = splitsData.map((key, value) => MapEntry(
      key,
      ExpenseSplit.fromJson(Map<String, dynamic>.from(value as Map)),
    ));

    // Parse payers map, with fallback to legacy single paidBy field
    final amount = (data['amount'] as num).toDouble();
    final paidBy = data['paidBy'] as String;
    Map<String, double> payers;
    if (data['payers'] != null) {
      final payersData = (data['payers'] as Map).cast<String, dynamic>();
      payers = payersData.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } else {
      // Backward compatibility: construct payers from legacy paidBy field
      payers = {paidBy: amount};
    }

    return Expense(
      id: doc.id,
      groupId: groupId,
      title: data['title'] as String,
      category: data['category'] as String?,
      notes: data['notes'] as String?,
      amount: amount,
      currency: data['currency'] as String,
      convertedAmount: (data['convertedAmount'] as num).toDouble(),
      exchangeRate: (data['exchangeRate'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      paidBy: paidBy,
      payers: payers,
      splits: splits,
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
