import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/providers/auth_provider.dart';
import 'package:tabs/services/firestore_service.dart';

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
      final userProfile = await _ref.read(currentUserProfileProvider.future);

      if (user == null || userProfile == null) {
        throw Exception('User not authenticated');
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
