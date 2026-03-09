import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/recover_code_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/charts/presentation/screens/charts_screen.dart';
import '../../features/groups/presentation/screens/group_members_screen.dart';
import '../../features/groups/presentation/screens/manage_groups_screen.dart';
import '../../features/profile/presentation/screens/friend_screen.dart';
import '../../features/profile/presentation/screens/me_placeholder_screen.dart';
import '../../features/records/presentation/screens/records_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/transactions/domain/transaction.dart';
import '../../features/transactions/presentation/screens/add_transaction_screen.dart';
import '../../features/transactions/presentation/screens/edit_transaction_screen.dart';
import '../../shell/main_shell_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final location = state.uri.path;
      if (isLoggedIn && (location == '/login' || location == '/register')) {
        return '/';
      }
      if (!isLoggedIn &&
          location != '/login' &&
          location != '/register' &&
          location != '/forgot-password' &&
          location != '/recover-code' &&
          location != '/reset-password') {
        return '/login';
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: RecordsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/charts',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ChartsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/add',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AddTransactionScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ReportsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: MePlaceholderScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'manage-groups',
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: HeroMode(
                        enabled: false,
                        child: ManageGroupsScreen(),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'group-members',
                    pageBuilder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      final groupId = extra?['groupId'] as String? ?? '';
                      final groupName = extra?['groupName'] as String? ?? '';
                      final isPersonal = extra?['isPersonal'] as bool? ?? true;
                      return NoTransitionPage(
                        key: ValueKey('group-members-$groupId'),
                        child: HeroMode(
                          enabled: false,
                          child: GroupMembersScreen(
                            groupId: groupId,
                            groupName: groupName,
                            isPersonal: isPersonal,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/recover-code',
        builder: (context, state) {
          final email = state.extra as String?;
          if (email == null || email.isEmpty) {
            return const ForgotPasswordScreen();
          }
          return RecoverCodeScreen(email: email);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return ResetPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const HeroMode(
          enabled: false,
          child: NotificationsScreen(),
        ),
      ),
      GoRoute(
        path: '/friend',
        builder: (context, state) => const HeroMode(
          enabled: false,
          child: FriendScreen(),
        ),
      ),
      GoRoute(
        path: '/edit-transaction',
        builder: (context, state) {
          final tx = state.extra as Transaction?;
          if (tx == null) {
            return const Scaffold(
              body: Center(child: Text('Thiếu thông tin giao dịch')),
            );
          }
          return EditTransactionScreen(transaction: tx);
        },
      ),
    ],
  );
});
