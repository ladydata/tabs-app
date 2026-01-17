import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tabs/config/theme.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/services/exchange_rate_service.dart';

class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final ExpenseGroup group;
  final VoidCallback? onTap;

  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.group,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');
    final showOriginalCurrency = expense.currency != group.currency;
    final payerCount = expense.payers.length;
    final paidByText = payerCount > 1
        ? 'Paid by $payerCount people'
        : 'Paid by ${group.members[expense.paidBy]?.displayName ?? 'Unknown'}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getExpenseIcon(),
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            paidByText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(expense.date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ExchangeRateService.formatAmount(
                      expense.convertedAmount,
                      group.currency,
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (showOriginalCurrency)
                    Text(
                      ExchangeRateService.formatAmount(
                        expense.amount,
                        expense.currency,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getExpenseIcon() {
    final title = expense.title.toLowerCase();
    if (title.contains('food') || title.contains('dinner') || title.contains('lunch') ||
        title.contains('breakfast') || title.contains('restaurant')) {
      return Icons.restaurant;
    }
    if (title.contains('grocery') || title.contains('groceries') || title.contains('supermarket')) {
      return Icons.shopping_cart;
    }
    if (title.contains('gas') || title.contains('fuel') || title.contains('petrol')) {
      return Icons.local_gas_station;
    }
    if (title.contains('uber') || title.contains('lyft') || title.contains('taxi') ||
        title.contains('transport')) {
      return Icons.directions_car;
    }
    if (title.contains('hotel') || title.contains('airbnb') || title.contains('lodging')) {
      return Icons.hotel;
    }
    if (title.contains('flight') || title.contains('plane') || title.contains('airline')) {
      return Icons.flight;
    }
    if (title.contains('drinks') || title.contains('bar') || title.contains('beer') ||
        title.contains('wine')) {
      return Icons.local_bar;
    }
    if (title.contains('rent') || title.contains('utilities') || title.contains('electric') ||
        title.contains('water')) {
      return Icons.home;
    }
    return Icons.receipt;
  }
}
