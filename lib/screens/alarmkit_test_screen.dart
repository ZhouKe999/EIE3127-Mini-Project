
import 'package:flutter/material.dart';

import '../services/alarmkit_service.dart';

class AlarmKitTestScreen extends StatefulWidget {
  const AlarmKitTestScreen({super.key});

  @override
  State<AlarmKitTestScreen> createState() =>
      _AlarmKitTestScreenState();
}

class _AlarmKitTestScreenState
    extends State<AlarmKitTestScreen> {
  final AlarmKitService service = AlarmKitService();

  bool busy = false;
  String status = 'Not tested';
  String? alarmId;

  Future<void> runAction(
    Future<void> Function() action,
  ) async {
    setState(() => busy = true);

    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(() => status = 'Error: $error');
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final supported = service.isSupportedPlatform;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AlarmKit Test'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.alarm, size: 72),
              const SizedBox(height: 20),

              Text(
                supported
                    ? 'iOS AlarmKit available for testing'
                    : 'iOS device required',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              FilledButton(
                onPressed: busy || !supported
                    ? null
                    : () => runAction(() async {
                        final allowed =
                            await service.requestPermission();

                        if (mounted) {
                          setState(() {
                            status = allowed
                                ? 'Permission granted'
                                : 'Permission denied';
                          });
                        }
                      }),
                child: const Text('1. Request Permission'),
              ),

              const SizedBox(height: 12),

              FilledButton(
                onPressed: busy || !supported
                    ? null
                    : () => runAction(() async {
                        final id =
                            await service.scheduleTestAlarm();

                        if (mounted) {
                          setState(() {
                            alarmId = id;
                            status =
                                'Alarm scheduled in 60 seconds';
                          });
                        }
                      }),
                child: const Text('2. Schedule 60s Alarm'),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: busy ||
                        !supported ||
                        alarmId == null
                    ? null
                    : () => runAction(() async {
                        await service.cancelAlarm(alarmId!);

                        if (mounted) {
                          setState(() {
                            alarmId = null;
                            status = 'Alarm cancelled';
                          });
                        }
                      }),
                child: const Text('3. Cancel Alarm'),
              ),

              const SizedBox(height: 30),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    status,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
