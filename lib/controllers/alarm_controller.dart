
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/alarm_state.dart';
import '../services/bed_sensor_service.dart';

class AlarmController extends ChangeNotifier {
  AlarmController({
    required this.sensor,
    this.recheckDelay = const Duration(seconds: 30),
    this.leaveConfirmation = const Duration(seconds: 60),
  }) {
    sensor.addListener(_onSensorChanged);
  }

  final BedSensorService sensor;
  final Duration recheckDelay;
  final Duration leaveConfirmation;

  AlarmState state = AlarmState.idle;
  int ringCount = 0;

  Timer? _checkTimer;
  Timer? _leaveTimer;

  bool get isRinging => state == AlarmState.ringing;

  void triggerAlarm() {
    _cancelTimers();
    ringCount++;
    state = AlarmState.ringing;
    notifyListeners();
  }

  void stopAlarm() {
    if (state != AlarmState.ringing) return;

    state = AlarmState.monitoring;
    notifyListeners();

    _evaluateBed();
    _scheduleCheck();
  }

  void _scheduleCheck() {
    _checkTimer?.cancel();

    _checkTimer = Timer(recheckDelay, () {
      if (state != AlarmState.monitoring) return;

     
    switch (sensor.value) {
      case BedPresence.occupied:
        triggerAlarm();
        return;

      case BedPresence.empty:
        _evaluateBed();
        _scheduleCheck();
        return;

      case BedPresence.unknown:
        _leaveTimer?.cancel();
        _leaveTimer = null;
        _scheduleCheck();
        return;
    }

    });
  }

  void _onSensorChanged() {
    if (state == AlarmState.monitoring) {
      _evaluateBed();
    }
    notifyListeners();
  }

  void _evaluateBed() {
    if (sensor.value != BedPresence.empty) {
      _leaveTimer?.cancel();
      _leaveTimer = null;
      return;
    }

    if (_leaveTimer != null) return;

    _leaveTimer = Timer(leaveConfirmation, () {
      if (state == AlarmState.monitoring &&
          sensor.value == BedPresence.empty) {
        _cancelTimers();
        state = AlarmState.completed;
        notifyListeners();
      }
    });
  }

  void reset() {
    _cancelTimers();
    state = AlarmState.idle;
    ringCount = 0;
    notifyListeners();
  }

  void _cancelTimers() {
    _checkTimer?.cancel();
    _leaveTimer?.cancel();
    _checkTimer = null;
    _leaveTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
    sensor.removeListener(_onSensorChanged);
    super.dispose();
  }
}
