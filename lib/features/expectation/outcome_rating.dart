import 'package:flutter/material.dart';

import '../../domain/expectation.dart';

/// Stops the home prompt and the next pull from asking at the same time.
class RatingAskLock {
  static bool _held = false;

  static bool tryBegin() {
    if (_held) return false;
    _held = true;
    return true;
  }

  static void end() => _held = false;
}

class OutcomeRatingRow extends StatelessWidget {
  const OutcomeRatingRow({super.key, required this.onSelected, this.selected});

  final ValueChanged<int>? onSelected;
  final int? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (var score = 1; score <= 5; score++) ...[
          if (score > 1) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              button: true,
              selected: selected == score,
              label: '$score out of 5',
              child: OutlinedButton(
                onPressed: onSelected == null ? null : () => onSelected!(score),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  padding: EdgeInsets.zero,
                  backgroundColor: selected == score
                      ? theme.colorScheme.secondaryContainer
                      : null,
                ),
                child: Text('$score'),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

Future<int?> showOutcomeRatingDialog(
  BuildContext context,
  ExpectationCheck check,
) {
  return showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        title: const Text(expectationFraming),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                outcomeRatingQuestion(check.expectation),
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 16),
              OutcomeRatingRow(
                onSelected: (value) => Navigator.pop(ctx, value),
              ),
              const SizedBox(height: 8),
              Text(
                expectationScaleCaption,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Skip'),
          ),
        ],
      );
    },
  );
}
