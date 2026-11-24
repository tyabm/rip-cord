import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rip_cord/data/app_repository.dart';
import 'package:rip_cord/domain/expectation.dart';
import 'package:rip_cord/domain/models.dart';
import 'package:rip_cord/features/done/done_screen.dart';
import 'package:rip_cord/features/expectation/outcome_rating.dart';
import 'package:rip_cord/features/expectation/pending_outcome_prompt.dart';
import 'package:rip_cord/features/expectation/pull_flow.dart';
import 'package:rip_cord/features/settings/settings_screen.dart';
import 'package:rip_cord/providers/app_providers.dart';
import 'package:rip_cord/router.dart';
import 'package:rip_cord/services/expectation_nudge.dart';
import 'package:rip_cord/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppRepository repo;

  setUp(() async {
    RatingAskLock.end();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final dir = await Directory.systemTemp.createTemp('ripcord_flow');
    repo = AppRepository(prefs: prefs, documentsDirectory: dir);
    await repo.load();
  });

  tearDown(() {
    RatingAskLock.end();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(expectationNudgeChannelName),
          null,
        );
  });

  testWidgets('turning the check off keeps the existing pull path', (
    tester,
  ) async {
    await _io(tester, () {
      return repo.updateSettings(
        repo.settings.copyWith(expectationCheckEnabled: false),
      );
    });
    await _pump(
      tester,
      repo,
      const PullFlow(source: ActivationSource.fab, kind: PullKind.drill),
    );
    await _settle(tester);
    expect(find.text('Name the urge'), findsOneWidget);
    expect(find.text(expectationPromptQuestion), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a pull asks the expectation question and can skip it', (
    tester,
  ) async {
    await _pump(
      tester,
      repo,
      const PullFlow(source: ActivationSource.fab, kind: PullKind.drill),
    );
    await _settle(tester);
    expect(find.text(expectationPromptQuestion), findsOneWidget);
    expect(find.text('Relief'), findsOneWidget);
    expect(find.text('Habit, no reason'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await _settle(tester);
    expect(find.text('Name the urge'), findsOneWidget);
    expect(repo.expectationChecks, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('three ratings show the mirror before practice', (tester) async {
    await _io(tester, () async {
      for (final score in [2, 2, 3]) {
        final check = await repo.recordExpectation(ExpectationKind.relief);
        await repo.rateExpectation(id: check.id, rating: score);
      }
    });

    await _pump(
      tester,
      repo,
      const PullFlow(source: ActivationSource.tile, kind: PullKind.drill),
    );
    await _settle(tester);
    await _press(tester, 'Relief');

    expect(
      find.text(
        'The last 3 times you expected relief, you rated it 2.3 out of 5.',
      ),
      findsOneWidget,
    );
    expect(find.text('Continue'), findsOneWidget);
    expect(
      repo.expectationChecks.where((check) => check.rating == null),
      hasLength(1),
    );

    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Name the urge'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the next pull asks once about the previous hope', (
    tester,
  ) async {
    await _io(tester, () => repo.recordExpectation(ExpectationKind.escapeBoredom));

    await _pump(
      tester,
      repo,
      const PullFlow(source: ActivationSource.widget, kind: PullKind.drill),
    );
    await _settle(tester);
    expect(
      find.text(outcomeRatingQuestion(ExpectationKind.escapeBoredom)),
      findsOneWidget,
    );

    await _press(tester, '3');
    expect(find.text(expectationPromptQuestion), findsOneWidget);
    final rated = repo.expectationChecks.single;
    expect(rated.rating, 3);
    expect(rated.ratingAsked, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pump(
      tester,
      repo,
      const PullFlow(source: ActivationSource.widget, kind: PullKind.drill),
    );
    await _settle(tester);
    expect(
      find.text(outcomeRatingQuestion(ExpectationKind.escapeBoredom)),
      findsNothing,
    );
    expect(find.text(expectationPromptQuestion), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('opt-in reminder schedules one local notification per pull', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(expectationNudgeChannelName),
          (call) async {
            calls.add(call);
            return true;
          },
        );
    await _io(tester, () {
      return repo.updateSettings(
        repo.settings.copyWith(expectationNudgeEnabled: true),
      );
    });

    await _pump(
      tester,
      repo,
      const PullFlow(source: ActivationSource.fab, kind: PullKind.drill),
    );
    await _settle(tester);
    final before = DateTime.now();
    await _press(tester, 'Checking something');
    final after = DateTime.now();

    expect(calls.where((call) => call.method == 'schedule'), hasLength(1));
    final args =
        calls.singleWhere((call) => call.method == 'schedule').arguments
            as Map<dynamic, dynamic>;
    expect(args['title'], 'See if it was worth it');
    expect(args['body'], contains('to check something'));
    final trigger = DateTime.fromMillisecondsSinceEpoch(
      (args['triggerAtMillis'] as num).toInt(),
    );
    expect(
      trigger.isAfter(
        before.add(expectationNudgeDelay - const Duration(seconds: 5)),
      ),
      isTrue,
    );
    expect(
      trigger.isBefore(
        after.add(expectationNudgeDelay + const Duration(seconds: 5)),
      ),
      isTrue,
    );
    expect(repo.expectationChecks.single.nudgeScheduled, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reminder stays off unless the phone allows notifications', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(expectationNudgeChannelName),
          (call) async => call.method == 'requestPermission' ? false : true,
        );
    await _pump(tester, repo, const SettingsScreen());
    await tester.scrollUntilVisible(
      find.text('Remind me about 2 hours later'),
      400,
      scrollable: _verticalScrollable,
    );
    final reminder = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Remind me about 2 hours later'),
    );
    await tester.runAsync(() async {
      reminder.onChanged?.call(true);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();

    expect(repo.settings.expectationNudgeEnabled, isFalse);
    expect(find.textContaining('Notifications are off'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('opening the app asks once, and clear removes the history', (
    tester,
  ) async {
    await _io(tester, () => repo.recordExpectation(ExpectationKind.relief));
    await _pump(tester, repo, const PendingOutcomePrompt());
    await _settle(tester);
    expect(
      find.text(outcomeRatingQuestion(ExpectationKind.relief)),
      findsOneWidget,
    );

    await tester.tap(find.text('Skip'));
    await _settle(tester);
    expect(
      find.text(outcomeRatingQuestion(ExpectationKind.relief)),
      findsNothing,
    );
    expect(repo.expectationChecks.single.rating, isNull);
    expect(repo.expectationChecks.single.ratingAsked, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pump(tester, repo, const PendingOutcomePrompt());
    await _settle(tester);
    expect(
      find.text(outcomeRatingQuestion(ExpectationKind.relief)),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await _pump(tester, repo, const SettingsScreen());
    await tester.scrollUntilVisible(
      find.text('Clear expectation history'),
      400,
      scrollable: _verticalScrollable,
    );
    await tester.tap(find.text('Clear expectation history'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final clear = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Clear'),
    );
    await tester.runAsync(() async {
      clear.onPressed?.call();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    expect(repo.expectationChecks, isEmpty);
    expect(repo.events, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('closing screen can record one rating without blocking leave', (
    tester,
  ) async {
    await _io(tester, () => repo.recordExpectation(ExpectationKind.habit));
    await _pump(tester, repo, const DoneScreen());
    await _settle(tester);
    expect(find.text('Done'), findsOneWidget);
    expect(
      find.text(outcomeRatingQuestion(ExpectationKind.habit)),
      findsOneWidget,
    );
    expect(find.text('Leave now'), findsOneWidget);

    await _press(tester, '5');
    expect(repo.expectationChecks.single.rating, 5);
    expect(find.text('Saved on this phone.'), findsOneWidget);
    expect(find.text('Leave now'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('home still opens when the expectation prompt is mounted', (
    tester,
  ) async {
    final router = createRouter();
    addTearDown(router.dispose);
    final theme = AppTheme.light();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          appBootstrapProvider.overrideWith((ref) async => repo),
        ],
        child: MaterialApp.router(theme: theme, routerConfig: router),
      ),
    );
    await _settle(tester);
    expect(find.text('Pull Rip-Cord'), findsOneWidget);
    expect(tester.getSize(find.text('Pull Rip-Cord')).height, greaterThan(0));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _pump(WidgetTester tester, AppRepository repo, Widget home) async {
  final theme = AppTheme.light();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        appBootstrapProvider.overrideWith((ref) async => repo),
      ],
      child: MaterialApp(theme: theme, home: home),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}

/// Disk and preferences writes complete outside the widget test's fake clock.
Future<void> _io(WidgetTester tester, Future<void> Function() body) async {
  await tester.runAsync(body);
}

/// Runs a button callback that writes to disk, outside the fake async zone.
final _verticalScrollable = find.byWidgetPredicate(
  (widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down,
);

Future<void> _press(WidgetTester tester, String label) async {
  final button = tester.widget<ButtonStyleButton>(
    find
        .ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate(
            (widget) => widget is ButtonStyleButton,
          ),
        )
        .first,
  );
  await tester.runAsync(() async {
    button.onPressed?.call();
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  await tester.pump();
}
