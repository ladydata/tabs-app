import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabs/config/theme.dart';
import 'package:tabs/config/routes.dart';
import 'package:tabs/providers/auth_provider.dart';

class TabsApp extends ConsumerWidget {
  const TabsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state to force rebuild when it changes
    final authState = ref.watch(authStateProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      key: ValueKey(authState.valueOrNull?.uid ?? 'signed-out'),
      title: 'Tabs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
