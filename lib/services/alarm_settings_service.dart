
import 'package:shared_preferences/shared_preferences.dart';

class AlarmSettings {
  final int hour;
  final int minute;
  final bool enabled;
  final String lastTriggeredDate;

  const AlarmSettings({
    required this.hour,
    required this.minute,
    required this.enabled,
    required this.lastTriggeredDate,
  });
}

class AlarmSettingsService {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static const _hourKey = 'alarm_hour';
  static const _minuteKey = 'alarm_minute';
  static const _enabledKey = 'alarm_enabled';
  static const _lastDateKey = 'last_triggered_date';

  Future<AlarmSettings> load() async {
    final hour = await _prefs.getInt(_hourKey) ?? 8;
    final minute = await _prefs.getInt(_minuteKey) ?? 0;
    final enabled = await _prefs.getBool(_enabledKey) ?? false;
    final lastDate =
        await _prefs.getString(_lastDateKey) ?? '';

    return AlarmSettings(
      hour: hour.clamp(0, 23).toInt(),
      minute: minute.clamp(0, 59).toInt(),
      enabled: enabled,
      lastTriggeredDate: lastDate,
    );
  }

  Future<void> saveTime(int hour, int minute) async {
    await _prefs.setInt(_hourKey, hour);
    await _prefs.setInt(_minuteKey, minute);
    await _prefs.setString(_lastDateKey, '');
  }

  Future<void> saveEnabled(bool enabled) async {
    await _prefs.setBool(_enabledKey, enabled);
  }

  Future<void> saveLastTriggeredDate(String date) async {
    await _prefs.setString(_lastDateKey, date);
  }
}
