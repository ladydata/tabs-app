import 'package:flutter/material.dart';
import 'package:tabs/config/theme.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/services/balance_service.dart';
import 'package:tabs/services/exchange_rate_service.dart';

class BalanceSummary extends StatelessWidget {
  final List<Debt> debts;
  final String currentUserId;
  final ExpenseGroup group;
  final VoidCallback? onSettleUp;

  const BalanceSummary({
    super.key,
    required this.debts,
    required this.currentUserId,
    required this.group,
    this.onSettleUp,
  });

  @override
  Widget build(BuildContext context) {
    final userDebts = debts.where((d) => d.involvesUser(currentUserId)).toList();

    // Calculate total owed to user and total user owes
    double youAreOwed = 0;
    double youOwe = 0;

    for (final debt in userDebts) {
      if (debt.toUserId == currentUserId) {
        youAreOwed += debt.amount;
      } else if (debt.fromUserId == currentUserId) {
        youOwe += debt.amount;
      }
    }

    final netBalance = youAreOwed - youOwe;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Your Balance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              netBalance >= 0
                  ? '+${ExchangeRateService.formatAmount(netBalance, group.currency)}'
                  : ExchangeRateService.formatAmount(netBalance, group.currency),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: netBalance >= 0 ? AppColors.positive : AppColors.negative,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              netBalance >= 0
                  ? (netBalance > 0 ? 'You are owed' : 'All settled up')
                  : 'You owe',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (userDebts.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              ...userDebts.map((debt) => _DebtRow(
                debt: debt,
                currentUserId: currentUserId,
                currency: group.currency,
              )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSettleUp,
                  child: const Text('Settle Up'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DebtRow extends StatelessWidget {
  final Debt debt;
  final String currentUserId;
  final String currency;

  const _DebtRow({
    required this.debt,
    required this.currentUserId,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isOwed = debt.toUserId == currentUserId;
    final otherPersonName = isOwed ? debt.fromUserName : debt.toUserName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isOwed
                ? AppColors.positive.withOpacity(0.2)
                : AppColors.negative.withOpacity(0.2),
            child: Text(
              otherPersonName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: isOwed ? AppColors.positive : AppColors.negative,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isOwed ? '$otherPersonName owes you' : 'You owe $otherPersonName',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            ExchangeRateService.formatAmount(debt.amount, currency),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isOwed ? AppColors.positive : AppColors.negative,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
