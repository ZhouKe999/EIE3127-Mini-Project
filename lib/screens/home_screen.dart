
import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/alarm_controller.dart';
import '../models/alarm_state.dart';
import '../services/mock_bed_sensor.dart';
import '../services/alarm_settings_service.dart';
import '../screens/alarmkit_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MockBedSensor sensor;
  late final AlarmController controller;

  final AlarmSettingsService settingsService =
      AlarmSettingsService();

  TimeOfDay alarmTime =
      const TimeOfDay(hour: 8, minute: 0);

  bool alarmEnabled = false;
  bool settingsLoaded = false;

  String lastTriggeredDate = '';
  Timer? clockTimer;

  @override
  void initState() {
    super.initState();

    sensor = MockBedSensor();

    controller = AlarmController(
      sensor: sensor,
      recheckDelay: const Duration(seconds: 5),
      leaveConfirmation: const Duration(seconds: 10),
    );

    controller.addListener(_refresh);

    _loadSettings();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await settingsService.load();

      if (!mounted) return;

      setState(() {
        alarmTime = TimeOfDay(
          hour: settings.hour,
          minute: settings.minute,
        );
        alarmEnabled = settings.enabled;
        lastTriggeredDate = settings.lastTriggeredDate;
        settingsLoaded = true;
      });

      clockTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _checkAlarmTime(),
      );

      _checkAlarmTime();
    } catch (error) {
      debugPrint('Failed to load settings: $error');

      if (mounted) {
        setState(() {
          settingsLoaded = true;
        });
      }
    }
  }

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void _checkAlarmTime() {
    if (!settingsLoaded || !alarmEnabled) return;

    if (controller.state == AlarmState.ringing ||
        controller.state == AlarmState.monitoring) {
      return;
    }

    final now = DateTime.now();
    final today = _dateKey(now);

    if (now.hour == alarmTime.hour &&
        now.minute == alarmTime.minute &&
        lastTriggeredDate != today) {
      // Mark in memory immediately to prevent duplicate triggers.
      lastTriggeredDate = today;

      controller.triggerAlarm();

      settingsService
          .saveLastTriggeredDate(today)
          .catchError((Object error) {
        debugPrint('Failed to save trigger date: $error');
      });
    }
  }

  Future<void> _chooseAlarmTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: alarmTime,
      initialEntryMode: TimePickerEntryMode.input,
      helpText: 'SET WAKE-UP TIME',
    );

    if (selected == null || !mounted) return;

    setState(() {
      alarmTime = selected;
      lastTriggeredDate = '';
    });

    await settingsService.saveTime(
      selected.hour,
      selected.minute,
    );

    if (mounted) _checkAlarmTime();
  }

  Future<void> _toggleAlarm(bool value) async {
    setState(() {
      alarmEnabled = value;
    });

    await settingsService.saveEnabled(value);

    if (mounted && value) {
      _checkAlarmTime();
    }
  }

  String get alarmStatusText {
    switch (controller.state) {
      case AlarmState.idle:
        return alarmEnabled
            ? 'Alarm is ready'
            : 'Alarm is disabled';

      case AlarmState.ringing:
        return 'WAKE UP!';

      case AlarmState.monitoring:
        return 'Monitoring your bed...';

      case AlarmState.completed:
        return 'Successfully woke up!';
    }
  }

  String get bedStatusText {
    switch (sensor.value) {
      case BedPresence.occupied:
        return 'In Bed';

      case BedPresence.empty:
        return 'Out of Bed';

      case BedPresence.unknown:
        return 'Sensor Offline';
    }
  }

  Color get statusColor {
    switch (controller.state) {
      case AlarmState.ringing:
        return Colors.red;

      case AlarmState.completed:
        return Colors.green;

      case AlarmState.monitoring:
        return Colors.orange;

      case AlarmState.idle:
        return Colors.teal;
    }
  }

  @override
  void dispose() {
    clockTimer?.cancel();
    controller.removeListener(_refresh);
    controller.dispose();
    sensor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!settingsLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        title: const Text(
          'Smart Wake',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'alarmkit_test',
        icon: const Icon(Icons.phone_iphone),
        label: const Text('AlarmKit Test'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AlarmKitTestScreen(),
            ),
          );
        },
      ),


      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 12),

                const Text(
                  'Your next wake-up',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 8),

                InkWell(
                  onTap: _chooseAlarmTime,
                  child: Column(
                    children: [
                      Text(
                        alarmTime.format(context),
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172B4D),
                        ),
                      ),
                      const Text(
                        'Tap to change time',
                        style: TextStyle(
                          color: Colors.teal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  child: SwitchListTile(
                    title: const Text(
                      'Daily Alarm',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Repeat every day',
                    ),
                    value: alarmEnabled,
                    onChanged: _toggleAlarm,
                    secondary: const Icon(Icons.repeat),
                  ),
                ),

                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text('Alarm Status'),

                        const SizedBox(height: 12),

                        Icon(
                          controller.isRinging
                              ? Icons.notifications_active
                              : Icons.alarm,
                          size: 48,
                          color: statusColor,
                        ),

                        const SizedBox(height: 10),

                        Text(
                          alarmStatusText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'Times triggered: '
                          '${controller.ringCount}',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bed),
                            SizedBox(width: 10),
                            Text(
                              'Bed Monitoring',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Text(
                          bedStatusText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24),
                        ),

                        const SizedBox(height: 14),

                        DropdownButton<BedPresence>(
                          value: sensor.value,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: BedPresence.occupied,
                              child: Text('In Bed'),
                            ),
                            DropdownMenuItem(
                              value: BedPresence.empty,
                              child: Text('Out of Bed'),
                            ),
                            DropdownMenuItem(
                              value: BedPresence.unknown,
                              child: Text('Sensor Offline'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              sensor.setPresence(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (controller.state != AlarmState.ringing &&
                    controller.state != AlarmState.monitoring)
                  FilledButton.icon(
                    onPressed: controller.triggerAlarm,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Test Alarm Now'),
                  ),

                if (controller.isRinging)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: controller.stopAlarm,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Alarm'),
                  ),

                const SizedBox(height: 12),

                OutlinedButton(
                  onPressed: controller.reset,
                  child: const Text('Reset Simulation'),
                ),

                const SizedBox(height: 24),

                const Text(
                  'DEVELOPMENT MODE\n'
                  'Bed recheck: 5 seconds\n'
                  'Leave confirmation: 10 seconds\n'
                  'Scheduled alarm works only while '
                  'this app is running in the foreground.\n'
                  'No real alarm sound yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
