import 'models.dart';

/// Clock-app timer request. [skipUi] stays false so the system Clock app
/// shows the timer instead of Rip-Cord running its own countdown.
class WalkTimerLaunch {
  const WalkTimerLaunch({
    required this.action,
    required this.lengthSeconds,
    required this.message,
    required this.skipUi,
  });

  final String action;
  final int lengthSeconds;
  final String message;
  final bool skipUi;

  static const lengthExtra = 'android.intent.extra.alarm.LENGTH';
  static const messageExtra = 'android.intent.extra.alarm.MESSAGE';
  static const skipUiExtra = 'android.intent.extra.alarm.SKIP_UI';
}

const _blockedMusicSchemes = {'javascript', 'data', 'file', 'intent'};

/// Digits with an optional leading +. Empty and too-short values are rejected.
String? normalizePhone(String? raw) {
  if (raw == null) return null;
  final buf = StringBuffer();
  for (final code in raw.runes) {
    final char = String.fromCharCode(code);
    if (char == '+' && buf.isEmpty) {
      buf.write(char);
    } else if (char.codeUnitAt(0) >= 0x30 && char.codeUnitAt(0) <= 0x39) {
      buf.write(char);
    }
  }
  final normalized = buf.toString();
  final digits =
      normalized.startsWith('+') ? normalized.substring(1) : normalized;
  if (digits.length < 3) return null;
  return normalized;
}

/// `sms:` URI with no query, so the composer opens with an empty body.
Uri? smsComposerUri(String? phone) {
  final normalized = normalizePhone(phone);
  if (normalized == null) return null;
  return Uri.parse('sms:$normalized');
}

/// Opens the dialer. Does not place the call.
Uri? dialerUri(String? phone) {
  final normalized = normalizePhone(phone);
  if (normalized == null) return null;
  return Uri.parse('tel:$normalized');
}

Uri? musicLaunchUri(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) return null;
  if (_blockedMusicSchemes.contains(uri.scheme.toLowerCase())) return null;
  return uri;
}

WalkTimerLaunch? walkTimerLaunchFor(AppSettings settings) {
  if (settings.handoffKind != HandoffKind.walkTimer) return null;
  final minutes = settings.walkTimerMinutes.clamp(1, 180);
  return WalkTimerLaunch(
    action: 'android.intent.action.SET_TIMER',
    lengthSeconds: minutes * 60,
    message: 'Walk',
    skipUi: false,
  );
}

/// True when the selected hand-off has enough detail to launch.
bool handoffIsReady(AppSettings settings) {
  switch (settings.handoffKind) {
    case HandoffKind.none:
      return false;
    case HandoffKind.walkTimer:
      return walkTimerLaunchFor(settings) != null;
    case HandoffKind.music:
      return musicLaunchUri(settings.musicUri) != null;
    case HandoffKind.call:
      return dialerUri(settings.trustedPersonPhone) != null;
  }
}

String leaveAcknowledgement(AppSettings settings) {
  switch (settings.handoffKind) {
    case HandoffKind.none:
      return 'You can put the phone down.';
    case HandoffKind.walkTimer:
      final minutes = settings.walkTimerMinutes;
      return 'Opening a $minutes-minute walk timer in Clock, then leaving.';
    case HandoffKind.music:
      if (musicLaunchUri(settings.musicUri) == null) {
        return 'You can put the phone down.';
      }
      return 'Opening your music, then leaving.';
    case HandoffKind.call:
      if (dialerUri(settings.trustedPersonPhone) == null) {
        return 'You can put the phone down.';
      }
      final name = settings.trustedPersonName?.trim();
      if (name != null && name.isNotEmpty) {
        return 'Opening the dialer for $name, then leaving.';
      }
      return 'Opening the dialer, then leaving.';
  }
}

/// Label for the one-tap SMS button, or null when no number is stored.
String? trustedCheckInLabel(AppSettings settings) {
  if (smsComposerUri(settings.trustedPersonPhone) == null) return null;
  final name = settings.trustedPersonName?.trim();
  if (name == null || name.isEmpty) return 'Text trusted person';
  return 'Text $name';
}
