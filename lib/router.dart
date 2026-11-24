import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'domain/models.dart';
import 'features/done/done_screen.dart';
import 'features/expectation/pull_flow.dart';
import 'features/home/home_shell.dart';
import 'features/log/log_screen.dart';
import 'features/sequence/activation_entry.dart';
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
          return ActivationEntry(source: _sourceFrom(state));
        },
      ),
      GoRoute(
        path: '/prompt',
        name: 'prompt',
        builder: (context, state) {
          return PullFlow(source: _sourceFrom(state), kind: PullKind.prompt);
        },
      ),
      GoRoute(
        path: '/drill',
        name: 'drill',
        builder: (context, state) {
          return PullFlow(source: _sourceFrom(state), kind: PullKind.drill);
        },
      ),
      GoRoute(
        path: '/done',
        name: 'done',
        builder: (context, state) => const DoneScreen(),
      ),
    ],
  );
}

ActivationSource _sourceFrom(GoRouterState state) {
  final sourceName = state.uri.queryParameters['source'] ?? 'fab';
  return ActivationSource.values.asNameMap()[sourceName] ??
      ActivationSource.deepLink;
}

/// Parse Android deep link / intent into a router location.
String? locationFromUri(Uri? uri) {
  if (uri == null) return null;
  if (uri.scheme == 'ripcord' && uri.host == 'rate') {
    return '/';
  }
  if (uri.scheme == 'ripcord' &&
      (uri.host == 'activate' ||
          uri.path == '/activate' ||
          uri.pathSegments.contains('activate'))) {
    final source = uri.queryParameters['source'] ?? 'deepLink';
    return '/activate?source=$source';
  }
  if (uri.path == '/activate' || uri.pathSegments.contains('activate')) {
    final source = uri.queryParameters['source'] ?? 'deepLink';
    return '/activate?source=$source';
  }
  return null;
}
