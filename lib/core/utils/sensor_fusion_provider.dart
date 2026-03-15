import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Sensor-fused heading provider (uncorrected, 0° declination baseline).
/// Most consumers should use [headingProvider] in heading_provider.dart,
/// which automatically applies magnetic declination for True North.
final fusedHeadingProvider = StreamProvider<double>((ref) {
  return SensorFusionEngine(declinationDeg: 0.0).headingStream;
});

/// Publicly accessible engine — instantiate with the local declination
/// to get a True North heading stream. Used by heading_provider.dart.
class SensorFusionEngine {
  // ─── Complementary filter tuning ──────────────────────────────────────────
  // α close to 1.0 = trust gyro more (smoother, but drifts)
  // α close to 0.0 = trust magnetometer more (noisier, but no drift)
  static const double _alpha = 0.92;

  // How aggressively to smooth the magnetometer reference
  static const double _magSmoothFactor = 0.08;

  // Minimum interval between emitted values (16ms ≈ 60 Hz)
  static const Duration _emitInterval = Duration(milliseconds: 16);

  // ── Calibration / quantization ────────────────────────────────────────────
  // Snap emitted heading to this resolution (degrees).
  // 1.0° matches the practical resolution of consumer magnetometers
  // and removes sub-degree noise from causing spurious widget rebuilds.
  static const double _resolutionDeg = 1.0;

  /// Magnetic declination offset added to every emitted heading value,
  /// converting Magnetic North → True North.
  /// Positive = east declination (heading increases), negative = west.
  final double declinationDeg;

  SensorFusionEngine({required this.declinationDeg});

  Stream<double> get headingStream => _createFusedStream();

  Stream<double> _createFusedStream() {
    late StreamController<double> controller;
    StreamSubscription? compassSub;
    StreamSubscription? gyroSub;
    StreamSubscription? accelSub;

    double fusedHeading = 0.0;
    double smoothedMagHeading = 0.0;
    bool magInitialized = false;
    double lastEmittedQuantized = -1.0;

    // Tilt compensation values from accelerometer
    double pitch = 0.0;
    double roll = 0.0;

    // Gyro integration tracking
    DateTime lastGyroTime = DateTime.now();
    DateTime lastEmitTime = DateTime.now();

    controller = StreamController<double>(
      onListen: () {
        // ─── Accelerometer: compute pitch & roll for tilt awareness ──────
        accelSub = accelerometerEventStream(
          samplingPeriod: SensorInterval.uiInterval,
        ).listen((event) {
          final ax = event.x;
          final ay = event.y;
          final az = event.z;
          final norm = sqrt(ax * ax + ay * ay + az * az);
          if (norm > 0.1) {
            pitch = asin((ay / norm).clamp(-1.0, 1.0));
            roll = asin((ax / norm).clamp(-1.0, 1.0));
          }
        });

        // ─── Magnetometer: absolute heading reference (Magnetic North) ────
        // flutter_compass on Android → Magnetic North (degrees).
        // flutter_compass on iOS → True North (declination already applied).
        // declinationDeg is set to 0.0 for iOS in heading_provider.dart.
        final compassStream = FlutterCompass.events;
        if (compassStream != null) {
          compassSub = compassStream.listen((event) {
            final raw = event.heading ?? event.headingForCameraMode;
            if (raw == null) return;

            final magHeading = _normalize360(raw);

            if (!magInitialized) {
              smoothedMagHeading = magHeading;
              fusedHeading = magHeading;
              magInitialized = true;
              final q = _quantizeAndCorrect(fusedHeading);
              lastEmittedQuantized = q;
              controller.add(q);
              return;
            }

            // Exponential moving average on magnetometer to reduce jitter
            var diff = magHeading - smoothedMagHeading;
            if (diff > 180) diff -= 360;
            if (diff < -180) diff += 360;
            smoothedMagHeading = _normalize360(
              smoothedMagHeading + _magSmoothFactor * diff,
            );
          });
        }

        // ─── Gyroscope: integrate Z-axis rotation for smooth tracking ─────
        gyroSub = gyroscopeEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen((event) {
          if (!magInitialized) return;

          final now = DateTime.now();
          final dt = (now.difference(lastGyroTime).inMicroseconds) / 1e6;
          lastGyroTime = now;

          if (dt <= 0 || dt > 0.5) return;

          // Tilt-compensated effective yaw rate
          final gz = event.z;
          final gx = event.x;
          final gy = event.y;

          final effectiveYawRate =
              gz * cos(pitch) * cos(roll) + gx * sin(roll) + gy * sin(pitch);

          // Gyro Z is positive CCW, compass is CW → subtract
          final gyroHeading = _normalize360(
            fusedHeading - effectiveYawRate * (180.0 / pi) * dt,
          );

          // Complementary filter blend
          var magDiff = smoothedMagHeading - gyroHeading;
          if (magDiff > 180) magDiff -= 360;
          if (magDiff < -180) magDiff += 360;

          fusedHeading = _normalize360(gyroHeading + (1.0 - _alpha) * magDiff);

          // Throttle to ~60 Hz, quantize + apply declination, emit on change
          if (now.difference(lastEmitTime) >= _emitInterval) {
            lastEmitTime = now;
            final q = _quantizeAndCorrect(fusedHeading);
            if (q != lastEmittedQuantized) {
              lastEmittedQuantized = q;
              controller.add(q);
            }
          }
        });
      },
      onCancel: () {
        compassSub?.cancel();
        gyroSub?.cancel();
        accelSub?.cancel();
      },
    );

    return controller.stream;
  }

  static double _normalize360(double angle) {
    return ((angle % 360) + 360) % 360;
  }

  /// Rounds [angle] to the nearest [_resolutionDeg] step, normalises to [0, 360).
  static double _quantize(double angle) {
    final steps = (angle / _resolutionDeg).round();
    return _normalize360(steps * _resolutionDeg);
  }

  /// Applies declination correction then quantizes to 1° steps.
  double _quantizeAndCorrect(double magneticHeading) {
    return _quantize(_normalize360(magneticHeading + declinationDeg));
  }
}
