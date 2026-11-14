import 'package:flutter_test/flutter_test.dart';
import 'package:rip_cord/domain/handoff.dart';
import 'package:rip_cord/domain/models.dart';

void main() {
  test('sms composer uri has no body', () {
    final uri = smsComposerUri('+1 (555) 010-2030?body=hello')!;
    expect(uri.scheme, 'sms');
    expect(uri.query, isEmpty);
    expect(uri.toString().contains('body'), isFalse);
    expect(uri.toString().contains('?'), isFalse);
    expect(uri.path, '+15550102030');
  });

  test('call hand-off uses the dialer, not an immediate call', () {
    final uri = dialerUri('555-010-2030')!;
    expect(uri.scheme, 'tel');
    expect(uri.path, '5550102030');
  });

  test('short or empty numbers are not launchable', () {
    expect(smsComposerUri('12'), isNull);
    expect(smsComposerUri(''), isNull);
    expect(smsComposerUri(null), isNull);
    expect(dialerUri('abc'), isNull);
  });

  test('music uri rejects empty and dangerous schemes', () {
    expect(musicLaunchUri(null), isNull);
    expect(musicLaunchUri('   '), isNull);
    expect(musicLaunchUri('not a uri'), isNull);
    expect(musicLaunchUri('javascript:alert(1)'), isNull);
    expect(musicLaunchUri('file:///sdcard/secret'), isNull);
    expect(
      musicLaunchUri('https://open.spotify.com/playlist/abc')?.scheme,
      'https',
    );
    expect(musicLaunchUri('spotify:playlist:abc')?.scheme, 'spotify');
  });

  test('walk timer is handed to Clock with the UI shown', () {
    final settings = AppSettings(
      handoffKind: HandoffKind.walkTimer,
      walkTimerMinutes: 10,
    );
    final launch = walkTimerLaunchFor(settings)!;
    expect(launch.action, 'android.intent.action.SET_TIMER');
    expect(launch.lengthSeconds, 600);
    expect(launch.message, 'Walk');
    expect(launch.skipUi, isFalse);
    expect(handoffIsReady(settings), isTrue);
  });

  test('call hand-off waits for a stored number', () {
    final missing = AppSettings(handoffKind: HandoffKind.call);
    expect(handoffIsReady(missing), isFalse);
    expect(leaveAcknowledgement(missing), 'You can put the phone down.');

    final ready = missing.copyWith(
      trustedPersonName: 'Sam',
      trustedPersonPhone: '5550102030',
    );
    expect(handoffIsReady(ready), isTrue);
    expect(trustedCheckInLabel(ready), 'Text Sam');
    expect(
      leaveAcknowledgement(ready),
      'Opening the dialer for Sam, then leaving.',
    );
  });

  test('none means the acknowledgement just closes', () {
    final settings = AppSettings();
    expect(handoffIsReady(settings), isFalse);
    expect(leaveAcknowledgement(settings), 'You can put the phone down.');
    expect(trustedCheckInLabel(settings), isNull);
  });
}
