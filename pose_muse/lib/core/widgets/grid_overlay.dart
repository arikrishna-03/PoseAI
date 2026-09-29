import 'package:flutter/material.dart';

class GridOverlay extends StatelessWidget {
  final bool show;

  const GridOverlay({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _RuleOfThirdsPainter(),
      ),
    );
  }
}

class _RuleOfThirdsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final x1 = size.width / 3.0;
    final x2 = (size.width / 3.0) * 2.0;
    final y1 = size.height / 3.0;
    final y2 = (size.height / 3.0) * 2.0;

    // Vertical lines
    canvas.drawLine(Offset(x1, 0), Offset(x1, size.height), paint);
    canvas.drawLine(Offset(x2, 0), Offset(x2, size.height), paint);

    // Horizontal lines
    canvas.drawLine(Offset(0, y1), Offset(size.width, y1), paint);
    canvas.drawLine(Offset(0, y2), Offset(size.width, y2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
