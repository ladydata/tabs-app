import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tabs/config/theme.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/providers/groups_provider.dart';
import 'package:tabs/services/exchange_rate_service.dart';
import 'package:tabs/widgets/common/loading_widget.dart';
import 'package:tabs/widgets/common/error_widget.dart';

// Activity stream provider
final groupActivityProvider =
    StreamProvider.family<List<ActivityLog>, String>((ref, groupId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getGroupActivity(groupId);
});

class ActivityScreen extends ConsumerWidget {
  final String groupId;

  const ActivityScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(groupActivityProvider(groupId));
    final groupAsync = ref.watch(groupProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
      ),
      body: groupAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(groupActivityProvider(groupId)),
        ),
        data: (group) {
          if (group == null) {
            return const Center(child: Text('Group not found'));
          }

          return activityAsync.when(
            loading: () => const LoadingWidget(),
            error: (error, _) => AppErrorWidget(
              message: error.toString(),
              onRetry: () => ref.invalidate(groupActivityProvider(groupId)),
            ),
            data: (activities) {
              if (activities.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No activity yet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Activities will appear here',
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
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  final showDateHeader = index == 0 ||
                      !_isSameDay(
                        activities[index - 1].createdAt,
                        activity.createdAt,
                      );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showDateHeader) ...[
                        if (index > 0) const SizedBox(height: 16),
                        _DateHeader(date: activity.createdAt),
                        const SizedBox(height: 8),
                      ],
                      _ActivityItem(activity: activity, group: group),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    String label;
    if (dateOnly == today) {
      label = 'Today';
    } else if (dateOnly == yesterday) {
      label = 'Yesterday';
    } else {
      label = DateFormat('EEEE, MMMM d').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final ActivityLog activity;
  final ExpenseGroup group;

  const _ActivityItem({
    required this.activity,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActivityIcon(type: activity.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getActivityTitle(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getActivityDescription(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              timeFormat.format(activity.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _getActivityTitle() {
    switch (activity.type) {
      case ActivityType.expenseAdded:
        return '${activity.actorName} added an expense';
      case ActivityType.expenseUpdated:
        return '${activity.actorName} updated an expense';
      case ActivityType.expenseDeleted:
        return '${activity.actorName} deleted an expense';
      case ActivityType.settlementAdded:
        return '${activity.actorName} recorded a settlement';
      case ActivityType.memberJoined:
        if (activity.details['action'] == 'created group') {
          return '${activity.actorName} created this group';
        }
        final addedName = activity.details['addedUserName'] ?? 'Someone';
        return '${activity.actorName} added $addedName';
      case ActivityType.memberLeft:
        final removedName = activity.details['removedUserName'] ?? 'Someone';
        return '$removedName left the group';
      case ActivityType.groupUpdated:
        return '${activity.actorName} updated the group';
    }
  }

  String _getActivityDescription() {
    switch (activity.type) {
      case ActivityType.expenseAdded:
      case ActivityType.expenseUpdated:
        final title = activity.details['title'] ?? 'Expense';
        final amount = activity.details['convertedAmount'] ?? 0;
        final currency = activity.details['groupCurrency'] ?? group.currency;
        return '$title - ${ExchangeRateService.formatAmount(amount.toDouble(), currency)}';
      case ActivityType.expenseDeleted:
        return activity.details['title'] ?? 'Expense deleted';
      case ActivityType.settlementAdded:
        final from = activity.details['fromUserName'] ?? 'Someone';
        final to = activity.details['toUserName'] ?? 'Someone';
        final amount = activity.details['amount'] ?? 0;
        final currency = activity.details['currency'] ?? group.currency;
        return '$from paid $to ${ExchangeRateService.formatAmount(amount.toDouble(), currency)}';
      case ActivityType.memberJoined:
        if (activity.details['action'] == 'created group') {
          return 'Group created with ${group.currency} currency';
        }
        return 'New member added to the group';
      case ActivityType.memberLeft:
        return 'Member removed from the group';
      case ActivityType.groupUpdated:
        final changes = <String>[];
        if (activity.details.containsKey('name')) {
          changes.add('name changed');
        }
        if (activity.details.containsKey('description')) {
          changes.add('description updated');
        }
        return changes.isEmpty ? 'Group settings changed' : changes.join(', ');
    }
  }
}

class _ActivityIcon extends StatelessWidget {
  final ActivityType type;

  const _ActivityIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case ActivityType.expenseAdded:
        icon = Icons.add_circle_outline;
        color = AppColors.secondary;
        break;
      case ActivityType.expenseUpdated:
        icon = Icons.edit_outlined;
        color = AppColors.primary;
        break;
      case ActivityType.expenseDeleted:
        icon = Icons.remove_circle_outline;
        color = AppColors.error;
        break;
      case ActivityType.settlementAdded:
        icon = Icons.check_circle_outline;
        color = AppColors.success;
        break;
      case ActivityType.memberJoined:
        icon = Icons.person_add_outlined;
        color = AppColors.primary;
        break;
      case ActivityType.memberLeft:
        icon = Icons.person_remove_outlined;
        color = AppColors.textSecondary;
        break;
      case ActivityType.groupUpdated:
        icon = Icons.settings_outlined;
        color = AppColors.textSecondary;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
