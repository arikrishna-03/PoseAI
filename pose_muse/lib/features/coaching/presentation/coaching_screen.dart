import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/animated_score_badge.dart';
import '../../../core/widgets/glass_container.dart';
import '../../camera/presentation/widgets/hint_banner.dart';
import '../../ideas/domain/photo_idea.dart';
import '../../ideas/presentation/ideas_view_model.dart';
import '../../settings/presentation/settings_view_model.dart';
import 'coaching_view_model.dart';
import 'widgets/multi_person_skeleton_painter.dart';

class CoachingScreen extends ConsumerStatefulWidget {
  final PhotoIdea idea;
  final CameraController? cameraController;

  const CoachingScreen({
    super.key,
    required this.idea,
    this.cameraController,
  });

  @override
  ConsumerState<CoachingScreen> createState() => _CoachingScreenState();
}

class _CoachingScreenState extends ConsumerState<CoachingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(coachingViewModelProvider.notifier).startCoaching(widget.idea, widget.cameraController);
    });
  }

  @override
  Widget build(BuildContext context) {
    final coachingState = ref.watch(coachingViewModelProvider);
    final notifier = ref.read(coachingViewModelProvider.notifier);
    final settings = ref.watch(settingsViewModelProvider);

    final controller = coachingState.controller ?? widget.cameraController;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Preview
          if (controller != null && controller.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: 1 / controller.value.aspectRatio,
                child: CameraPreview(controller),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: AppColors.primaryNeon)),

          // 2. Multi-Person Skeleton Overlay (Ghost + Realtime)
          if (controller != null && controller.value.isInitialized)
            Positioned.fill(
              child: CustomPaint(
                painter: MultiPersonSkeletonPainter(
                  targets: widget.idea.people,
                  detectedPeople: coachingState.detectedPeople,
                  personAssignments: coachingState.personAssignments,
                  personScores: coachingState.groupMatchResult.personResults.map((r) => r.score).toList(),
                  isFrontCamera: controller.description.lensDirection == CameraLensDirection.front && settings.mirrorFrontCamera,
                ),
              ),
            ),

          // 3. Capture Flash Effect
          if (coachingState.isCapturing)
            AnimatedOpacity(
              opacity: coachingState.isCapturing ? 0.75 : 0.0,
              duration: const Duration(milliseconds: 100),
              child: Container(color: Colors.white),
            ),

          // 4. Overlays (Top Bar, Score Pill, Hint Banner, Bottom Controls)
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Action Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back to idea selection
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),

                      // Group match score pill
                      AnimatedScoreBadge(
                        score: coachingState.groupMatchResult.overallScore,
                        isTargetReached: coachingState.groupMatchResult.allTargetsReached,
                      ),

                      // Burst mode toggle
                      TextButton.icon(
                        onPressed: notifier.toggleBurstMode,
                        icon: Icon(
                          Icons.burst_mode_rounded,
                          color: coachingState.burstMode ? AppColors.primaryNeon : Colors.white60,
                          size: 20,
                        ),
                        label: Text(
                          coachingState.burstMode ? 'Burst 3' : 'Single',
                          style: TextStyle(
                            color: coachingState.burstMode ? AppColors.primaryNeon : Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.black45,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Top Floating Guidance Hint
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: HintBanner(
                    hint: coachingState.primaryHint,
                    score: coachingState.groupMatchResult.overallScore,
                    isTargetReached: coachingState.groupMatchResult.allTargetsReached,
                  ),
                ),

                const Spacer(),

                // Bottom Control Bar
                Padding(
                  padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Shutter button with outer auto-capture hold countdown ring
                      GestureDetector(
                        onTap: coachingState.isCapturing ? null : notifier.capture,
                        child: SizedBox(
                          width: 86,
                          height: 86,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Auto-capture hold countdown progress ring
                              if (coachingState.autoCaptureProgress > 0)
                                SizedBox(
                                  width: 86,
                                  height: 86,
                                  child: CircularProgressIndicator(
                                    value: coachingState.autoCaptureProgress,
                                    strokeWidth: 4.5,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryNeon),
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),
                              // Shutter outer ring
                              Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: coachingState.autoCaptureProgress > 0 ? AppColors.primaryNeon : Colors.white,
                                    width: 4,
                                  ),
                                ),
                              ),
                              // Shutter inner button
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: coachingState.isCapturing ? 52 : 62,
                                height: coachingState.isCapturing ? 52 : 62,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: coachingState.autoCaptureProgress > 0 ? AppColors.primaryNeon : Colors.white,
                                  boxShadow: [
                                    if (coachingState.autoCaptureProgress > 0)
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
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 5. Post-Capture Review Sheet
          if (coachingState.capturedPhotoPaths.isNotEmpty)
            _buildReviewOverlay(context, coachingState.capturedPhotoPaths.last),
        ],
      ),
    );
  }

  Widget _buildReviewOverlay(BuildContext context, String photoPath) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.92),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Great Shot!',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => context.go('/'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(photoPath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Like/Dislike this idea for future personalization
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Did this idea work well?',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.thumb_up_rounded, color: AppColors.primaryNeon),
                  onPressed: () {
                    ref.read(ideasViewModelProvider.notifier).rateIdea(widget.idea.id, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved! PoseMuse will recommend more like this.')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.thumb_down_rounded, color: AppColors.errorRed),
                  onPressed: () {
                    ref.read(ideasViewModelProvider.notifier).rateIdea(widget.idea.id, false);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: () => Share.shareXFiles([XFile(photoPath)]),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('View Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNeon,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: () => context.push('/gallery'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
