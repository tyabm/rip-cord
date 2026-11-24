import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../common/app_chrome.dart';
import '../expectation/pending_outcome_prompt.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          const Positioned(top: 0, left: 0, child: PendingOutcomePrompt()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt),
            label: 'Rip-Cord',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Log',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(appBootstrapProvider);

    return bootstrap.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Failed to load: $e'))),
      data: (_) {
        final settings = ref.watch(settingsProvider);
        final summary = ref.watch(summaryProvider);
        final theme = Theme.of(context);
        final drillDefault = settings.drillIsDefaultPull;
        final todayLine = summary.todayUses == 0
            ? 'A private record stays in Log.'
            : 'Today: ${summary.todayUses}. The record stays in Log.';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Rip-Cord'),
            actions: ripCordAppBarActions(context),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Interrupt the urge. Then put the phone down.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: drillDefault
                        ? 'Pull Rip-Cord. Start the urge drill.'
                        : 'Pull Rip-Cord. Start competing response sequence.',
                    child: FilledButton(
                      onPressed: () async {
                        await HapticFeedback.heavyImpact();
                        await Future<void>.delayed(
                          const Duration(milliseconds: 40),
                        );
                        await HapticFeedback.mediumImpact();
                        if (context.mounted) {
                          context.push('/activate?source=fab');
                        }
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(88),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, size: 36),
                          SizedBox(height: 4),
                          Text('Pull Rip-Cord'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      if (drillDefault) {
                        context.push('/prompt?source=fab');
                      } else {
                        context.push('/drill?source=fab');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(
                      drillDefault ? 'Use a prompt instead' : 'Urge drill',
                    ),
                  ),
                  if (!drillDefault) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Name the urge, one physical move, then leave. Under a minute.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const Spacer(),
                  Text(
                    todayLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Also available from Quick Settings and the home-screen widget.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
