import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rip_cord/data/app_repository.dart';
import 'package:rip_cord/domain/expectation.dart';
import 'package:rip_cord/domain/models.dart';
import 'package:rip_cord/domain/urge_drill.dart';
import 'package:rip_cord/features/done/done_screen.dart';
import 'package:rip_cord/features/drill/drill_screen.dart';
import 'package:rip_cord/features/expectation/pull_flow.dart';
import 'package:rip_cord/features/settings/settings_screen.dart';
import 'package:rip_cord/providers/app_providers.dart';
import 'package:rip_cord/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fontFamily = 'Inter';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppRepository repo;

  setUp(() async {
    await _loadFonts();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final dir = await Directory.systemTemp.createTemp('ripcord_shot');
    repo = AppRepository(prefs: prefs, documentsDirectory: dir);
    await repo.load();
    await repo.updateSettings(
      repo.settings.copyWith(
        handoffKind: HandoffKind.walkTimer,
        walkTimerMinutes: 10,
        trustedPersonName: 'Sam',
        trustedPersonPhone: '5550102030',
      ),
    );
  });

  testWidgets('settings hand-off section', (tester) async {
    await _pump(tester, const Size(400, 1180), const SettingsScreen(), repo);
    expect(find.text('After a pull'), findsOneWidget);
    final top = tester.getTopLeft(find.text('After a pull')).dy;
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    scrollable.position.jumpTo(scrollable.position.pixels + top - 4);
    await tester.pump();
    expect(find.text('Urge drill'), findsOneWidget);
    expect(find.text('Trusted person'), findsOneWidget);
    expect(find.text('Walk timer'), findsWidgets);
    await _save(tester, 'settings-after-pull');
  });

  testWidgets('urge drill naming step', (tester) async {
    await _pump(
      tester,
      const Size(400, 800),
      const DrillScreen(source: ActivationSource.fab),
      repo,
    );
    expect(find.text('Name the urge'), findsOneWidget);
    expect(find.text('Scroll'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    await _save(tester, 'urge-drill');
  });

  testWidgets('urge drill practice step', (tester) async {
    await _pump(
      tester,
      const Size(400, 800),
      const DrillScreen(source: ActivationSource.fab),
      repo,
    );
    await tester.tap(find.text('Scroll'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.tap(find.byType(RadioListTile<DrillAction>).first);
    await tester.pump();
    final start = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Start'),
    );
    expect(start.onPressed, isNotNull);
    await tester.runAsync(() async {
      start.onPressed!();
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pump();
    expect(find.text('seconds'), findsOneWidget);
    expect(find.text('Text Sam'), findsOneWidget);
    await _save(tester, 'urge-drill-practice');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('post-pull acknowledgement', (tester) async {
    await _pump(tester, const Size(400, 800), const DoneScreen(), repo);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Text Sam'), findsOneWidget);
    expect(find.textContaining('walk timer'), findsOneWidget);
    expect(find.text('Leave now'), findsOneWidget);
    await _save(tester, 'post-pull');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('expectation prompt', (tester) async {
    await _pump(
      tester,
      const Size(400, 860),
      const PullFlow(source: ActivationSource.fab, kind: PullKind.prompt),
      repo,
    );
    await _settle(tester);
    expect(
      find.text('What were you hoping this would get you?'),
      findsOneWidget,
    );
    expect(find.text('Relief'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    await _save(tester, 'expectation-prompt');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('expectation mirror', (tester) async {
    await tester.runAsync(() async {
      for (final score in [2, 2, 2, 2, 2, 3]) {
        final check = await repo.recordExpectation(ExpectationKind.relief);
        await repo.rateExpectation(id: check.id, rating: score);
      }
    });
    await _pump(
      tester,
      const Size(400, 860),
      const PullFlow(source: ActivationSource.fab, kind: PullKind.prompt),
      repo,
    );
    await _settle(tester);
    final relief = tester.widget<ButtonStyleButton>(
      find
          .ancestor(
            of: find.text('Relief'),
            matching: find.byWidgetPredicate(
              (widget) => widget is ButtonStyleButton,
            ),
          )
          .first,
    );
    await tester.runAsync(() async {
      relief.onPressed?.call();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    expect(find.textContaining('you rated it'), findsOneWidget);
    await _save(tester, 'expectation-mirror');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('outcome rating at the next pull', (tester) async {
    await tester.runAsync(() => repo.recordExpectation(ExpectationKind.relief));
    await _pump(
      tester,
      const Size(400, 860),
      const PullFlow(source: ActivationSource.fab, kind: PullKind.prompt),
      repo,
    );
    await _settle(tester);
    expect(
      find.textContaining('Last time you expected relief'),
      findsOneWidget,
    );
    expect(find.text('Skip'), findsOneWidget);
    await _save(tester, 'outcome-rating');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('closing screen rating', (tester) async {
    await tester.runAsync(() => repo.recordExpectation(ExpectationKind.relief));
    await _pump(tester, const Size(400, 900), const DoneScreen(), repo);
    await _settle(tester);
    expect(find.text('Done'), findsOneWidget);
    expect(find.textContaining('did it deliver'), findsOneWidget);
    await _save(tester, 'post-pull-rating');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('settings expectation section', (tester) async {
    await _pump(tester, const Size(400, 900), const SettingsScreen(), repo);
    final vertical = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    await tester.scrollUntilVisible(
      find.text('Remind me about 2 hours later'),
      220,
      scrollable: vertical,
    );
    expect(find.text('Ask what you were hoping for'), findsOneWidget);
    expect(find.text('Remind me about 2 hours later'), findsOneWidget);
    await _save(tester, 'settings-expectation');
  });
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}

Future<void> _loadFonts() async {
  const faces = [
    '/usr/share/fonts/truetype/macos/Inter-Regular.ttf',
    '/usr/share/fonts/truetype/macos/Inter-Medium.ttf',
    '/usr/share/fonts/truetype/macos/Inter-SemiBold.ttf',
    '/usr/share/fonts/truetype/macos/Inter-Bold.ttf',
  ];
  final iconCandidates = [
    File(
      '${Platform.environment['HOME']}/sdk/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ),
    File(
      '/tmp/flutter-sdk/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ),
  ];
  final icons = iconCandidates.where((file) => file.existsSync()).firstOrNull;
  if (!File(faces.first).existsSync()) return;

  final text = FontLoader(_fontFamily);
  for (final path in faces) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final bytes = file.readAsBytesSync();
    text.addFont(Future.value(ByteData.sublistView(Uint8List.fromList(bytes))));
  }
  await text.load();

  if (icons == null) return;
  final iconBytes = icons.readAsBytesSync();
  final iconLoader = FontLoader(
    'MaterialIcons',
  )..addFont(Future.value(ByteData.sublistView(Uint8List.fromList(iconBytes))));
  await iconLoader.load();
}

Future<void> _pump(
  WidgetTester tester,
  Size size,
  Widget home,
  AppRepository repo,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final base = AppTheme.light();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        appBootstrapProvider.overrideWith((ref) async => repo),
      ],
      child: RepaintBoundary(
        key: const Key('shot'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: base.colorScheme,
            useMaterial3: true,
            fontFamily: _fontFamily,
          ),
          home: home,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _save(WidgetTester tester, String name) async {
  final outDir = Directory('/opt/cursor/artifacts');
  if (!outDir.existsSync()) return;
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('shot')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${outDir.path}/$name.png');
    await file.writeAsBytes(
      bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
  });
}
