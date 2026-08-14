import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'router.dart';

const _channel = MethodChannel('com.ripcord.rip_cord/activation');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Uri? launchUri;
  try {
    final initial = await _channel.invokeMethod<String>('getInitialLink');
    if (initial != null && initial.isNotEmpty) {
      launchUri = Uri.tryParse(initial);
    }
  } catch (_) {
    // Channel optional when running without custom MainActivity methods.
  }

  // Also honor Flutter's default route / deep link if provided.
  final defaultRoute = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  if (launchUri == null &&
      defaultRoute.isNotEmpty &&
      defaultRoute != '/') {
    launchUri = Uri.tryParse(
      defaultRoute.startsWith('/')
          ? 'ripcord:/$defaultRoute'
          : defaultRoute,
    );
  }

  runApp(
    ProviderScope(
      child: RipCordApp(initialUri: launchUri),
    ),
  );
}

/// Used by tests / hot-restart helpers.
String? debugLocationFromUri(Uri? uri) => locationFromUri(uri);
