import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'manifest can see hand-off targets and adds no dangerous permissions',
    () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(manifest, contains('android.intent.action.SET_TIMER'));
      expect(manifest, contains('android.intent.action.DIAL'));
      expect(manifest, contains('android.intent.action.SENDTO'));
      expect(manifest, contains('android:scheme="sms"'));
      expect(manifest, contains('android:scheme="smsto"'));
      expect(manifest, contains('android:scheme="tel"'));
      expect(manifest, contains('android:scheme="https"'));

      expect(manifest.contains('android.permission.SEND_SMS'), isFalse);
      expect(manifest.contains('android.permission.READ_CONTACTS'), isFalse);
      expect(manifest.contains('android.permission.CALL_PHONE'), isFalse);
      expect(manifest.contains('android.permission.READ_SMS'), isFalse);
      expect(
        manifest.contains('android.permission.SCHEDULE_EXACT_ALARM'),
        isFalse,
      );
      expect(manifest.contains('android.permission.USE_EXACT_ALARM'), isFalse);
      expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
      expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
      expect(manifest, contains('ExpectationNudgeReceiver'));
      expect(manifest, contains('ExpectationNudgeBootReceiver'));
    },
  );
}
