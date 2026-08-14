import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'domain/models.dart';
import 'providers/app_providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

const _activationChannel = MethodChannel('com.ripcord.rip_cord/activation');

class RipCordApp extends ConsumerStatefulWidget {
  const RipCordApp({super.key, this.initialUri});

  final Uri? initialUri;

  @override
  ConsumerState<RipCordApp> createState() => _RipCordAppState();
}

class _RipCordAppState extends ConsumerState<RipCordApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final initial = locationFromUri(widget.initialUri);
    _router = createRouter(initialLocation: initial);
    _activationChannel.setMethodCallHandler(_onNativeCall);
  }

  Future<void> _onNativeCall(MethodCall call) async {
    if (call.method == 'onNewLink') {
      final link = call.arguments as String?;
      final loc = locationFromUri(link != null ? Uri.tryParse(link) : null);
      if (loc != null) {
        _router.go(loc);
      }
    }
  }

  @override
  void dispose() {
    _activationChannel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(appBootstrapProvider);

    return bootstrap.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: Text('Startup error: $e'))),
      ),
      data: (_) {
        final settings = ref.watch(settingsProvider);
        final themeMode = settings.themeMode;
        final seed = Color(settings.customSeedColor);

        late final ThemeData lightTheme;
        late final ThemeData darkTheme;

        switch (themeMode) {
          case AppThemeMode.highContrast:
            lightTheme = AppTheme.highContrast(Brightness.light);
            darkTheme = AppTheme.highContrast(Brightness.dark);
          case AppThemeMode.moreColors:
            lightTheme = AppTheme.moreColorsLight(seed);
            darkTheme = AppTheme.moreColorsDark(seed);
          case AppThemeMode.light:
            lightTheme = AppTheme.moreColorsLight(seed);
            darkTheme = AppTheme.dark();
          case AppThemeMode.dark:
            lightTheme = AppTheme.light();
            darkTheme = AppTheme.moreColorsDark(seed);
          case AppThemeMode.system:
            lightTheme = AppTheme.light();
            darkTheme = AppTheme.dark();
        }

        return MaterialApp.router(
          title: 'Rip-Cord',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: AppTheme.materialThemeMode(themeMode),
          routerConfig: _router,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: mq.textScaler.clamp(
                  minScaleFactor: 0.9,
                  maxScaleFactor: 1.6,
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
