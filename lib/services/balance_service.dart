import 'package:tabs/models/models.dart';

class BalanceService {
  /// Calculate balances for all members in a group
  /// Returns a map of userId -> balance (positive = owed money, negative = owes money)
  Map<String, double> calculateBalances({
    required List<Expense> expenses,
    required List<Settlement> settlements,
  }) {
    final balances = <String, double>{};

    // Process expenses
    for (final expense in expenses) {
      // The payer is owed the converted amount
      balances[expense.paidBy] =
          (balances[expense.paidBy] ?? 0) + expense.convertedAmount;

      // Each person in the split owes their share
      for (final split in expense.splits.values) {
        balances[split.userId] =
            (balances[split.userId] ?? 0) - split.amount;
      }
    }

    // Process settlements
    for (final settlement in settlements) {
      // The payer (fromUser) has settled some of their debt
      balances[settlement.fromUserId] =
          (balances[settlement.fromUserId] ?? 0) + settlement.amount;
      // The receiver (toUser) has received payment
      balances[settlement.toUserId] =
          (balances[settlement.toUserId] ?? 0) - settlement.amount;
    }

    return balances;
  }

  /// Calculate pairwise debts between members
  /// Returns a list of debts showing who owes whom and how much
  List<Debt> calculateDebts({
    required Map<String, double> balances,
    required Map<String, GroupMember> members,
  }) {
    final debts = <Debt>[];

    // Separate members into creditors (positive balance) and debtors (negative balance)
    final creditors = <String, double>{};
    final debtors = <String, double>{};

    for (final entry in balances.entries) {
      if (entry.value > 0.01) {
        creditors[entry.key] = entry.value;
      } else if (entry.value < -0.01) {
        debtors[entry.key] = -entry.value; // Store as positive amount
      }
    }

    // Simple algorithm: match debtors to creditors
    // This is a greedy approach; for optimal (minimum transactions),
    // a more complex algorithm would be needed
    final creditorList = creditors.entries.toList();
    final debtorList = debtors.entries.toList();

    int ci = 0;
    int di = 0;

    while (ci < creditorList.length && di < debtorList.length) {
      final creditor = creditorList[ci];
      final debtor = debtorList[di];

      final amount = creditor.value < debtor.value
          ? creditor.value
          : debtor.value;

      if (amount > 0.01) {
        debts.add(Debt(
          fromUserId: debtor.key,
          fromUserName: members[debtor.key]?.displayName ?? 'Unknown',
          toUserId: creditor.key,
          toUserName: members[creditor.key]?.displayName ?? 'Unknown',
          amount: amount,
        ));
      }

      creditorList[ci] = MapEntry(creditor.key, creditor.value - amount);
      debtorList[di] = MapEntry(debtor.key, debtor.value - amount);

      if (creditorList[ci].value < 0.01) ci++;
      if (debtorList[di].value < 0.01) di++;
    }

    return debts;
  }

  /// Get the total balance for a specific user in a group
  /// Positive means they are owed money, negative means they owe money
  double getUserBalance(String userId, Map<String, double> balances) {
    return balances[userId] ?? 0;
  }

  /// Get simplified debts involving a specific user
  List<Debt> getUserDebts(String userId, List<Debt> allDebts) {
    return allDebts.where((debt) =>
        debt.fromUserId == userId || debt.toUserId == userId).toList();
  }
}

/// Represents a debt between two users
class Debt {
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final double amount;

  const Debt({
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
  });

  /// Returns true if this debt involves the given user
  bool involvesUser(String userId) {
    return fromUserId == userId || toUserId == userId;
  }

  /// Returns the amount from the perspective of the given user
  /// Positive = they are owed, Negative = they owe
  double getAmountForUser(String userId) {
    if (toUserId == userId) return amount;
    if (fromUserId == userId) return -amount;
    return 0;
  }
}
