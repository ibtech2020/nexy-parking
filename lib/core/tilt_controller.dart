import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

/// Reads device gyroscope/accelerometer and converts tilt to steer value -1..1
class TiltController {
  StreamSubscription<AccelerometerEvent>? _sub;
  double _steerValue = 0;
  bool _active = false;

  // Calibration baseline
  double _baseX = 0;
  bool _calibrated = false;

  double get steerValue => _active ? _steerValue : 0;

  void start() {
    _active = true;
    _sub = accelerometerEventStream().listen(_onAccelerometer);
  }

  void _onAccelerometer(AccelerometerEvent event) {
    if (!_calibrated) {
      // First reading = neutral position
      _baseX = event.x;
      _calibrated = true;
      return;
    }
    // event.x is lateral tilt in landscape mode
    // Positive x = tilt right = steer right
    final tilt = (event.x - _baseX).clamp(-4.0, 4.0);
    _steerValue = (tilt / 4.0).clamp(-1.0, 1.0);
  }

  void recalibrate() => _calibrated = false;

  void stop() {
    _active = false;
    _sub?.cancel();
    _sub = null;
    _steerValue = 0;
    _calibrated = false;
  }

  void dispose() => stop();
}
