# Settled Tabs Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Auto-hide settled tabs (30+ days inactive) from the main list and provide a dedicated "Settled Tabs" screen with swipe-to-delete.

**Architecture:** Client-side filtering of groups into active vs settled (30+ days). A floating card on the home screen links to a new Settled Tabs screen. Swipe-to-delete with undo snackbar for safe deletion.

**Tech Stack:** Flutter, Riverpod (providers), Firestore (existing), flutter_slidable (for swipe actions)

---

## Task 1: Add flutter_slidable dependency

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Add dependency**

Add to `pubspec.yaml` under dependencies:

```yaml
  flutter_slidable: ^3.1.0
```

**Step 2: Install**

Run: `flutter pub get`
Expected: Resolving dependencies... Got dependencies!

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: Add flutter_slidable for swipe-to-delete"
```

---

## Task 2: Create settled groups provider

**Files:**
- Modify: `lib/providers/groups_provider.dart`

**Step 1: Add constants and helper**

At top of file after imports (around line 10), add:

```dart
const int kSettledDaysThreshold = 30;

bool _isGroupSettledAndOld(ExpenseGroup group, Map<String, double> balances) {
  // Check if all balances are ~0
  final isSettled = balances.values.every((b) => b.abs() < 0.01);
  if (!isSettled) return false;

  // Check if 30+ days since last activity
  final daysSinceUpdate = DateTime.now().difference(group.updatedAt).inDays;
  return daysSinceUpdate >= kSettledDaysThreshold;
}
```

**Step 2: Create active groups provider**

After `userGroupsProvider` (around line 20), add:

```dart
/// Groups that are active (not settled or settled < 30 days)
@riverpod
Stream<List<ExpenseGroup>> activeGroupsStream(Ref ref) async* {
  final userId = ref.watch(authStateProvider).value?.uid;
  if (userId == null) {
    yield [];
    return;
  }

  final groupsStream = ref.watch(userGroupsProvider.stream);

  await for (final groups in groupsStream) {
    final activeGroups = <ExpenseGroup>[];

    for (final group in groups) {
      // Get balances to check if settled
      final balances = await ref.read(groupBalancesProvider(group.id).future);
      if (!_isGroupSettledAndOld(group, balances)) {
        activeGroups.add(group);
      }
    }

    yield activeGroups;
  }
}
```

**Step 3: Create settled groups provider**

After the active groups provider, add:

```dart
/// Groups that are settled for 30+ days (hidden from main list)
@riverpod
Stream<List<ExpenseGroup>> settledGroupsStream(Ref ref) async* {
  final userId = ref.watch(authStateProvider).value?.uid;
  if (userId == null) {
    yield [];
    return;
  }

  final groupsStream = ref.watch(userGroupsProvider.stream);

  await for (final groups in groupsStream) {
    final settledGroups = <ExpenseGroup>[];

    for (final group in groups) {
      // Get balances to check if settled
      final balances = await ref.read(groupBalancesProvider(group.id).future);
      if (_isGroupSettledAndOld(group, balances)) {
        settledGroups.add(group);
      }
    }

    yield settledGroups;
  }
}
```

**Step 4: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: Build completed successfully

**Step 5: Commit**

```bash
git add lib/providers/groups_provider.dart lib/providers/groups_provider.g.dart
git commit -m "feat: Add active/settled groups providers with 30-day threshold"
```

---

## Task 3: Create Settled Tabs floating card widget

**Files:**
- Create: `lib/widgets/group/settled_tabs_card.dart`

**Step 1: Create the widget file**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabs/config/theme.dart';
import 'package:tabs/providers/groups_provider.dart';
import 'package:tabs/l10n/app_localizations.dart';

class SettledTabsCard extends ConsumerWidget {
  final VoidCallback onTap;

  const SettledTabsCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settledGroupsAsync = ref.watch(settledGroupsStreamProvider);

    return settledGroupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.all(16),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: AppColors.surfaceLight,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${AppLocalizations.of(context)!.settledTabs} (${groups.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.tapToView,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/widgets/group/settled_tabs_card.dart
git commit -m "feat: Add SettledTabsCard floating widget"
```

---

## Task 4: Add localization strings

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_de.arb`
- Modify: `lib/l10n/app_pt.arb`

**Step 1: Add English strings**

In `lib/l10n/app_en.arb`, add before the closing `}`:

```json
  "settledTabs": "Settled Tabs",
  "tapToView": "Tap to view",
  "settledDaysAgo": "Settled {days} days ago",
  "@settledDaysAgo": {
    "placeholders": {
      "days": {
        "type": "int"
      }
    }
  },
  "tabDeleted": "Tab deleted",
  "undo": "Undo",
  "noSettledTabs": "No settled tabs"
