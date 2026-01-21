import 'package:flutter_test/flutter_test.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/providers/groups_provider.dart';

void main() {
  group('Settled Groups Logic', () {
    // Helper to create a test group with specific updatedAt
    ExpenseGroup createTestGroup({
      required String id,
      required String name,
      required DateTime updatedAt,
    }) {
      final now = DateTime.now();
      return ExpenseGroup(
        id: id,
        name: name,
        currency: 'USD',
        members: {
          'user1': GroupMember(
            userId: 'user1',
            displayName: 'User 1',
            email: 'user1@test.com',
            joinedAt: now,
          ),
          'user2': GroupMember(
            userId: 'user2',
            displayName: 'User 2',
            email: 'user2@test.com',
            joinedAt: now,
          ),
        },
        memberIds: ['user1', 'user2'],
        createdBy: 'user1',
        createdAt: now,
        updatedAt: updatedAt,
      );
    }

    // Helper to check if a group is "old settled" (matches the provider logic)
    bool isGroupSettledAndOld(ExpenseGroup group, Map<String, double> balances) {
      final isSettled = balances.values.every((b) => b.abs() < 0.01);
      if (!isSettled) return false;
      final daysSinceUpdate = DateTime.now().difference(group.updatedAt).inDays;
      return daysSinceUpdate >= kSettledDaysThreshold;
    }

    test('Group updated today with zero balances is NOT old settled', () {
      final group = createTestGroup(
        id: 'group1',
        name: 'Recent Settled',
        updatedAt: DateTime.now(),
      );
      final balances = {'user1': 0.0, 'user2': 0.0};

      // Settled but not 30+ days old
      final isSettled = balances.values.every((b) => b.abs() < 0.01);
      final daysSinceUpdate = DateTime.now().difference(group.updatedAt).inDays;
      final isOldSettled = isGroupSettledAndOld(group, balances);

      expect(isSettled, true);
      expect(daysSinceUpdate, 0);
      expect(isOldSettled, false);
    });

    test('Group updated 29 days ago with zero balances is NOT old settled', () {
      final group = createTestGroup(
        id: 'group2',
        name: '29 Days Settled',
        updatedAt: DateTime.now().subtract(const Duration(days: 29)),
      );
      final balances = {'user1': 0.0, 'user2': 0.0};

      final isSettled = balances.values.every((b) => b.abs() < 0.01);
      final daysSinceUpdate = DateTime.now().difference(group.updatedAt).inDays;
      final isOldSettled = isGroupSettledAndOld(group, balances);

      expect(isSettled, true);
      expect(daysSinceUpdate, 29);
      expect(isOldSettled, false);
    });

    test('Group updated 30 days ago with zero balances IS old settled', () {
      final group = createTestGroup(
        id: 'group3',
        name: '30 Days Settled',
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      final balances = {'user1': 0.0, 'user2': 0.0};

      final isSettled = balances.values.every((b) => b.abs() < 0.01);
      final daysSinceUpdate = DateTime.now().difference(group.updatedAt).inDays;
      final isOldSettled = isGroupSettledAndOld(group, balances);

      expect(isSettled, true);
      expect(daysSinceUpdate, 30);
      expect(isOldSettled, true);
    });

    test('Group updated 45 days ago with zero balances IS old settled', () {
      final group = createTestGroup(
        id: 'group4',
        name: '45 Days Settled',
        updatedAt: DateTime.now().subtract(const Duration(days: 45)),
      );
      final balances = {'user1': 0.0, 'user2': 0.0};

      final isSettled = balances.values.every((b) => b.abs() < 0.01);
      final daysSinceUpdate = DateTime.now().difference(group.updatedAt).inDays;
      final isOldSettled = isGroupSettledAndOld(group, balances);

      expect(isSettled, true);
      expect(daysSinceUpdate, 45);
      expect(isOldSettled, true);
    });

    test('Group updated 60 days ago with NON-zero balances is NOT old settled', () {
      final group = createTestGroup(
        id: 'group5',
        name: 'Old But Active',
        updatedAt: DateTime.now().subtract(const Duration(days: 60)),
      );
      final balances = {'user1': 25.50, 'user2': -25.50}; // Not settled

      final isSettled = balances.values.every((b) => b.abs() < 0.01);
      final isOldSettled = isGroupSettledAndOld(group, balances);

      expect(isSettled, false);
      expect(isOldSettled, false);
    });

    test('Group with near-zero balances (< 0.01) counts as settled', () {
      final group = createTestGroup(
        id: 'group6',
        name: 'Near Zero',
        updatedAt: DateTime.now().subtract(const Duration(days: 35)),
      );
      final balances = {'user1': 0.005, 'user2': -0.005}; // Near zero

      final isSettled = balances.values.every((b) => b.abs() < 0.01);
      final isOldSettled = isGroupSettledAndOld(group, balances);

      expect(isSettled, true);
      expect(isOldSettled, true);
    });

    test('kSettledDaysThreshold constant equals 30', () {
      expect(kSettledDaysThreshold, 30);
    });
  });
}
