import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/handoff.dart';
import '../../providers/app_providers.dart';
import '../../services/handoff_service.dart';
import '../common/app_chrome.dart';
import '../common/check_in_button.dart';

/// How long the calm acknowledgement stays before Rip-Cord leaves.
const Duration doneLeaveDelay = Duration(seconds: 4);

/// Brief close of a pull. Not a celebration, and it does not return Home.
class DoneScreen extends ConsumerStatefulWidget {
  const DoneScreen({super.key});

  @override
  ConsumerState<DoneScreen> createState() => _DoneScreenState();
}

class _DoneScreenState extends ConsumerState<DoneScreen> {
  Timer? _leaveTimer;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _leaveTimer = Timer(doneLeaveDelay, _leave);
  }

  @override
  void dispose() {
    _leaveTimer?.cancel();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_left) return;
    _left = true;
    _leaveTimer?.cancel();
    final settings = ref.read(settingsProvider);
    try {
      if (handoffIsReady(settings)) {
        await launchConfiguredHandoff(settings);
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    } catch (_) {
      // Still leave if Clock, music, or the dialer cannot open.
    }
    exitRipCordApp();
  }

  void _pauseForCheckIn() {
    _leaveTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rip-Cord'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Exit',
            onPressed: _leave,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.check_rounded,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Done',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                leaveAcknowledgement(settings),
                style: theme.textTheme.titleMedium?.copyWith(
                  height: 1.4,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              TrustedCheckInButton(onOpened: _pauseForCheckIn),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _leave,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text('Leave now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
