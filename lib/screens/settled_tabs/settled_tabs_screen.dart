import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:tabs/config/theme.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/providers/groups_provider.dart';
import 'package:tabs/services/firestore_service.dart';
import 'package:tabs/l10n/app_localizations.dart';

class SettledTabsScreen extends ConsumerStatefulWidget {
  const SettledTabsScreen({super.key});

  @override
  ConsumerState<SettledTabsScreen> createState() => _SettledTabsScreenState();
}

class _SettledTabsScreenState extends ConsumerState<SettledTabsScreen> {
  late final FirestoreService _firestoreService;
  ScaffoldMessengerState? _scaffoldMessenger;
  final Set<String> _pendingDeletes = {};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _firestoreService = ref.read(firestoreServiceProvider);
      _initialized = true;
    }
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    // Clear any showing snackbar and execute pending deletes
    _scaffoldMessenger?.clearSnackBars();
    for (final groupId in _pendingDeletes) {
      _firestoreService.deleteGroup(groupId);
    }
    super.dispose();
  }

  Future<void> _deleteGroup(ExpenseGroup group) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = _scaffoldMessenger;
    if (messenger == null) return;

    // Add to pending deletes
    _pendingDeletes.add(group.id);

    // Clear any existing snackbar
    messenger.clearSnackBars();

    // Show undo snackbar
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.tabDeleted),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () {
            // Remove from pending - undo was pressed
            _pendingDeletes.remove(group.id);
          },
        ),
      ),
    );

    // Wait for snackbar to close
    await controller.closed;

    // If still in pending set (undo wasn't pressed), perform delete
    if (_pendingDeletes.contains(group.id)) {
      _pendingDeletes.remove(group.id);
      try {
        await _firestoreService.deleteGroup(group.id);
      } catch (e) {
        // Show error if still mounted
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Error deleting: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
          if (groups.isEmpty) {
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
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
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
