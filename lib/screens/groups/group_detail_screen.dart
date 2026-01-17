import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tabs/config/theme.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/providers/auth_provider.dart';
import 'package:tabs/providers/groups_provider.dart';
import 'package:tabs/providers/expenses_provider.dart';
import 'package:tabs/providers/balances_provider.dart';
import 'package:tabs/services/exchange_rate_service.dart';
import 'package:tabs/services/balance_service.dart';
import 'package:tabs/widgets/common/loading_widget.dart';
import 'package:tabs/widgets/common/error_widget.dart';
import 'package:tabs/widgets/expense/expense_list_item.dart';
import 'package:tabs/widgets/balance/balance_summary.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupProvider(widget.groupId));

    return groupAsync.when(
      loading: () => const Scaffold(body: LoadingWidget()),
      error: (error, _) => Scaffold(
        body: AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(groupProvider(widget.groupId)),
        ),
      ),
      data: (group) {
        if (group == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Group not found')),
          );
        }
        return _buildContent(context, group);
      },
    );
  }

  Widget _buildContent(BuildContext context, ExpenseGroup group) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Activity',
            onPressed: () => context.push('/groups/${widget.groupId}/activity'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, group),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'members',
                child: ListTile(
                  leading: Icon(Icons.people_outline),
                  title: Text('Members'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Balances'),
            Tab(text: 'Totals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ExpensesTab(groupId: widget.groupId, group: group),
          _BalancesTab(groupId: widget.groupId, group: group),
          _TotalsTab(groupId: widget.groupId, group: group),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/groups/${widget.groupId}/expenses/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _handleMenuAction(String action, ExpenseGroup group) {
    switch (action) {
      case 'members':
        _showMembersSheet(group);
        break;
      case 'settings':
        _showSettingsSheet(group);
        break;
    }
  }

  void _showMembersSheet(ExpenseGroup group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return _MembersSheet(
              group: group,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  void _showSettingsSheet(ExpenseGroup group) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Group'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to edit group screen
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('Export Report'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/groups/${widget.groupId}/export');
                },
              ),
              ListTile(
                leading: Icon(Icons.exit_to_app, color: AppColors.error),
                title: Text('Leave Group', style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await _showConfirmDialog(
                    'Leave Group',
                    'Are you sure you want to leave this group?',
                  );
                  if (confirm == true) {
                    await ref.read(groupsNotifierProvider.notifier)
                        .leaveGroup(widget.groupId);
                    if (mounted) context.go('/');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  final String groupId;
  final ExpenseGroup group;

  const _ExpensesTab({required this.groupId, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(groupExpensesProvider(groupId));

    return expensesAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(groupExpensesProvider(groupId)),
      ),
      data: (expenses) {
        if (expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No expenses yet',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first expense',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return ExpenseListItem(
              expense: expense,
              group: group,
              onTap: () => context.push(
                '/groups/$groupId/expenses/${expense.id}',
              ),
            );
          },
        );
      },
    );
  }
}

class _BalancesTab extends ConsumerWidget {
  final String groupId;
  final ExpenseGroup group;

  const _BalancesTab({required this.groupId, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(groupDebtsProvider(groupId));
    final currentUser = ref.watch(currentUserProvider);

    return debtsAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(groupDebtsProvider(groupId)),
      ),
      data: (debts) {
        if (debts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                  'No outstanding balances',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BalanceSummary(
              debts: debts,
              currentUserId: currentUser?.uid ?? '',
              group: group,
              onSettleUp: () => context.push('/groups/$groupId/settle'),
            ),
            const SizedBox(height: 24),
            Text(
              'All Debts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...debts.map((debt) => _DebtCard(debt: debt, group: group)),
          ],
        );
      },
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final ExpenseGroup group;

  const _DebtCard({required this.debt, required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.negative.withOpacity(0.2),
              child: Text(
                debt.fromUserName.substring(0, 1).toUpperCase(),
                style: TextStyle(color: AppColors.negative),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.fromUserName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'owes ${debt.toUserName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              ExchangeRateService.formatAmount(debt.amount, group.currency),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.negative,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsTab extends ConsumerWidget {
  final String groupId;
  final ExpenseGroup group;

  const _TotalsTab({required this.groupId, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(groupExpensesProvider(groupId));

    return expensesAsync.when(
      loading: () => const LoadingWidget(),
      error: (error, _) => AppErrorWidget(
        message: error.toString(),
        onRetry: () => ref.invalidate(groupExpensesProvider(groupId)),
      ),
      data: (expenses) {
        final totalSpent = expenses.fold<double>(
          0,
          (sum, expense) => sum + expense.convertedAmount,
        );

        // Calculate per-member spending
        final memberSpending = <String, double>{};
        for (final expense in expenses) {
          memberSpending[expense.paidBy] =
              (memberSpending[expense.paidBy] ?? 0) + expense.convertedAmount;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Total Spent',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ExchangeRateService.formatAmount(totalSpent, group.currency),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${expenses.length} expense${expenses.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Spending by Member',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...memberSpending.entries.map((entry) {
              final member = group.members[entry.key];
              final percentage = totalSpent > 0
                  ? (entry.value / totalSpent * 100).toStringAsFixed(1)
                  : '0';

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
                            Text(
                              member?.displayName ?? 'Unknown',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '$percentage% of total',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        ExchangeRateService.formatAmount(entry.value, group.currency),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _MembersSheet extends ConsumerStatefulWidget {
  final ExpenseGroup group;
  final ScrollController scrollController;

  const _MembersSheet({
    required this.group,
    required this.scrollController,
  });

  @override
  ConsumerState<_MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends ConsumerState<_MembersSheet> {
  final _emailController = TextEditingController();
  bool _isAddingMember = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    if (_emailController.text.trim().isEmpty) return;

    setState(() => _isAddingMember = true);

    await ref.read(groupsNotifierProvider.notifier).addMember(
      widget.group.id,
      _emailController.text.trim(),
    );

    setState(() => _isAddingMember = false);
    _emailController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final members = widget.group.members.values.toList();

    ref.listen<AsyncValue<void>>(groupsNotifierProvider, (_, state) {
      state.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        },
      );
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Members',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Add member by email',
                        prefixIcon: Icon(Icons.person_add_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isAddingMember ? null : _addMember,
                    icon: _isAddingMember
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isCurrentUser = member.userId == currentUser?.uid;
              final isAdmin = member.role == MemberRole.admin;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    member.displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: AppColors.primaryDark),
                  ),
                ),
                title: Row(
                  children: [
                    Text(member.displayName),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      const Chip(
                        label: Text('You'),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      const Chip(
                        label: Text('Admin'),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ],
                ),
                subtitle: Text(member.email),
              );
            },
          ),
        ),
      ],
    );
  }
}
