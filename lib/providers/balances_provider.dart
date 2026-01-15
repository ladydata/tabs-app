import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/providers/auth_provider.dart';
import 'package:tabs/providers/groups_provider.dart';
import 'package:tabs/providers/expenses_provider.dart';
import 'package:tabs/services/balance_service.dart';

// Balance service provider
final balanceServiceProvider = Provider<BalanceService>((ref) {
  return BalanceService();
});

// Group settlements stream provider
final groupSettlementsProvider =
    StreamProvider.family<List<Settlement>, String>((ref, groupId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getGroupSettlements(groupId);
});

// Group balances provider
final groupBalancesProvider =
    Provider.family<AsyncValue<Map<String, double>>, String>((ref, groupId) {
  final expensesAsync = ref.watch(groupExpensesProvider(groupId));
  final settlementsAsync = ref.watch(groupSettlementsProvider(groupId));
  final balanceService = ref.watch(balanceServiceProvider);

  return expensesAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (expenses) {
      return settlementsAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
        data: (settlements) {
          final balances = balanceService.calculateBalances(
            expenses: expenses,
            settlements: settlements,
          );
          return AsyncValue.data(balances);
        },
      );
    },
  );
});

// Group debts provider
final groupDebtsProvider =
    Provider.family<AsyncValue<List<Debt>>, String>((ref, groupId) {
  final balancesAsync = ref.watch(groupBalancesProvider(groupId));
  final groupAsync = ref.watch(groupProvider(groupId));
  final balanceService = ref.watch(balanceServiceProvider);

  return balancesAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (balances) {
      return groupAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
        data: (group) {
          if (group == null) return const AsyncValue.data([]);
          final debts = balanceService.calculateDebts(
            balances: balances,
            members: group.members,
          );
          return AsyncValue.data(debts);
        },
      );
    },
  );
});

// Current user's balance in a group
final userBalanceProvider =
    Provider.family<AsyncValue<double>, String>((ref, groupId) {
  final user = ref.watch(currentUserProvider);
  final balancesAsync = ref.watch(groupBalancesProvider(groupId));

  if (user == null) return const AsyncValue.data(0);

  return balancesAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (balances) {
      return AsyncValue.data(balances[user.uid] ?? 0);
    },
  );
});

// Current user's debts in a group
final userDebtsProvider =
    Provider.family<AsyncValue<List<Debt>>, String>((ref, groupId) {
  final user = ref.watch(currentUserProvider);
  final debtsAsync = ref.watch(groupDebtsProvider(groupId));

  if (user == null) return const AsyncValue.data([]);

  return debtsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (debts) {
      final userDebts = debts.where((debt) => debt.involvesUser(user.uid)).toList();
      return AsyncValue.data(userDebts);
    },
  );
});

// Settlements actions notifier
class SettlementsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SettlementsNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<String?> createSettlement({
    required String groupId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      final userProfile = await _ref.read(currentUserProfileProvider.future);
      final group = await _ref.read(groupProvider(groupId).future);

      if (user == null || userProfile == null || group == null) {
        throw Exception('User not authenticated or group not found');
      }

      final firestoreService = _ref.read(firestoreServiceProvider);
      final settlementId = await firestoreService.createSettlement(
        groupId: groupId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        amount: amount,
        date: date,
        notes: notes,
        createdBy: user.uid,
      );

      // Log activity
      final fromName = group.members[fromUserId]?.displayName ?? 'Unknown';
      final toName = group.members[toUserId]?.displayName ?? 'Unknown';

      await firestoreService.logActivity(
        groupId: groupId,
        type: ActivityType.settlementAdded,
        actorUserId: user.uid,
        actorName: userProfile.displayName,
        details: {
          'settlementId': settlementId,
          'fromUserId': fromUserId,
          'fromUserName': fromName,
          'toUserId': toUserId,
          'toUserName': toName,
          'amount': amount,
          'currency': group.currency,
        },
      );

      state = const AsyncValue.data(null);
      return settlementId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> deleteSettlement(String groupId, String settlementId) async {
    state = const AsyncValue.loading();
    try {
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.deleteSettlement(groupId, settlementId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final settlementsNotifierProvider =
    StateNotifierProvider<SettlementsNotifier, AsyncValue<void>>((ref) {
  return SettlementsNotifier(ref);
});
