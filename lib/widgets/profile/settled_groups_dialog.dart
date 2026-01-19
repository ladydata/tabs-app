import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tabs/config/theme.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/providers/auth_provider.dart';
import 'package:tabs/providers/groups_provider.dart';
import 'package:tabs/services/balance_service.dart';
import 'package:tabs/providers/balances_provider.dart';
import 'package:tabs/services/firestore_service.dart';
import 'package:tabs/l10n/app_localizations.dart';

class SettledGroupsDialog extends ConsumerStatefulWidget {
  const SettledGroupsDialog({super.key});

  @override
  ConsumerState<SettledGroupsDialog> createState() => _SettledGroupsDialogState();
}

class _SettledGroupsDialogState extends ConsumerState<SettledGroupsDialog> {
  bool _isLoading = true;
  List<ExpenseGroup> _settledGroups = [];
  final Set<String> _selectedGroupIds = {};
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _scanGroups();
  }

  Future<void> _scanGroups() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Scanning your groups...'; // Use localized string in real implementation or refactor later
    });

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      // 1. Get all groups
      final groups = await ref.read(userGroupsProvider.future);
      
      final firestoreService = ref.read(firestoreServiceProvider);
      final balanceService = ref.read(balanceServiceProvider);
      final inactiveSettledGroups = <ExpenseGroup>[];

      // 30 days ago
      final inactivityThreshold = DateTime.now().subtract(const Duration(days: 30));

      int scanned = 0;
      for (final group in groups) {
        scanned++;
        setState(() {
          _statusMessage = 'Scanning ${scanned}/${groups.length}: ${group.name}';
        });

        // 2. Filter by inactivity (updatedAt < threshold)
        if (group.updatedAt.isAfter(inactivityThreshold)) {
          continue; // Active recently, skip
        }

        // 3. Filter by role (must be admin to delete)
        // Check if current user is admin of this group
        final member = group.members[currentUser.uid];
        if (member?.role != MemberRole.admin) {
          continue; 
        }

        // 4. Check if settled
        final expenses = await firestoreService.getGroupExpensesOnce(group.id);
        final settlements = await firestoreService.getGroupSettlementsOnce(group.id);
        
        if (balanceService.isGroupSettled(expenses, settlements)) {
          inactiveSettledGroups.add(group);
        }
      }

      if (mounted) {
        setState(() {
          _settledGroups = inactiveSettledGroups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error scanning groups: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedGroupIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete ${_selectedGroupIds.length} groups? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      
      for (final groupId in _selectedGroupIds) {
         await firestoreService.deleteGroup(groupId);
      }
      
      // Refresh list
      await ref.refresh(userGroupsProvider.future);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted ${_selectedGroupIds.length} groups')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting groups: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.cleaning_services_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Clean Up Inactive Tabs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tabs that have been inactive for 30+ days and are fully settled.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(_statusMessage ?? 'Loading...'),
                        ],
                      ),
                    )
                  : _settledGroups.isEmpty
                      ? Center(
                          child: Text(
                            'No inactive settled tabs found.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _settledGroups.length,
                          itemBuilder: (context, index) {
                            final group = _settledGroups[index];
                            final isSelected = _selectedGroupIds.contains(group.id);
                            
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedGroupIds.add(group.id);
                                  } else {
                                    _selectedGroupIds.remove(group.id);
                                  }
                                });
                              },
                              title: Text(group.name),
                              subtitle: Text('Last active: ${DateFormat.yMMMd().format(group.updatedAt)}'),
                              secondary: CircleAvatar(
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  group.name[0].toUpperCase(),
                                  style: const TextStyle(color: AppColors.primaryDark),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectedGroupIds.isEmpty || _isLoading ? null : _deleteSelected,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Delete (${_selectedGroupIds.length})'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
