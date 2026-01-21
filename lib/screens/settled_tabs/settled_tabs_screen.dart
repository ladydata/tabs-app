import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tabs/config/theme.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/providers/groups_provider.dart';
import 'package:tabs/l10n/app_localizations.dart';

class SettledTabsScreen extends ConsumerStatefulWidget {
  const SettledTabsScreen({super.key});

  @override
  ConsumerState<SettledTabsScreen> createState() => _SettledTabsScreenState();
}

class _SettledTabsScreenState extends ConsumerState<SettledTabsScreen> {
  ExpenseGroup? _recentlyDeleted;

  Future<void> _deleteGroup(ExpenseGroup group) async {
    setState(() {
      _recentlyDeleted = group;
    });

    // Show undo snackbar
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.tabDeleted),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.undo,
          onPressed: () {
            setState(() {
              _recentlyDeleted = null;
            });
          },
        ),
      ),
    ).closed.then((reason) async {
      // If not dismissed by undo action, delete permanently
      if (reason != SnackBarClosedReason.action && _recentlyDeleted?.id == group.id) {
        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.deleteGroup(group.id);
        setState(() {
          _recentlyDeleted = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settledGroupsAsync = ref.watch(settledGroupsStreamProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settledTabs),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: settledGroupsAsync.when(
        data: (groups) {
          // Filter out recently deleted group from display
          final displayGroups = _recentlyDeleted != null
              ? groups.where((g) => g.id != _recentlyDeleted!.id).toList()
              : groups;

          if (displayGroups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noSettledTabs,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: displayGroups.length,
            itemBuilder: (context, index) {
              final group = displayGroups[index];
              final daysSinceUpdate = DateTime.now().difference(group.updatedAt).inDays;

              return Slidable(
                key: ValueKey(group.id),
                endActionPane: ActionPane(
                  motion: const BehindMotion(),
                  dismissible: DismissiblePane(
                    onDismissed: () => _deleteGroup(group),
                  ),
                  children: [
                    SlidableAction(
                      onPressed: (_) => _deleteGroup(group),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        group.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(group.name),
                    subtitle: Text(
                      l10n.settledDaysAgo(daysSinceUpdate),
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${group.memberIds.length}',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: AppColors.textSecondary,
                          tooltip: 'Delete',
                          onPressed: () => _deleteGroup(group),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
