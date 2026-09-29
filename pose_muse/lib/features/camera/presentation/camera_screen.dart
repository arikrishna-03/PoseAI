import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/grid_overlay.dart';
import '../../coaching/presentation/coaching_screen.dart';
import '../../ideas/presentation/ideas_view_model.dart';
import '../../ideas/presentation/widgets/idea_card.dart';
import '../../ideas/presentation/widgets/idea_detail_sheet.dart';
import '../../ideas/presentation/widgets/scan_loading_overlay.dart';
import '../../settings/presentation/settings_view_model.dart';
import 'camera_view_model.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final PageController _ideasPageController = PageController(viewportFraction: 0.88);

  void _onGetIdeasTapped() async {
    final cameraState = ref.read(cameraViewModelProvider);
    final controller = cameraState.controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      final XFile snapshot = await controller.takePicture();
      // Estimated people count hint from on-device detector
      final peopleHint = cameraState.detectedLandmarks.isNotEmpty ? 1 : 1;

      ref.read(ideasViewModelProvider.notifier).scanAndGenerateIdeas(
            photoPath: snapshot.path,
            peopleCountHint: peopleHint,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to grab snapshot: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _ideasPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraViewModelProvider);
    final cameraNotifier = ref.read(cameraViewModelProvider.notifier);
    final ideasState = ref.watch(ideasViewModelProvider);
    final settings = ref.watch(settingsViewModelProvider);

    final controller = cameraState.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Viewfinder
          if (controller != null && controller.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: 1 / controller.value.aspectRatio,
                child: CameraPreview(controller),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: AppColors.primaryNeon)),

          // 2. Rule of Thirds Grid Overlay
          GridOverlay(show: cameraState.showGrid || settings.showGridLines),

          // 3. Scanning Loading State with rotating thoughts
          if (ideasState.status == IdeasStatus.scanning)
            ScanLoadingOverlay(message: ideasState.scanningMessage),

          // 4. Offline State Banner
          if (ideasState.status == IdeasStatus.offline)
            _buildErrorBanner(
              context,
              icon: Icons.wifi_off_rounded,
              title: "You're Offline",
              message: ideasState.errorMessage ?? 'Connect to the internet to generate fresh photo ideas for this scene.',
              actionLabel: 'Try Again',
              onAction: _onGetIdeasTapped,
            ),

          // 5. Rate Limit State Banner
          if (ideasState.status == IdeasStatus.rateLimited)
            _buildErrorBanner(
              context,
              icon: Icons.hourglass_top_rounded,
              title: 'Daily Limit Reached',
              message: ideasState.errorMessage ?? 'You have reached your 30 daily scans.',
              actionLabel: 'OK',
              onAction: () => ref.read(ideasViewModelProvider.notifier)._init(),
            ),

          // 6. Generic Error State
          if (ideasState.status == IdeasStatus.error)
            _buildErrorBanner(
              context,
              icon: Icons.error_outline_rounded,
              title: 'Vision AI Error',
              message: ideasState.errorMessage ?? 'Failed to analyze scene. Please try again.',
              actionLabel: 'Retry',
              onAction: _onGetIdeasTapped,
            ),

          // 7. Top & Bottom Controls Overlays
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Settings
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 24),
                        onPressed: () => context.push('/settings'),
                      ),

                      // Scene analysis pill if available
                      if (ideasState.response != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primaryNeon.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.wb_sunny_outlined, color: AppColors.primaryNeon, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                ideasState.response!.sceneAnalysis.locationType,
                                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),

                      // Gallery
                      IconButton(
                        icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 24),
                        onPressed: () => context.push('/gallery'),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom: Idea Cards Carousel (if ideas are available)
                if (ideasState.ideas.isNotEmpty && ideasState.status != IdeasStatus.scanning)
                  SizedBox(
                    height: 200,
                    child: PageView.builder(
                      controller: _ideasPageController,
                      itemCount: ideasState.ideas.length,
                      itemBuilder: (context, index) {
                        final idea = ideasState.ideas[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: IdeaCard(
                            idea: idea,
                            onTap: () {
                              IdeaDetailSheet.show(
                                context,
                                idea,
                                () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CoachingScreen(
                                      idea: idea,
                                      cameraController: cameraState.controller,
                                    ),
                                  ),
                                ),
                              );
                            },
                            onRate: (isLiked) {
                              ref.read(ideasViewModelProvider.notifier).rateIdea(idea.id, isLiked);
                            },
                          ),
                        );
                      },
                    ),
                  ),

                // Bottom Action Button: "Get Ideas"
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Camera flip
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
                          onPressed: cameraNotifier.flipCamera,
                        ),
                      ),

                      // Prominent "Get Ideas" Scan Shutter Button
                      GestureDetector(
                        onTap: ideasState.status == IdeasStatus.scanning ? null : _onGetIdeasTapped,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryNeon, AppColors.primaryCyan],
                            ),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryNeon.withOpacity(0.4),
                                blurRadius: 18,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_rounded, color: Colors.black, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Get Ideas',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Flash toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.flash_auto_rounded, color: Colors.white),
                          onPressed: cameraNotifier.toggleFlash,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Positioned(
      top: 90,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.darkSurface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.errorRed.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.errorRed, size: 36),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNeon,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
