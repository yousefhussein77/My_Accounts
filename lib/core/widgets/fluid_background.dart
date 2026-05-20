import 'dart:math' as math;

import 'package:flutter/material.dart';

class FluidBackground extends StatefulWidget {
  const FluidBackground({
    this.intensity = 1,
    super.key,
  });

  final double intensity;

  @override
  State<FluidBackground> createState() => _FluidBackgroundState();
}

class _FluidBackgroundState extends State<FluidBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _FluidBackgroundPainter(
              progress: _controller.value,
              surface: colors.surface,
              primary: colors.primary,
              secondary: colors.secondary,
              outline: colors.outline,
              intensity: widget.intensity,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _FluidBackgroundPainter extends CustomPainter {
  const _FluidBackgroundPainter({
    required this.progress,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.outline,
    required this.intensity,
  });

  final double progress;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color outline;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(surface, primary, 0.08 * intensity)!,
          surface,
          Color.lerp(surface, secondary, 0.05 * intensity)!,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    _drawGlow(
      canvas,
      size,
      center: Offset(
        size.width * (0.18 + 0.05 * math.sin(progress * math.pi * 2)),
        size.height * 0.16,
      ),
      radius: size.shortestSide * 0.55,
      color: primary.withOpacity(0.12 * intensity),
    );
    _drawGlow(
      canvas,
      size,
      center: Offset(
        size.width * (0.88 + 0.04 * math.cos(progress * math.pi * 2)),
        size.height * 0.72,
      ),
      radius: size.shortestSide * 0.46,
      color: secondary.withOpacity(0.09 * intensity),
    );

    _drawWave(
      canvas,
      size,
      yFactor: 0.30,
      amplitude: 18 * intensity,
      phase: progress * math.pi * 2,
      color: primary.withOpacity(0.10 * intensity),
    );
    _drawWave(
      canvas,
      size,
      yFactor: 0.42,
      amplitude: 14 * intensity,
      phase: progress * math.pi * 2 + math.pi * 0.65,
      color: outline.withOpacity(0.11 * intensity),
    );
  }

  void _drawGlow(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withOpacity(0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required double yFactor,
    required double amplitude,
    required double phase,
    required Color color,
  }) {
    final path = Path();
    final baseY = size.height * yFactor;
    path.moveTo(0, baseY);
    for (var x = 0.0; x <= size.width; x += 12) {
      final y = baseY +
          math.sin((x / size.width * math.pi * 2) + phase) * amplitude +
          math.sin((x / size.width * math.pi * 4) - phase * 0.7) *
              amplitude *
              0.35;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _FluidBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.surface != surface ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.outline != outline ||
        oldDelegate.intensity != intensity;
  }
}
