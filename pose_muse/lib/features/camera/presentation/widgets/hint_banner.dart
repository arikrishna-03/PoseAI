import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';

class HintBanner extends StatelessWidget {
  final String hint;
  final double score;
  final bool isTargetReached;

  const HintBanner({
    super.key,
    required this.hint,
    required this.score,
    required this.isTargetReached,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.matchColor(score);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.2),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: GlassContainer(
        key: ValueKey<String>(hint),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        borderRadius: BorderRadius.circular(30),
        backgroundColor: Colors.black.withOpacity(0.55),
        borderColor: color.withOpacity(0.4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isTargetReached ? Icons.check_circle_rounded : Icons.tips_and_updates_rounded,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                hint,
                style: TextStyle(
                  color: isTargetReached ? AppColors.primaryNeon : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
