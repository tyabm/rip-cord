import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/handoff.dart';
import '../../providers/app_providers.dart';
import '../../services/handoff_service.dart';

/// One tap opens the SMS composer for the stored person, with an empty body.
class TrustedCheckInButton extends ConsumerWidget {
  const TrustedCheckInButton({super.key, this.onOpened});

  /// Called before the composer opens, so a pending auto-exit can stand down.
  final VoidCallback? onOpened;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final label = trustedCheckInLabel(settings);
    if (label == null) return const SizedBox.shrink();

    return TextButton.icon(
      onPressed: () async {
        onOpened?.call();
        final opened = await openSmsComposer(settings.trustedPersonPhone);
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open the message app.'),
            ),
          );
        }
      },
      icon: const Icon(Icons.sms_outlined),
      label: Text(label),
    );
  }
}
