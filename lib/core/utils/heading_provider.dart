import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sensor_fusion_provider.dart';

/// Provider that streams the device heading.
/// [flutter_compass] attempts to yield True North if location permissions are
/// granted, falling back to Magnetic North if not. The sensor fusion engine
/// automatically uses this value.
final headingProvider = StreamProvider<double>((ref) {
  // Pass 0.0 because flutter_compass handles true north internally
  // when location permissions are granted on both iOS and Android.
  return SensorFusionEngine(declinationDeg: 0.0).headingStream;
});
