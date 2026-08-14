import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'domain/models.dart';
import 'features/home/home_shell.dart';
import 'features/log/log_screen.dart';
import 'features/reward/reward_screen.dart';
import 'features/sequence/sequence_screen.dart';
import 'features/settings/settings_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter createRouter({String? initialLocation}) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: initialLocation ?? '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomeTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/log',
                name: 'log',
                builder: (context, state) => const LogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/activate',
        name: 'activate',
        builder: (context, state) {
          final sourceName = state.uri.queryParameters['source'] ?? 'fab';
          final source = ActivationSource.values.firstWhere(
            (s) => s.name == sourceName,
            orElse: () => ActivationSource.deepLink,
          );
          return SequenceScreen(source: source);
        },
      ),
      GoRoute(
        path: '/reward',
        name: 'reward',
        builder: (context, state) => const RewardScreen(),
      ),
    ],
  );
}

/// Parse Android deep link / intent into a router location.
String? locationFromUri(Uri? uri) {
  if (uri == null) return null;
  if (uri.scheme == 'ripcord' &&
      (uri.host == 'activate' || uri.path == '/activate' || uri.pathSegments.contains('activate'))) {
    final source = uri.queryParameters['source'] ?? 'deepLink';
    return '/activate?source=$source';
  }
  if (uri.path == '/activate' || uri.pathSegments.contains('activate')) {
    final source = uri.queryParameters['source'] ?? 'deepLink';
    return '/activate?source=$source';
  }
  return null;
}
