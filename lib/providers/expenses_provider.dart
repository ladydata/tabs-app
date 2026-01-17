import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/providers/auth_provider.dart';
import 'package:tabs/providers/groups_provider.dart';
import 'package:tabs/services/exchange_rate_service.dart';

// Exchange rate service provider
final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  return ExchangeRateService();
});

// Group expenses stream provider
final groupExpensesProvider =
    StreamProvider.family<List<Expense>, String>((ref, groupId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getGroupExpenses(groupId);
});

// Single expense provider
final expenseProvider =
    FutureProvider.family<Expense?, ({String groupId, String expenseId})>((ref, params) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getExpense(params.groupId, params.expenseId);
});

// Expenses actions notifier
class ExpensesNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ExpensesNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<String?> createExpense({
    required String groupId,
    required String title,
    String? notes,
    required double amount,
    required String currency,
    required DateTime date,
    required Map<String, double> payers, // userId -> amount in original currency
    required Map<String, ExpenseSplit> splits,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      final userProfile = await _ref.read(currentUserProfileProvider.future);
      final group = await _ref.read(groupProvider(groupId).future);

      if (user == null || userProfile == null || group == null) {
        throw Exception('User not authenticated or group not found');
      }

      // Get exchange rate
      final exchangeRateService = _ref.read(exchangeRateServiceProvider);
      final exchangeRate = await exchangeRateService.getExchangeRate(
        fromCurrency: currency,
        toCurrency: group.currency,
        date: date,
      );

      final convertedAmount = amount * exchangeRate;

      // Adjust splits to group currency
      final convertedSplits = <String, ExpenseSplit>{};
      for (final entry in splits.entries) {
        convertedSplits[entry.key] = ExpenseSplit(
          userId: entry.value.userId,
          amount: entry.value.amount * exchangeRate,
          type: entry.value.type,
          percentage: entry.value.percentage,
        );
      }

      // Determine primary payer (first one or the one with highest amount)
      final paidBy = payers.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

      final firestoreService = _ref.read(firestoreServiceProvider);
      final expenseId = await firestoreService.createExpense(
        groupId: groupId,
        title: title,
        notes: notes,
        amount: amount,
        currency: currency,
        convertedAmount: convertedAmount,
        exchangeRate: exchangeRate,
        date: date,
        paidBy: paidBy,
        payers: payers,
        splits: convertedSplits,
        createdBy: user.uid,
      );

      // Log activity
      await firestoreService.logActivity(
        groupId: groupId,
        type: ActivityType.expenseAdded,
        actorUserId: user.uid,
        actorName: userProfile.displayName,
        details: {
          'expenseId': expenseId,
          'title': title,
          'amount': amount,
          'currency': currency,
          'convertedAmount': convertedAmount,
          'groupCurrency': group.currency,
        },
      );

      state = const AsyncValue.data(null);
      return expenseId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> updateExpense({
    required String groupId,
    required String expenseId,
    String? title,
    String? notes,
    double? amount,
    String? currency,
    DateTime? date,
    Map<String, double>? payers, // userId -> amount in original currency
    Map<String, ExpenseSplit>? splits,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      final userProfile = await _ref.read(currentUserProfileProvider.future);
      final group = await _ref.read(groupProvider(groupId).future);
      final existingExpense = await _ref.read(
        expenseProvider((groupId: groupId, expenseId: expenseId)).future,
      );

      if (user == null || userProfile == null || group == null || existingExpense == null) {
        throw Exception('Data not found');
      }

      // Recalculate exchange rate if date or currency changed
      double? convertedAmount;
      double? exchangeRate;
      Map<String, ExpenseSplit>? convertedSplits;

      final finalCurrency = currency ?? existingExpense.currency;
      final finalDate = date ?? existingExpense.date;
      final finalAmount = amount ?? existingExpense.amount;

      if (currency != null || date != null || amount != null) {
        final exchangeRateService = _ref.read(exchangeRateServiceProvider);
        exchangeRate = await exchangeRateService.getExchangeRate(
          fromCurrency: finalCurrency,
          toCurrency: group.currency,
          date: finalDate,
        );
        convertedAmount = finalAmount * exchangeRate;

        // Recalculate splits if amount changed
        if (splits != null || amount != null) {
          final finalSplits = splits ?? existingExpense.splits;
          convertedSplits = <String, ExpenseSplit>{};
          for (final entry in finalSplits.entries) {
            convertedSplits[entry.key] = ExpenseSplit(
              userId: entry.value.userId,
              amount: entry.value.amount * exchangeRate,
              type: entry.value.type,
              percentage: entry.value.percentage,
            );
          }
        }
      }

      // Determine primary payer if payers changed
      String? paidBy;
      if (payers != null) {
        paidBy = payers.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      }

      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.updateExpense(
        groupId: groupId,
        expenseId: expenseId,
        title: title,
        notes: notes,
        amount: amount,
        currency: currency,
        convertedAmount: convertedAmount,
        exchangeRate: exchangeRate,
        date: date,
        paidBy: paidBy,
        payers: payers,
        splits: convertedSplits,
      );

      // Log activity
      await firestoreService.logActivity(
        groupId: groupId,
        type: ActivityType.expenseUpdated,
        actorUserId: user.uid,
        actorName: userProfile.displayName,
        details: {
          'expenseId': expenseId,
          'title': title ?? existingExpense.title,
        },
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteExpense(String groupId, String expenseId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      final userProfile = await _ref.read(currentUserProfileProvider.future);
      final expense = await _ref.read(
        expenseProvider((groupId: groupId, expenseId: expenseId)).future,
      );

      if (user == null || userProfile == null) {
        throw Exception('User not authenticated');
      }

      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.deleteExpense(groupId, expenseId);

      // Log activity
      await firestoreService.logActivity(
        groupId: groupId,
        type: ActivityType.expenseDeleted,
        actorUserId: user.uid,
        actorName: userProfile.displayName,
        details: {
          'expenseId': expenseId,
          'title': expense?.title ?? 'Unknown',
        },
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final expensesNotifierProvider =
    StateNotifierProvider<ExpensesNotifier, AsyncValue<void>>((ref) {
  return ExpensesNotifier(ref);
});
