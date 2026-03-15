import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A widget that displays the current local time ticking every second.
class LiveLocalTime extends StatefulWidget {
  final TextStyle style;
  final double longitude;

  const LiveLocalTime({super.key, required this.style, required this.longitude});

  @override
  State<LiveLocalTime> createState() => _LiveLocalTimeState();
}

class _LiveLocalTimeState extends State<LiveLocalTime> {
  late Timer _timer;
  late String _timeString;

  String _getAdjustedTime() {
    // 15 degrees longitude = 1 hour (or 1 degree = 4 minutes)
    final offsetMinutes = (widget.longitude * 4).round();
    final adjustedTime = DateTime.now().toUtc().add(Duration(minutes: offsetMinutes));
    return DateFormat('HH:mm:ss').format(adjustedTime);
  }

  @override
  void initState() {
    super.initState();
    _timeString = _getAdjustedTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return;
      setState(() {
        _timeString = _getAdjustedTime();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_timeString, style: widget.style);
  }
}
