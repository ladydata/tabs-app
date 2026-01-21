import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/providers/auth_provider.dart';
import 'package:tabs/providers/balances_provider.dart';
import 'package:tabs/services/firestore_service.dart';

const int kSettledDaysThreshold = 30;

bool _isGroupSettledAndOld(ExpenseGroup group, Map<String, double> balances) {
  // Check if all balances are ~0
  final isSettled = balances.values.every((b) => b.abs() < 0.01);
  if (!isSettled) return false;

  // Check if 30+ days since last activity
  final daysSinceUpdate = DateTime.now().difference(group.updatedAt).inDays;
  return daysSinceUpdate >= kSettledDaysThreshold;
}

// Firestore service provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// User's groups stream provider
final userGroupsProvider = StreamProvider<List<ExpenseGroup>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getUserGroups(user.uid);
});

/// Groups that are active (not settled or settled < 30 days)
final activeGroupsStreamProvider = StreamProvider<List<ExpenseGroup>>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield [];
    return;
  }

  final groupsStream = ref.watch(userGroupsProvider.stream);

  await for (final groups in groupsStream) {
    final activeGroups = <ExpenseGroup>[];

    for (final group in groups) {
      // Get balances to check if settled
      final balancesAsync = ref.read(groupBalancesProvider(group.id));
      final balances = balancesAsync.valueOrNull ?? {};
      if (!_isGroupSettledAndOld(group, balances)) {
        activeGroups.add(group);
      }
    }

    yield activeGroups;
  }
});

/// Groups that are settled for 30+ days (hidden from main list)
final settledGroupsStreamProvider = StreamProvider<List<ExpenseGroup>>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield [];
    return;
  }

  final groupsStream = ref.watch(userGroupsProvider.stream);

  await for (final groups in groupsStream) {
    final settledGroups = <ExpenseGroup>[];

    for (final group in groups) {
      // Get balances to check if settled
      final balancesAsync = ref.read(groupBalancesProvider(group.id));
      final balances = balancesAsync.valueOrNull ?? {};
      if (_isGroupSettledAndOld(group, balances)) {
        settledGroups.add(group);
      }
    }

    yield settledGroups;
  }
});

// Single group stream provider
final groupProvider = StreamProvider.family<ExpenseGroup?, String>((ref, groupId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.groupStream(groupId);
});

// Group actions notifier
class GroupsNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  GroupsNotifier(this._firestoreService, this._ref) : super(const AsyncValue.data(null));

  Future<String?> createGroup({
    required String name,
    String? description,
    required String currency,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Retry fetching user profile with delay (handles race condition after sign-in)
      AppUser? userProfile;
      for (int i = 0; i < 3; i++) {
        _ref.invalidate(currentUserProfileProvider);
        userProfile = await _ref.read(currentUserProfileProvider.future);
        if (userProfile != null) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (userProfile == null) {
        throw Exception('User profile not found. Please try again.');
      }

      final groupId = await _firestoreService.createGroup(
        name: name,
        description: description,
        currency: currency,
        creatorId: user.uid,
        creatorName: userProfile.displayName,
        creatorEmail: userProfile.email,
      );

      // Log activity
      await _firestoreService.logActivity(
        groupId: groupId,
        type: ActivityType.memberJoined,
        actorUserId: user.uid,
        actorName: userProfile.displayName,
        details: {'action': 'created group'},
      );

      state = const AsyncValue.data(null);
      return groupId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> updateGroup(
    String groupId, {
    String? name,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.updateGroup(groupId, name: name, description: description);

      final user = _ref.read(currentUserProvider);
      final userProfile = await _ref.read(currentUserProfileProvider.future);

      if (user != null && userProfile != null) {
        await _firestoreService.logActivity(
          groupId: groupId,
          type: ActivityType.groupUpdated,
          actorUserId: user.uid,
          actorName: userProfile.displayName,
          details: {
            if (name != null) 'name': name,
            if (description != null) 'description': description,
          },
        );
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMember(String groupId, String email) async {
    state = const AsyncValue.loading();
    try {
      // Find user by email
      final targetUser = await _firestoreService.findUserByEmail(email);
      if (targetUser == null) {
        throw Exception('User with email $email not found');
      }

      await _firestoreService.addMemberToGroup(
        groupId,
        targetUser.uid,
        targetUser.displayName,
        targetUser.email,
      );

      final user = _ref.read(currentUserProvider);
      final userProfile = await _ref.read(currentUserProfileProvider.future);

      if (user != null && userProfile != null) {
        await _firestoreService.logActivity(
          groupId: groupId,
          type: ActivityType.memberJoined,
          actorUserId: user.uid,
          actorName: userProfile.displayName,
          details: {
            'addedUserId': targetUser.uid,
            'addedUserName': targetUser.displayName,
          },
        );
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeMember(String groupId, String userId) async {
    state = const AsyncValue.loading();
    try {
      final group = await _firestoreService.getGroup(groupId);
      final memberName = group?.members[userId]?.displayName ?? 'Unknown';

      await _firestoreService.removeMemberFromGroup(groupId, userId);

      final user = _ref.read(currentUserProvider);
      final userProfile = await _ref.read(currentUserProfileProvider.future);

      if (user != null && userProfile != null) {
        await _firestoreService.logActivity(
          groupId: groupId,
          type: ActivityType.memberLeft,
          actorUserId: user.uid,
          actorName: userProfile.displayName,
          details: {
            'removedUserId': userId,
            'removedUserName': memberName,
          },
        );
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> leaveGroup(String groupId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    await removeMember(groupId, user.uid);
  }

  Future<void> deleteGroup(String groupId) async {
    state = const AsyncValue.loading();
    try {
      await _firestoreService.deleteGroup(groupId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final groupsNotifierProvider =
    StateNotifierProvider<GroupsNotifier, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return GroupsNotifier(firestoreService, ref);
});
