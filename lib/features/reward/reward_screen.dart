import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';

class RewardScreen extends ConsumerStatefulWidget {
  const RewardScreen({super.key});

  @override
  ConsumerState<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends ConsumerState<RewardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _auto;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    HapticFeedback.heavyImpact();
    _auto = Timer(const Duration(seconds: 3), () {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reward = ref.watch(lastRewardProvider);
    final theme = Theme.of(context);

    if (reward == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.elasticOut,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 96,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Well done',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '+${reward.pointsAwarded} points',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (reward.hadBonus) ...[
                const SizedBox(height: 8),
                Chip(
                  avatar: const Icon(Icons.casino, size: 18),
                  label: Text('Bonus +${reward.bonusPoints}!'),
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                ),
              ],
              if (reward.justUnlockedBonus) ...[
                const SizedBox(height: 12),
                Chip(
                  avatar: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Bonus prompts unlocked for 24h!'),
                  backgroundColor: theme.colorScheme.secondaryContainer,
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Streak: ${reward.newStreak}',
                style: theme.textTheme.titleLarge,
              ),
              if (reward.newStreak >= reward.bestStreak &&
                  reward.newStreak > 1) ...[
                const SizedBox(height: 6),
                Text(
                  'Personal best!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                height: 80,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _SparkPainter(
                        progress: _controller.value,
                        color: theme.colorScheme.primary,
                      ),
                      size: const Size(double.infinity, 80),
                    );
                  },
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7 * (1 - progress * 0.5))
      ..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final count = 12;
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2;
      final dist = 12 + progress * 36;
      final p = Offset(
        center.dx + math.cos(angle) * dist,
        center.dy + math.sin(angle) * dist,
      );
      canvas.drawCircle(p, 3 + (1 - progress) * 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
