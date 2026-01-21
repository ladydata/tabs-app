import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tabs/config/routes.dart';
import 'package:tabs/config/theme.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/providers/auth_provider.dart';
import 'package:tabs/providers/groups_provider.dart';
import 'package:tabs/widgets/common/loading_widget.dart';
import 'package:tabs/widgets/common/error_widget.dart';
import 'package:tabs/widgets/group/group_card.dart';
import 'package:tabs/widgets/group/settled_tabs_card.dart';
import 'package:tabs/l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(activeGroupsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              _showProfileMenu(context, ref);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          groupsAsync.when(
            loading: () => const LoadingWidget(),
            error: (error, _) => AppErrorWidget(
              message: error.toString(),
              onRetry: () => ref.invalidate(activeGroupsStreamProvider),
            ),
            data: (groups) {
              if (groups.isEmpty) {
                return _buildEmptyState(context);
              }
              return _buildGroupsList(context, ref, groups);
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SettledTabsCard(
              onTap: () => context.push(AppRoutes.settledTabs),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createGroup),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.newGroup),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noGroupsYet,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.createGroupPrompt,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push(AppRoutes.createGroup),
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.createGroup),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsList(
    BuildContext context,
    WidgetRef ref,
    List<ExpenseGroup> groups,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GroupCard(
            group: group,
            onTap: () => context.push('/groups/${group.id}'),
          ),
        );
      },
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    final userProfile = ref.read(currentUserProfileProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: userProfile.when(
                    data: (user) => Text(
                      user?.displayName.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const Text('?'),
                  ),
                ),
                title: userProfile.when(
                  data: (user) => Text(user?.displayName ?? 'User'),
                  loading: () => Text(AppLocalizations.of(context)!.loading),
                  error: (_, __) => const Text('Error'),
                ),
                subtitle: userProfile.when(
                  data: (user) => Text(user?.email ?? ''),
                  loading: () => null,
                  error: (_, __) => null,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(AppLocalizations.of(context)!.signOut),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authNotifierProvider.notifier).signOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
