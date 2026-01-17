import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tabs/config/theme.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/providers/groups_provider.dart';
import 'package:tabs/providers/expenses_provider.dart';
import 'package:tabs/services/exchange_rate_service.dart';
import 'package:tabs/widgets/common/loading_widget.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final String groupId;
  final String expenseId;

  const ExpenseDetailScreen({
    super.key,
    required this.groupId,
    required this.expenseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupProvider(groupId));
    final expenseAsync = ref.watch(
      expenseProvider((groupId: groupId, expenseId: expenseId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: groupAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (group) {
          if (group == null) {
            return const Center(child: Text('Group not found'));
          }

          return expenseAsync.when(
            loading: () => const LoadingWidget(),
            error: (error, _) => Center(child: Text('Error: $error')),
            data: (expense) {
              if (expense == null) {
                return const Center(child: Text('Expense not found'));
              }
              return _buildContent(context, group, expense);
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ExpenseGroup group, Expense expense) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final showOriginalCurrency = expense.currency != group.currency;
    final hasMultiplePayers = expense.payers.length > 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    ExchangeRateService.formatAmount(
                      expense.convertedAmount,
                      group.currency,
                    ),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (showOriginalCurrency) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Original: ${ExchangeRateService.formatAmount(expense.amount, expense.currency)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      'Rate: 1 ${expense.currency} = ${expense.exchangeRate.toStringAsFixed(4)} ${group.currency}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Details
          _DetailRow(
            icon: Icons.description_outlined,
            label: 'Description',
            value: expense.title,
          ),

          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: dateFormat.format(expense.date),
          ),

          if (!hasMultiplePayers)
            _DetailRow(
              icon: Icons.person_outlined,
              label: 'Paid by',
              value: group.members[expense.paidBy]?.displayName ?? 'Unknown',
            ),

          if (hasMultiplePayers) ...[
            const SizedBox(height: 8),
            Text(
              'Paid by',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            ...expense.payers.entries.map((entry) {
              final member = group.members[entry.key];
              final payerAmount = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        member?.displayName.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(color: AppColors.primaryDark, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(member?.displayName ?? 'Unknown'),
                    ),
                    Text(
                      ExchangeRateService.formatAmount(payerAmount, expense.currency),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],

          if (expense.notes != null && expense.notes!.isNotEmpty)
            _DetailRow(
              icon: Icons.notes_outlined,
              label: 'Notes',
              value: expense.notes!,
            ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Split breakdown
          Text(
            'Split Breakdown',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          ...expense.splits.entries.map((entry) {
            final member = group.members[entry.key];
            final split = entry.value;
            final isPayer = expense.payers.containsKey(entry.key);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        member?.displayName.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(color: AppColors.primaryDark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                member?.displayName ?? 'Unknown',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (isPayer) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Paid',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.secondary,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            split.type == SplitType.percentage
                                ? '${split.percentage?.toStringAsFixed(1)}% of total'
                                : split.type == SplitType.equal
                                    ? 'Equal share'
                                    : 'Exact amount',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      ExchangeRateService.formatAmount(split.amount, group.currency),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) async {
    switch (action) {
      case 'edit':
        // TODO: Navigate to edit screen
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Expense'),
            content: const Text('Are you sure you want to delete this expense?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await ref.read(expensesNotifierProvider.notifier)
              .deleteExpense(groupId, expenseId);
          if (context.mounted) {
            context.pop();
          }
        }
        break;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
