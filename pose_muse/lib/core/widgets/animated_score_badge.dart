import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AnimatedScoreBadge extends StatelessWidget {
  final double score; // 0.0 to 1.0
  final bool isTargetReached;

  const AnimatedScoreBadge({
    super.key,
    required this.score,
    required this.isTargetReached,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score * 100).clamp(0, 100).toInt();
    final color = AppColors.matchColor(score);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          if (isTargetReached)
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 16,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTargetReached ? Icons.check_circle_rounded : Icons.camera_alt_outlined,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$percentage% MATCH',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
