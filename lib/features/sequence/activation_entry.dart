import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../../providers/app_providers.dart';
import '../expectation/pull_flow.dart';

/// External entry points (tile, widget, deep link, side-key launch into
/// activate) land here and follow the default-pull setting.
class ActivationEntry extends ConsumerWidget {
  const ActivationEntry({super.key, required this.source});

  final ActivationSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(appBootstrapProvider);
    return bootstrap.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (_) {
        final settings = ref.watch(settingsProvider);
        return PullFlow(
          source: source,
          kind: settings.drillIsDefaultPull ? PullKind.drill : PullKind.prompt,
        );
      },
    );
  }
}
