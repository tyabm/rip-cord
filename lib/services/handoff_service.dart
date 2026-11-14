import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/handoff.dart';
import '../domain/models.dart';

/// Launches the pre-chosen replacement action, if it is ready.
/// Walk timers go to the system Clock app. Music and calls use an external
/// app. Nothing here sends an SMS or places a call by itself.
Future<void> launchConfiguredHandoff(AppSettings settings) async {
  switch (settings.handoffKind) {
    case HandoffKind.none:
      return;
    case HandoffKind.walkTimer:
      final spec = walkTimerLaunchFor(settings);
      if (spec == null) return;
      final intent = AndroidIntent(
        action: spec.action,
        arguments: <String, dynamic>{
          WalkTimerLaunch.lengthExtra: spec.lengthSeconds,
          WalkTimerLaunch.messageExtra: spec.message,
          WalkTimerLaunch.skipUiExtra: spec.skipUi,
        },
      );
      await intent.launch();
    case HandoffKind.music:
      final uri = musicLaunchUri(settings.musicUri);
      if (uri == null) return;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    case HandoffKind.call:
      final uri = dialerUri(settings.trustedPersonPhone);
      if (uri == null) return;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Opens the SMS composer for [phone] with no message body.
Future<bool> openSmsComposer(String? phone) async {
  final uri = smsComposerUri(phone);
  if (uri == null) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
