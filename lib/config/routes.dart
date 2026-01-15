import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tabs/providers/auth_provider.dart';
import 'package:tabs/screens/auth/sign_in_screen.dart';
import 'package:tabs/screens/auth/sign_up_screen.dart';
import 'package:tabs/screens/home/home_screen.dart';
import 'package:tabs/screens/groups/group_detail_screen.dart';
import 'package:tabs/screens/groups/create_group_screen.dart';
import 'package:tabs/screens/expenses/add_expense_screen.dart';
import 'package:tabs/screens/expenses/expense_detail_screen.dart';
import 'package:tabs/screens/settlements/settle_up_screen.dart';
import 'package:tabs/screens/activity/activity_screen.dart';

class AppRoutes {
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const home = '/';
  static const createGroup = '/groups/create';
  static const groupDetail = '/groups/:groupId';
  static const addExpense = '/groups/:groupId/expenses/add';
  static const editExpense = '/groups/:groupId/expenses/:expenseId/edit';
  static const expenseDetail = '/groups/:groupId/expenses/:expenseId';
  static const settleUp = '/groups/:groupId/settle';
  static const activity = '/groups/:groupId/activity';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == AppRoutes.signIn ||
          state.matchedLocation == AppRoutes.signUp;

      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.signIn;
      }
      if (isLoggedIn && isAuthRoute) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.createGroup,
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: AppRoutes.groupDetail,
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return GroupDetailScreen(groupId: groupId);
        },
        routes: [
          GoRoute(
            path: 'expenses/add',
            builder: (context, state) {
              final groupId = state.pathParameters['groupId']!;
              return AddExpenseScreen(groupId: groupId);
            },
          ),
          GoRoute(
            path: 'expenses/:expenseId',
            builder: (context, state) {
              final groupId = state.pathParameters['groupId']!;
              final expenseId = state.pathParameters['expenseId']!;
              return ExpenseDetailScreen(
                groupId: groupId,
                expenseId: expenseId,
              );
            },
          ),
          GoRoute(
            path: 'settle',
            builder: (context, state) {
              final groupId = state.pathParameters['groupId']!;
              return SettleUpScreen(groupId: groupId);
            },
          ),
          GoRoute(
            path: 'activity',
            builder: (context, state) {
              final groupId = state.pathParameters['groupId']!;
              return ActivityScreen(groupId: groupId);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
