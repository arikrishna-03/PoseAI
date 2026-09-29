import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/animated_score_badge.dart';
import '../../../core/widgets/grid_overlay.dart';
import '../../poses/presentation/pose_picker_sheet.dart';
import '../../poses/presentation/pose_view_model.dart';
import '../../settings/presentation/settings_view_model.dart';
import 'camera_view_model.dart';
import 'widgets/camera_control_bar.dart';
import 'widgets/camera_top_bar.dart';
import 'widgets/hint_banner.dart';
import 'widgets/pose_skeleton_painter.dart';

class CameraScreen extends ConsumerWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraViewModelProvider);
    final cameraNotifier = ref.read(cameraViewModelProvider.notifier);
    final poseState = ref.watch(poseViewModelProvider);
    final settings = ref.watch(settingsViewModelProvider);

    final controller = cameraState.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Feed
          if (controller != null && controller.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: 1 / controller.value.aspectRatio,
                child: CameraPreview(controller),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.primaryNeon),
            ),

          // 2. Rule of Thirds Grid Overlay
          GridOverlay(show: cameraState.showGrid || settings.showGridLines),

          // 3. Pose Skeleton Overlay (Ghost + Realtime Detected)
          if (controller != null && controller.value.isInitialized)
            Positioned.fill(
              child: CustomPaint(
                painter: PoseSkeletonPainter(
                  detectedLandmarks: cameraState.detectedLandmarks,
                  targetPose: poseState.currentSelectedPose,
                  matchScore: cameraState.matchResult.score,
                  isFrontCamera: cameraState.isFrontCamera && settings.mirrorFrontCamera,
                ),
              ),
            ),

          // 4. White Flash Animation when picture is captured
          if (cameraState.isCapturing)
            AnimatedOpacity(
              opacity: cameraState.isCapturing ? 0.7 : 0.0,
              duration: const Duration(milliseconds: 100),
              child: Container(color: Colors.white),
            ),

          // 5. Timer Countdown Overlay (Big Number in Center)
          if (cameraState.activeTimerCountdown > 0)
            Center(
              child: Text(
                '${cameraState.activeTimerCountdown}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 96,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.black87, blurRadius: 20),
                  ],
                ),
              ),
            ),

          // 6. UI Overlays (Top Bar, Score, Guidance Hint, Bottom Controls)
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar
              Column(
                children: [
                  CameraTopBar(
                    flashMode: cameraState.flashMode,
                    onToggleFlash: cameraNotifier.toggleFlash,
                    timerSeconds: cameraState.timerSeconds,
                    onToggleTimer: cameraNotifier.toggleTimer,
                    showGrid: cameraState.showGrid,
                    onToggleGrid: cameraNotifier.toggleGrid,
                  ),
                  const SizedBox(height: 8),
                  // Animated Match Score Badge
                  if (poseState.currentSelectedPose != null)
                    AnimatedScoreBadge(
                      score: cameraState.matchResult.score,
                      isTargetReached: cameraState.matchResult.isTargetReached,
                    ),
                  const SizedBox(height: 8),
                  // Real-time Actionable Guidance Hint Banner
                  if (cameraState.detectedLandmarks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: HintBanner(
                        hint: cameraState.matchResult.primaryHint,
                        score: cameraState.matchResult.score,
                        isTargetReached: cameraState.matchResult.isTargetReached,
                      ),
                    ),
                ],
              ),

              // Bottom Thumb-Reachable Control Bar
              CameraControlBar(
                currentPose: poseState.currentSelectedPose,
                onOpenPosePicker: () => PosePickerSheet.show(context),
                onCapturePhoto: cameraNotifier.capturePhoto,
                onFlipCamera: cameraNotifier.flipCamera,
                isCapturing: cameraState.isCapturing,
                autoCaptureProgress: cameraState.autoCaptureProgress,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
