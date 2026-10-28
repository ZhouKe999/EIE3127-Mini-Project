
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AlarmKitService {
  static const MethodChannel _channel =
      MethodChannel('com.smartwake/alarmkit');

  bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<bool> requestPermission() async {
    if (!isSupportedPlatform) return false;

    final authorized =
        await _channel.invokeMethod<bool>('requestPermission');

    return authorized ?? false;
  }

  Future<String> scheduleTestAlarm({
    int seconds = 60,
  }) async {
    if (!isSupportedPlatform) {
      throw UnsupportedError(
        'AlarmKit requires a real iOS device.',
      );
    }

    final id = await _channel.invokeMethod<String>(
      'scheduleTestAlarm',
      {'seconds': seconds},
    );

    if (id == null) {
      throw StateError('AlarmKit returned no alarm ID.');
    }

    return id;
  }

  Future<void> cancelAlarm(String alarmId) async {
    if (!isSupportedPlatform) {
      throw UnsupportedError('iOS only');
    }

    await _channel.invokeMethod<void>(
      'cancelAlarm',
      {'id': alarmId},
    );
  }
}
