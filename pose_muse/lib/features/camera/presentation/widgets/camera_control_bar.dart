import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../poses/domain/pose_model.dart';

class CameraControlBar extends StatelessWidget {
  final PoseModel? currentPose;
  final VoidCallback onOpenPosePicker;
  final VoidCallback onCapturePhoto;
  final VoidCallback onFlipCamera;
  final bool isCapturing;
  final double autoCaptureProgress; // 0.0 to 1.0 (for 1 second hold countdown)

  const CameraControlBar({
    super.key,
    required this.currentPose,
    required this.onOpenPosePicker,
    required this.onCapturePhoto,
    required this.onFlipCamera,
    this.isCapturing = false,
    this.autoCaptureProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Current Pose Button / Open Library
            GestureDetector(
              onTap: onOpenPosePicker,
              child: GlassContainer(
                width: 72,
                height: 72,
                borderRadius: BorderRadius.circular(36),
                backgroundColor: Colors.black.withOpacity(0.45),
                borderColor: AppColors.primaryNeon.withOpacity(0.4),
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.accessibility_new_rounded, color: AppColors.primaryNeon, size: 26),
                    const SizedBox(height: 2),
                    Text(
                      currentPose != null ? 'Poses' : 'Pick Pose',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),

            // Center: Primary Capture Button with Auto-Capture Ring
            GestureDetector(
              onTap: isCapturing ? null : onCapturePhoto,
              child: SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer countdown / progress ring during auto-capture
                    if (autoCaptureProgress > 0.0)
                      SizedBox(
                        width: 84,
                        height: 84,
                        child: CircularProgressIndicator(
                          value: autoCaptureProgress,
                          strokeWidth: 4.5,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryNeon),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    // Outer white ring
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: autoCaptureProgress > 0 ? AppColors.primaryNeon : Colors.white,
                          width: 4,
                        ),
                      ),
                    ),
                    // Inner shutter button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: isCapturing ? 50 : 60,
                      height: isCapturing ? 50 : 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: autoCaptureProgress > 0 ? AppColors.primaryNeon : Colors.white,
                        boxShadow: [
                          if (autoCaptureProgress > 0)
                            BoxShadow(
                              color: AppColors.primaryNeon.withOpacity(0.6),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right: Camera Lens Flip Button
            GestureDetector(
              onTap: onFlipCamera,
              child: GlassContainer(
                width: 72,
                height: 72,
                borderRadius: BorderRadius.circular(36),
                backgroundColor: Colors.black.withOpacity(0.45),
                borderColor: Colors.white.withOpacity(0.2),
                child: const Center(
                  child: Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
