import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';

class CameraTopBar extends StatelessWidget {
  final FlashMode flashMode;
  final VoidCallback onToggleFlash;
  final int timerSeconds;
  final VoidCallback onToggleTimer;
  final bool showGrid;
  final VoidCallback onToggleGrid;

  const CameraTopBar({
    super.key,
    required this.flashMode,
    required this.onToggleFlash,
    required this.timerSeconds,
    required this.onToggleTimer,
    required this.showGrid,
    required this.onToggleGrid,
  });

  IconData _getFlashIcon() {
    switch (flashMode) {
      case FlashMode.torch:
        return Icons.highlight_rounded;
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.always:
        return Icons.flash_on_rounded;
      case FlashMode.off:
      default:
        return Icons.flash_off_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Settings button
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
              onPressed: () => context.push('/settings'),
            ),

            // Middle quick action pill
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              borderRadius: BorderRadius.circular(24),
              backgroundColor: Colors.black.withOpacity(0.4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Flash toggle
                  IconButton(
                    icon: Icon(_getFlashIcon(), color: Colors.white, size: 20),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: onToggleFlash,
                  ),
                  const SizedBox(width: 4),
                  // Timer toggle
                  TextButton(
                    onPressed: onToggleTimer,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: timerSeconds > 0 ? AppColors.primaryNeon : Colors.white,
                          size: 18,
                        ),
                        if (timerSeconds > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${timerSeconds}s',
                            style: const TextStyle(
                              color: AppColors.primaryNeon,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Grid toggle
                  IconButton(
                    icon: Icon(
                      Icons.grid_on_rounded,
                      color: showGrid ? AppColors.primaryNeon : Colors.white60,
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: onToggleGrid,
                  ),
                ],
              ),
            ),

            // Gallery navigation button
            IconButton(
              icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 24),
              onPressed: () => context.push('/gallery'),
            ),
          ],
        ),
      ),
    );
  }
}
