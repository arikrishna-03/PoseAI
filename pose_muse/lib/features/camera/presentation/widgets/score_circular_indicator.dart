import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ScoreCircularIndicator extends StatelessWidget {
  final double score; // 0.0 to 1.0
  final double size;

  const ScoreCircularIndicator({
    super.key,
    required this.score,
    this.size = 54.0,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.matchColor(score);
    final percentage = (score * 100).toInt().clamp(0, 100);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          CustomPaint(
            size: Size(size, size),
            painter: _CircularProgressPainter(
              progress: 1.0,
              strokeWidth: 4.0,
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          // Animated progress ring
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: score),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return CustomPaint(
                size: Size(size, size),
                painter: _CircularProgressPainter(
                  progress: value,
                  strokeWidth: 4.5,
                  color: color,
                ),
              );
            },
          ),
          // Percentage text
          Text(
            '$percentage%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
