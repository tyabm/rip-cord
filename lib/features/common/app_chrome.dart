import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared app-bar actions: About (?) and Exit (X).
List<Widget> ripCordAppBarActions(BuildContext context) {
  return [
    IconButton(
      tooltip: 'About',
      onPressed: () => showAboutRipCordDialog(context),
      icon: const Icon(Icons.help_outline),
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
      ),
    ),
    IconButton(
      tooltip: 'Exit',
      onPressed: exitRipCordApp,
      icon: const Icon(Icons.close),
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
      ),
    ),
  ];
}

Future<void> showAboutRipCordDialog(BuildContext context) {
  final theme = Theme.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        icon: Icon(Icons.bolt, color: theme.colorScheme.primary, size: 36),
        title: const Text('About Rip-Cord'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Establish good habits and break out of negative thinking patterns.',
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                'Pull the ripcord.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'When an urge hits: interrupt, do one short competing response, '
                'then put the phone down. All data stays on this device.',
                style: TextStyle(height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                'If you save a trusted person\'s number, it stays on this device. '
                'Rip-Cord does not read your contacts or send messages for you.',
                style: TextStyle(height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

/// Leaves the app (returns to the Android launcher).
void exitRipCordApp() {
  SystemNavigator.pop();
}
