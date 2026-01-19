import 'package:flutter_test/flutter_test.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/services/balance_service.dart';

void main() {
  group('BalanceService - isGroupSettled', () {
    final service = BalanceService();
    final now = DateTime.now();

    test('returns true for empty expenses and settlements', () {
      expect(service.isGroupSettled([], []), isTrue);
    });

    test('returns false when there is an outstanding balance', () {
      // User A paid 100, split equally with User B.
      // A +50, B -50. Not settled.
      final expense = Expense(
        id: 'e1',
        groupId: 'g1',
        title: 'Dinner',
        amount: 100,
        currency: 'USD',
        convertedAmount: 100,
        exchangeRate: 1.0,
        date: now,
        paidBy: 'uA',
        payers: {'uA': 100.0},
        splits: {
          'uA': ExpenseSplit(userId: 'uA', amount: 50, type: SplitType.equal),
          'uB': ExpenseSplit(userId: 'uB', amount: 50, type: SplitType.equal),
        },
        createdBy: 'uA',
        createdAt: now,
        updatedAt: now,
      );

      expect(service.isGroupSettled([expense], []), isFalse);
    });

    test('returns true when settlements balance out expenses', () {
      // User A paid 100, split equally with User B. (A: +50, B: -50)
      final expense = Expense(
        id: 'e1',
        groupId: 'g1',
        title: 'Dinner',
        amount: 100,
        currency: 'USD',
        convertedAmount: 100,
        exchangeRate: 1.0,
        date: now,
        paidBy: 'uA',
        payers: {'uA': 100.0},
        splits: {
          'uA': ExpenseSplit(userId: 'uA', amount: 50, type: SplitType.equal),
          'uB': ExpenseSplit(userId: 'uB', amount: 50, type: SplitType.equal),
        },
        createdBy: 'uA',
        createdAt: now,
        updatedAt: now,
      );

      // User B pays User A 50. (A: -50, B: +50) -> Net 0.
      final settlement = Settlement(
        id: 's1',
        groupId: 'g1',
        fromUserId: 'uB',
        toUserId: 'uA',
        amount: 50,
        date: now,
        createdBy: 'uB',
        createdAt: now,
      );

      expect(service.isGroupSettled([expense], [settlement]), isTrue);
    });
  });
}
