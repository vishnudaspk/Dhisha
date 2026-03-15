// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';

Future<void> main() async {
  // A dark foreground with transparent background for launcher icon plugin to overlay on light/dark adaptive bg
  final size = 1024.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

  // Settings
  final color = Color(0xFF1C1C1A); // Dark structural color
  final accent = Color(0xFFE64D2E); // Vermilion

  // Make logo take up ~60% of the image size per user spec, but actually flutter_launcher_icons handles
  // adaptive background, so the foreground itself should be large but fit within the safe zone.
  final logoSize = size * 0.6;
  final center = Offset(size / 2, size / 2);
  final radius = logoSize / 2;

  // 1. Circle
  final circlePaint =
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16.0;

  canvas.drawCircle(center, radius, circlePaint);

  // 2. Crosshairs
  final linePaint =
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12.0;

  canvas.drawLine(
    Offset(center.dx, center.dy - radius),
    Offset(center.dx, center.dy + radius),
    linePaint,
  );
  canvas.drawLine(
    Offset(center.dx - radius, center.dy),
    Offset(center.dx + radius, center.dy),
    linePaint,
  );

  // 3. Pointer
  final pointerPaint =
      Paint()
        ..color = accent
        ..style = PaintingStyle.fill;

  final angle = -105 * pi / 180;
  final perp = angle + pi / 2;
  final pointerPath = Path();

  final tip = Offset(
    center.dx + radius * 0.95 * cos(angle),
    center.dy + radius * 0.95 * sin(angle),
  );

  final baseLeft = Offset(
    center.dx + radius * 0.55 * cos(angle) + 40 * cos(perp),
    center.dy + radius * 0.55 * sin(angle) + 40 * sin(perp),
  );
  final baseRight = Offset(
    center.dx + radius * 0.55 * cos(angle) - 40 * cos(perp),
    center.dy + radius * 0.55 * sin(angle) - 40 * sin(perp),
  );

  pointerPath.moveTo(tip.dx, tip.dy);
  pointerPath.lineTo(baseLeft.dx, baseLeft.dy);
  pointerPath.lineTo(baseRight.dx, baseRight.dy);
  pointerPath.close();

  canvas.drawPath(pointerPath, pointerPaint);

  // Save to file
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

  if (byteData != null) {
    final buffer = byteData.buffer;
    final file = File('assets/logo/icon_fg.png');
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    await file.writeAsBytes(
      buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
    );
    print('Saved assets/logo/icon_fg.png');
  } else {
    print('Failed to convert image');
    exit(1);
  }
}
