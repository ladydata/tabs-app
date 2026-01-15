import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tabs/config/theme.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/providers/auth_provider.dart';
import 'package:tabs/providers/groups_provider.dart';
import 'package:tabs/providers/balances_provider.dart';
import 'package:tabs/services/exchange_rate_service.dart';
import 'package:tabs/services/balance_service.dart';
import 'package:tabs/widgets/common/loading_widget.dart';

class SettleUpScreen extends ConsumerStatefulWidget {
  final String groupId;

  const SettleUpScreen({super.key, required this.groupId});

  @override
  ConsumerState<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends ConsumerState<SettleUpScreen> {
  String? _fromUserId;
  String? _toUserId;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupProvider(widget.groupId));
    final debtsAsync = ref.watch(groupDebtsProvider(widget.groupId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settle Up'),
      ),
      body: groupAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (group) {
          if (group == null) {
            return const Center(child: Text('Group not found'));
          }

          return debtsAsync.when(
            loading: () => const LoadingWidget(),
            error: (error, _) => Center(child: Text('Error: $error')),
            data: (debts) {
              // Filter to debts involving current user
              final userDebts = debts
                  .where((d) => d.involvesUser(currentUser?.uid ?? ''))
                  .toList();

              return _buildContent(context, group, userDebts, currentUser?.uid);
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ExpenseGroup group,
    List<Debt> userDebts,
    String? currentUserId,
  ) {
    // Initialize with first debt if available
    if (_fromUserId == null && _toUserId == null && userDebts.isNotEmpty) {
      final firstDebt = userDebts.first;
      if (firstDebt.fromUserId == currentUserId) {
        _fromUserId = firstDebt.fromUserId;
        _toUserId = firstDebt.toUserId;
        _amountController.text = firstDebt.amount.toStringAsFixed(2);
      } else {
        _fromUserId = firstDebt.fromUserId;
        _toUserId = firstDebt.toUserId;
        _amountController.text = firstDebt.amount.toStringAsFixed(2);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (userDebts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All settled up!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have no outstanding balances',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Text(
              'Quick Settle',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...userDebts.map((debt) {
              final isSelected = debt.fromUserId == _fromUserId &&
                  debt.toUserId == _toUserId;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isSelected ? AppColors.primaryLight.withOpacity(0.2) : null,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _fromUserId = debt.fromUserId;
                      _toUserId = debt.toUserId;
                      _amountController.text = debt.amount.toStringAsFixed(2);
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: debt.fromUserId == currentUserId
                              ? AppColors.negative.withOpacity(0.2)
                              : AppColors.positive.withOpacity(0.2),
                          child: Text(
                            debt.fromUserName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: debt.fromUserId == currentUserId
                                  ? AppColors.negative
                                  : AppColors.positive,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                debt.fromUserId == currentUserId
                                    ? 'You owe ${debt.toUserName}'
                                    : '${debt.fromUserName} owes you',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          ExchangeRateService.formatAmount(debt.amount, group.currency),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: debt.fromUserId == currentUserId
                                    ? AppColors.negative
                                    : AppColors.positive,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle, color: AppColors.primary),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            Text(
              'Settlement Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // From (payer)
            DropdownButtonFormField<String>(
              value: _fromUserId,
              decoration: const InputDecoration(
                labelText: 'Who paid',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              items: group.members.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _fromUserId = value);
              },
            ),

            const SizedBox(height: 16),

            // To (receiver)
            DropdownButtonFormField<String>(
              value: _toUserId,
              decoration: const InputDecoration(
                labelText: 'Who received',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              items: group.members.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _toUserId = value);
              },
            ),

            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${ExchangeRateService.getCurrencySymbol(group.currency)} ',
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : () => _recordSettlement(group),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Record Settlement'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _recordSettlement(ExpenseGroup group) async {
    if (_fromUserId == null || _toUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both parties')),
      );
      return;
    }

    if (_fromUserId == _toUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payer and receiver must be different')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(settlementsNotifierProvider.notifier).createSettlement(
            groupId: widget.groupId,
            fromUserId: _fromUserId!,
            toUserId: _toUserId!,
            amount: amount,
            date: DateTime.now(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settlement recorded'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
