import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense_split.freezed.dart';
part 'expense_split.g.dart';

enum SplitType { equal, percentage, exact }

@freezed
class ExpenseSplit with _$ExpenseSplit {
  const factory ExpenseSplit({
    required String userId,
    required double amount,
    required SplitType type,
    double? percentage,
  }) = _ExpenseSplit;

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) =>
      _$ExpenseSplitFromJson(json);
}