```

**Step 2: Add German strings**

In `lib/l10n/app_de.arb`, add before the closing `}`:

```json
  "settledTabs": "Abgerechnete Tabs",
  "tapToView": "Tippen zum Anzeigen",
  "settledDaysAgo": "Vor {days} Tagen abgerechnet",
  "@settledDaysAgo": {
    "placeholders": {
      "days": {
        "type": "int"
      }
    }
  },
  "tabDeleted": "Tab gelöscht",
  "undo": "Rückgängig",
  "noSettledTabs": "Keine abgerechneten Tabs"
```

**Step 3: Add Portuguese strings**

In `lib/l10n/app_pt.arb`, add before the closing `}`:

```json
  "settledTabs": "Grupos Quitados",
  "tapToView": "Toque para ver",
  "settledDaysAgo": "Quitado há {days} dias",
  "@settledDaysAgo": {
    "placeholders": {
      "days": {
        "type": "int"
      }
    }
  },
  "tabDeleted": "Grupo excluído",
  "undo": "Desfazer",
  "noSettledTabs": "Nenhum grupo quitado"
```

**Step 4: Generate localizations**

Run: `flutter gen-l10n`
Expected: Files generated successfully

**Step 5: Commit**

```bash
git add lib/l10n/
git commit -m "feat: Add localization strings for settled tabs feature"
```

---

## Task 5: Create Settled Tabs screen

**Files:**
- Create: `lib/screens/settled_tabs/settled_tabs_screen.dart`

**Step 1: Create the screen file**

```dart
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
                    color: AppColors.textTertiary,
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
```

**Step 2: Commit**

```bash
git add lib/screens/settled_tabs/settled_tabs_screen.dart
git commit -m "feat: Add SettledTabsScreen with swipe-to-delete"
```

---

## Task 6: Add route for Settled Tabs screen

**Files:**
- Modify: `lib/config/router.dart`

**Step 1: Add import**

At top of file, add:

```dart
import 'package:tabs/screens/settled_tabs/settled_tabs_screen.dart';
```

**Step 2: Add route**

Find the routes list and add after the home route (look for `GoRoute` definitions):

```dart
GoRoute(
  path: '/settled-tabs',
  builder: (context, state) => const SettledTabsScreen(),
),
```

**Step 3: Commit**

```bash
git add lib/config/router.dart
git commit -m "feat: Add route for SettledTabsScreen"
```

---

## Task 7: Update HomeScreen to use active groups and show floating card

**Files:**
- Modify: `lib/screens/home/home_screen.dart`

**Step 1: Add imports**

At top of file, add:

```dart
import 'package:tabs/widgets/group/settled_tabs_card.dart';
import 'package:go_router/go_router.dart';
```

**Step 2: Replace userGroupsProvider with activeGroupsStreamProvider**

Find line ~22 where `userGroupsProvider` is watched:

```dart
final groupsAsync = ref.watch(userGroupsProvider);
```

Replace with:

```dart
final groupsAsync = ref.watch(activeGroupsStreamProvider);
```

**Step 3: Wrap body with Stack and add floating card**

Find the `Scaffold` body. Change from:

```dart
body: groupsAsync.when(
  data: (groups) {
    // ... existing content
  },
  // ...
),
```

To:

```dart
body: Stack(
  children: [
    groupsAsync.when(
      data: (groups) {
        // ... existing content (with bottom padding added to ListView)
      },
      // ...
    ),
    Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SettledTabsCard(
        onTap: () => context.push('/settled-tabs'),
      ),
    ),
  ],
),
```

**Step 4: Add bottom padding to ListView**

Find `_buildGroupsList` method. Update the ListView padding:

```dart
return ListView.builder(
  padding: const EdgeInsets.only(top: 8, bottom: 80), // Add bottom padding for floating card
  // ... rest unchanged
);
```

**Step 5: Commit**

```bash
git add lib/screens/home/home_screen.dart
git commit -m "feat: Show active groups only and add floating SettledTabsCard"
```

---

## Task 8: Remove "Clean Up Inactive Tabs" from profile menu

**Files:**
- Modify: `lib/screens/home/home_screen.dart`
- Delete: `lib/widgets/profile/settled_groups_dialog.dart`

**Step 1: Remove menu item from HomeScreen**

In `home_screen.dart`, find the PopupMenuButton items (around line 152-159). Remove the "Clean Up Inactive Tabs" item:

```dart
// DELETE THIS BLOCK:
PopupMenuItem(
  child: ListTile(
    leading: const Icon(Icons.cleaning_services),
    title: Text(AppLocalizations.of(context)!.cleanUpInactiveTabs),
    contentPadding: EdgeInsets.zero,
  ),
  onTap: () {
    // Show settled groups dialog
    showDialog(
      context: context,
      builder: (context) => const SettledGroupsDialog(),
    );
  },
),
```

**Step 2: Remove import**

Remove the import for `settled_groups_dialog.dart`:

```dart
// DELETE THIS LINE:
import 'package:tabs/widgets/profile/settled_groups_dialog.dart';
```

**Step 3: Delete the old dialog file**

Run: `rm lib/widgets/profile/settled_groups_dialog.dart`

**Step 4: Remove localization string (optional cleanup)**

In `lib/l10n/app_en.arb`, `app_de.arb`, `app_pt.arb`, remove `cleanUpInactiveTabs` if it exists.

**Step 5: Commit**

```bash
git add -A
git commit -m "refactor: Remove old Clean Up Inactive Tabs feature"
```

---

## Task 9: Add firestoreServiceProvider if missing

**Files:**
- Modify: `lib/providers/groups_provider.dart` (if needed)

**Step 1: Check if provider exists**

Search for `firestoreServiceProvider` in the codebase. If it doesn't exist, add to `lib/providers/groups_provider.dart`:

```dart
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
```

**Step 2: Commit if changes made**

```bash
git add lib/providers/
git commit -m "chore: Add firestoreServiceProvider"
```

---

## Task 10: Add unit tests for settled groups logic

**Files:**
- Create: `test/providers/settled_groups_test.dart`

**Step 1: Create test file with mocks**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/providers/groups_provider.dart';

void main() {
  group('Settled Groups Logic', () {
    // Helper to create a test group with specific updatedAt
    ExpenseGroup createTestGroup({
      required String id,
      required String name,
      required DateTime updatedAt,
    }) {
      final now = DateTime.now();
      return ExpenseGroup(
        id: id,
        name: name,
        currency: 'USD',
        members: {
          'user1': GroupMember(
            userId: 'user1',
            displayName: 'User 1',
            email: 'user1@test.com',
            joinedAt: now,
          ),
          'user2': GroupMember(
            userId: 'user2',
            displayName: 'User 2',
            email: 'user2@test.com',
            joinedAt: now,
          ),
        },
        memberIds: ['user1', 'user2'],
        createdBy: 'user1',
        createdAt: now,
        updatedAt: updatedAt,
      );
    }

    test('Group updated today with zero balances is NOT old settled', () {
      final group = createTestGroup(
        id: 'group1',
        name: 'Recent Settled',
        updatedAt: DateTime.now(),
      );
      final balances = {'user1': 0.0, 'user2': 0.0};

      // Settled but not 30+ days old
      final isSettled = balances.values.every((b) => b.abs() < 0.01);
      final daysSinceUpdate = DateTime.now().difference(group.updatedAt).inDays;
      final isOldSettled = isSettled && daysSinceUpdate >= kSettledDaysThreshold;

      expect(isSettled, true);
      expect(isOldSettled, false);
    });

    test('Group updated 29 days ago with zero balances is NOT old settled', () {
      final group = createTestGroup(
        id: 'group2',
        name: '29 Days Settled',
        updatedAt: DateTime.now().subtract(const Duration(days: 29)),
      );
      final balances = {'user1': 0.0, 'user2': 0.0};

      final isSettled = balances.values.every((b) => b.abs() < 0.01);
      final daysSinceUpdate = DateTime.now().difference(group.updatedAt).inDays;
      final isOldSettled = isSettled && daysSinceUpdate >= kSettledDaysThreshold;

      expect(isSettled, true);
      expect(daysSinceUpdate, 29);
      expect(isOldSettled, false);
    });

    test('Group updated 30 days ago with zero balances IS old settled', () {
      final group = createTestGroup(
        id: 'group3',
        name: '30 Days Settled',
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      final balances = {'user1': 0.0, 'user2': 0.0};

      final isSettled = balances.values.every((b) => b.abs() < 0.01);
      final daysSinceUpdate = DateTime.now().difference(group.updatedAt).inDays;
      final isOldSettled = isSettled && daysSinceUpdate >= kSettledDaysThreshold;

      expect(isSettled, true);
      expect(daysSinceUpdate, 30);
      expect(isOldSettled, true);
    });

    test('Group updated 45 days ago with zero balances IS old settled', () {
      final group = createTestGroup(
        id: 'group4',
        name: '45 Days Settled',
        updatedAt: DateTime.now().subtract(const Duration(days: 45)),
      );
      final balances = {'user1': 0.0, 'user2': 0.0};

      final isSettled = balances.values.every((b) => b.abs() < 0.01);
      final daysSinceUpdate = DateTime.now().difference(group.updatedAt).inDays;
      final isOldSettled = isSettled && daysSinceUpdate >= kSettledDaysThreshold;

      expect(isSettled, true);
      expect(daysSinceUpdate, 45);
      expect(isOldSettled, true);
    });

    test('Group updated 60 days ago with NON-zero balances is NOT old settled', () {
      final group = createTestGroup(
        id: 'group5',
        name: 'Old But Active',
        updatedAt: DateTime.now().subtract(const Duration(days: 60)),
      );
      final balances = {'user1': 25.50, 'user2': -25.50}; // Not settled

      final isSettled = balances.values.every((b) => b.abs() < 0.01);
      final daysSinceUpdate = DateTime.now().difference(group.updatedAt).inDays;
      final isOldSettled = isSettled && daysSinceUpdate >= kSettledDaysThreshold;

      expect(isSettled, false);
      expect(isOldSettled, false);
    });

    test('Group with near-zero balances (< 0.01) counts as settled', () {
      final group = createTestGroup(
        id: 'group6',
        name: 'Near Zero',
        updatedAt: DateTime.now().subtract(const Duration(days: 35)),
      );
      final balances = {'user1': 0.005, 'user2': -0.005}; // Near zero

      final isSettled = balances.values.every((b) => b.abs() < 0.01);
      final daysSinceUpdate = DateTime.now().difference(group.updatedAt).inDays;
      final isOldSettled = isSettled && daysSinceUpdate >= kSettledDaysThreshold;

      expect(isSettled, true);
      expect(isOldSettled, true);
    });
  });
}
```

