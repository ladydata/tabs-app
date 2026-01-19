import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabs/config/theme.dart';
import 'package:tabs/config/routes.dart';
import 'package:tabs/providers/auth_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tabs/l10n/app_localizations.dart';

class TabsApp extends ConsumerWidget {
  const TabsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state to force rebuild when it changes
    final authState = ref.watch(authStateProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      key: ValueKey(authState.valueOrNull?.uid ?? 'signed-out'),
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
