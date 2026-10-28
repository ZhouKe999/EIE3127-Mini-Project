
import 'package:flutter/foundation.dart';
import '../models/alarm_state.dart';
import 'bed_sensor_service.dart';

class MockBedSensor extends ValueNotifier<BedPresence>
    implements BedSensorService {
  MockBedSensor() : super(BedPresence.occupied);

  void setPresence(BedPresence presence) {
    value = presence;
  }
}