**Step 2: Run tests to verify they pass**

Run: `flutter test test/providers/settled_groups_test.dart -v`
Expected: All 6 tests pass

**Step 3: Commit**

```bash
git add test/providers/settled_groups_test.dart
git commit -m "test: Add unit tests for settled groups 30-day threshold logic"
```

---

## Task 11: Run full test suite and fix any issues

**Step 1: Run all tests**

Run: `flutter test`
Expected: All tests passed!

**Step 2: Fix any failures**

If tests fail, investigate and fix.

**Step 3: Run build to verify no compile errors**

Run: `flutter build macos --debug`
Expected: Build successful

**Step 4: Final commit**

```bash
git add -A
git commit -m "chore: Ensure all tests pass and build succeeds"
```

---

## Task 12: Manual testing checklist

**Step 1: Test active groups filtering**

- [ ] Create a new group with expenses
- [ ] Verify it appears in main list
- [ ] Settle all balances
- [ ] Verify it still appears (less than 30 days)

**Step 2: Test settled tabs card**

- [ ] When no settled tabs exist, floating card should be hidden
- [ ] When settled tabs exist, card shows correct count
- [ ] Tapping card navigates to Settled Tabs screen

**Step 3: Test swipe-to-delete**

- [ ] Swipe left on a settled tab reveals delete action
- [ ] Completing swipe shows "Tab deleted" snackbar with Undo
- [ ] Tapping Undo restores the tab
- [ ] Letting snackbar timeout permanently deletes the tab
- [ ] Tab is removed from Firestore after deletion

**Step 4: Test edge cases**

- [ ] App handles 0 settled tabs gracefully
- [ ] App handles 0 active tabs gracefully
- [ ] Navigation back from Settled Tabs works correctly

---

## Summary

| Task | Description | Files Changed |
|------|-------------|---------------|
| 1 | Add flutter_slidable | pubspec.yaml |
| 2 | Create providers | groups_provider.dart |
| 3 | Create floating card | settled_tabs_card.dart |
| 4 | Add localizations | app_*.arb |
| 5 | Create screen | settled_tabs_screen.dart |
| 6 | Add route | router.dart |
| 7 | Update HomeScreen | home_screen.dart |
| 8 | Remove old feature | home_screen.dart, delete dialog |
| 9 | Add provider if needed | groups_provider.dart |
| 10 | Add unit tests | settled_groups_test.dart |
| 11 | Run tests | - |
| 12 | Manual testing | - |
