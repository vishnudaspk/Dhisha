import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:ui' as ui;

class WindFlowBackground extends StatefulWidget {
  final double windDirectionDegrees; // FROM direction
  final double windSpeedMps;
  final double heading; // Device gyro heading

  const WindFlowBackground({
    super.key,
    required this.windDirectionDegrees,
    required this.windSpeedMps,
    required this.heading,
  });

  @override
  State<WindFlowBackground> createState() => _WindFlowBackgroundState();
}

class WindParticle {
  Offset pos;
  final List<Offset> trail = [];
  double speedMultiplier;
  int maxTrailLen;

  WindParticle({
    required this.pos,
    required this.speedMultiplier,
    required this.maxTrailLen,
  });
}

class _WindFlowBackgroundState extends State<WindFlowBackground>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _lastTime = 0;
  final List<WindParticle> _particles = [];
  final ValueNotifier<int> _tickNotifier = ValueNotifier(0);
  final Random _random = Random(); // Persistent random instance prevents seed overlap

  @override
  void initState() {
    super.initState();
    _initParticles();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(WindFlowBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When heading/speed updates from Riverpod, we do NOT want to clear _particles!
    // We just let the next tick automatically use the new widget.heading and widget.windSpeedMps.
    // This allows the particles to bend fluidly instead of restarting.
  }

  void _initParticles() {
    // 200 to 2800 particles (using whatever the user set).
    // Spread them uniformly across a massive 2000x2000 bounding box
    // so there is absolutely no clustering bias on initial load.
    for (int i = 0; i < 2800; i++) {
      _particles.add(
        WindParticle(
          pos: Offset(
            (_random.nextDouble() - 0.5) * 2000, // X: -1000 to +1000
            (_random.nextDouble() - 0.5) * 2000, // Y: -1000 to +1000
          ),
          speedMultiplier: 0.5 + _random.nextDouble() * 0.8,
          // 30 to 70 length trails
          maxTrailLen: 30 + _random.nextInt(40),
        ),
      );
    }
  }

  void _onTick(Duration elapsed) {
    double t = elapsed.inMicroseconds / 1000000.0;
    double dt = t - _lastTime;
    _lastTime = t;
    if (dt > 0.1) dt = 0.1;

    // Speed in m/s → pixels/s scale. 1 m/s ≈ 6 px/s feels realistic.
    final baseSpeedPx = (widget.windSpeedMps * 6.0).clamp(4.0, 60.0);

    // ── Direction math ─────────────────────────────────────────────────────
    // windDirectionDegrees = FROM direction (meteorological, True North).
    // We want the TO direction: FROM + 180°.
    // Then subtract device heading so strokes stay anchored to geography
    // regardless of which way the phone is pointed.
    //
    // Flutter canvas: X+ = right, Y+ = down, with centre at 0,0.
    // For a compass bearing B (0=North/up, 90=East/right):
    //   dx =  sin(B_rad)   → positive = right  ✓
    //   dy = -cos(B_rad)   → positive = down   (canvas Y is inverted vs math)
    //
    // Old code used (deg - 90)*pi/180 and then cos/sin which gave the right
    // dx but a *wrong* dy sign (North-bound strokes moved DOWN, not UP).
    final toDeg = (widget.windDirectionDegrees + 180.0 - widget.heading) % 360.0;
    final toRad = toDeg * pi / 180.0;
    final dx =  sin(toRad);
    final dy = -cos(toRad);
    // ───────────────────────────────────────────────────────────────────────

    for (var p in _particles) {
      p.pos += Offset(dx, dy) * baseSpeedPx * p.speedMultiplier * dt;
      p.trail.add(p.pos);
      if (p.trail.length > p.maxTrailLen) {
        p.trail.removeAt(0);
      }

      // Hard wrap-around on a 2000x2000 grid centered at (0,0).
      // This mathematically guarantees particles can NEVER compress into a single line.
      // E.g., if a particle hits X = 1000, it instantly wraps to X = -1000.
      bool wrapped = false;
      if (p.pos.dx > 1000) { p.pos = Offset(-1000, p.pos.dy); wrapped = true; }
      else if (p.pos.dx < -1000) { p.pos = Offset(1000, p.pos.dy); wrapped = true; }

      if (p.pos.dy > 1000) { p.pos = Offset(p.pos.dx, -1000); wrapped = true; }
      else if (p.pos.dy < -1000) { p.pos = Offset(p.pos.dx, 1000); wrapped = true; }

      if (wrapped) {
        p.trail.clear();
        // Give it a slightly new random speed/length so patterns don't repeat exactly
        p.speedMultiplier = 0.5 + _random.nextDouble() * 0.8;
        p.maxTrailLen = 30 + _random.nextInt(40);
      }
    }
    // Trigger repaint without rebuilding complete Widget tree
    _tickNotifier.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tickNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _WindFlowPainter(particles: _particles, tick: _tickNotifier),
    );
  }
}

class _WindFlowPainter extends CustomPainter {
  final List<WindParticle> particles;

  _WindFlowPainter({required this.particles, required Listenable tick})
    : super(repaint: tick);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx, center.dy);

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.0;

    for (var p in particles) {
      if (p.trail.length < 2) continue;

      final path = Path();
      path.moveTo(p.trail.first.dx, p.trail.first.dy);
      // Construct the bending tail
      for (int i = 1; i < p.trail.length; i++) {
        path.lineTo(p.trail[i].dx, p.trail[i].dy);
      }

      final head = p.pos;
      final tail = p.trail.first;
      if (head == tail) continue;

      // Fading tail: head is solid(ish) up to 50%, tail is 0 opacity
      paint.shader = ui.Gradient.linear(head, tail, [
        Colors.white.withAlpha(
          (127 * p.speedMultiplier).toInt().clamp(20, 127),
        ),
        Colors.white.withAlpha(0),
      ]);

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WindFlowPainter oldDelegate) => true; // driven by tick
}
