import 'package:flutter/services.dart';

import '../domain/expectation.dart';

const expectationNudgeChannelName = 'com.ripcord.rip_cord/nudge';

/// Schedules at most one local notification per pull. The platform side
/// does not repeat it. Failures stay quiet so a pull can still finish.
class ExpectationNudgeService {
  ExpectationNudgeService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(expectationNudgeChannelName);

  final MethodChannel _channel;

  Future<bool> requestPermission() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestPermission');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> schedule({
    required String checkId,
    required String title,
    required String body,
    required DateTime triggerAt,
  }) async {
    try {
      final ok = await _channel.invokeMethod<bool>('schedule', {
        'checkId': checkId,
        'title': title,
        'body': body,
        'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
      });
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> cancel(String checkId) async {
    try {
      await _channel.invokeMethod<void>('cancel', {'checkId': checkId});
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    try {
      await _channel.invokeMethod<void>('cancelAll');
    } catch (_) {}
  }
}

final expectationNudge = ExpectationNudgeService();

Future<bool> scheduleExpectationNudge(ExpectationCheck check) async {
  final when = DateTime.now().add(expectationNudgeDelay);
  return expectationNudge.schedule(
    checkId: check.id,
    title: expectationNudgeTitle,
    body: expectationNudgeBody(check.expectation),
    triggerAt: when,
  );
}
