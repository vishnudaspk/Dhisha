import 'package:flutter/material.dart';

class LoadingRadar extends StatefulWidget {
  final Color color;
  final double size;

  const LoadingRadar({super.key, required this.color, this.size = 24.0});

  @override
  State<LoadingRadar> createState() => _LoadingRadarState();
}

class _LoadingRadarState extends State<LoadingRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);

    // sine wave is close to easeInOut
    _opacityAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnim,
      builder: (context, _) {
        return Opacity(
          opacity: _opacityAnim.value,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
            ),
          ),
        );
      },
    );
  }
}
