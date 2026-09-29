import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/angle_calculator.dart';
import '../../../core/utils/haptic_service.dart';
import '../../../core/utils/voice_coach_service.dart';
import '../../gallery/data/gallery_repository.dart';
import '../../gallery/domain/captured_photo.dart';
import '../../ideas/domain/photo_idea.dart';
import '../../settings/presentation/settings_view_model.dart';
import '../data/pose_tracker.dart';
import '../domain/person_assigner.dart';
import '../domain/pose_matcher.dart';

final coachingViewModelProvider = StateNotifierProvider.autoDispose<CoachingViewModel, CoachingViewState>((ref) {
  final gallery = GalleryRepository();
  return CoachingViewModel(ref, gallery);
});

class CoachingViewState {
  final CameraController? controller;
  final bool isInitialized;
  final PhotoIdea? idea;
  final List<List<Point3D>> detectedPeople;
  final List<int> personAssignments;
  final GroupMatchResult groupMatchResult;
  final double autoCaptureProgress; // 0.0 to 1.0 (for 1s hold)
  final bool isCapturing;
  final bool burstMode; // Single vs Burst of 3
  final List<String> capturedPhotoPaths;
  final String primaryHint;
  final bool showGrid;
  final FlashMode flashMode;

  const CoachingViewState({
    this.controller,
    this.isInitialized = false,
    this.idea,
    this.detectedPeople = const [],
    this.personAssignments = const [],
    this.groupMatchResult = GroupMatchResult.empty,
    this.autoCaptureProgress = 0.0,
    this.isCapturing = false,
    this.burstMode = false,
    this.capturedPhotoPaths = const [],
    this.primaryHint = 'Step into the camera guide',
    this.showGrid = false,
    this.flashMode = FlashMode.off,
  });

  CoachingViewState copyWith({
    CameraController? controller,
    bool? isInitialized,
    PhotoIdea? idea,
    List<List<Point3D>>? detectedPeople,
    List<int>? personAssignments,
    GroupMatchResult? groupMatchResult,
    double? autoCaptureProgress,
    bool? isCapturing,
    bool? burstMode,
    List<String>? capturedPhotoPaths,
    String? primaryHint,
    bool? showGrid,
    FlashMode? flashMode,
  }) {
    return CoachingViewState(
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
      idea: idea ?? this.idea,
      detectedPeople: detectedPeople ?? this.detectedPeople,
      personAssignments: personAssignments ?? this.personAssignments,
      groupMatchResult: groupMatchResult ?? this.groupMatchResult,
      autoCaptureProgress: autoCaptureProgress ?? this.autoCaptureProgress,
      isCapturing: isCapturing ?? this.isCapturing,
      burstMode: burstMode ?? this.burstMode,
      capturedPhotoPaths: capturedPhotoPaths ?? this.capturedPhotoPaths,
      primaryHint: primaryHint ?? this.primaryHint,
      showGrid: showGrid ?? this.showGrid,
      flashMode: flashMode ?? this.flashMode,
    );
  }
}

class CoachingViewModel extends StateNotifier<CoachingViewState> {
  final Ref _ref;
  final GalleryRepository _galleryRepository;
  final PoseMatcher _poseMatcher = const PoseMatcher();
  final PoseTracker _poseTracker = PoseTracker();

  int _matchStartTimestamp = 0;
  bool _isDisposed = false;

  CoachingViewModel(this._ref, this._galleryRepository) : super(const CoachingViewState());

  Future<void> startCoaching(PhotoIdea idea, CameraController? existingController) async {
    state = state.copyWith(idea: idea);
    await _galleryRepository.init();
    await VoiceCoachService.init();

    // Initial voice tip from photographer advice
    VoiceCoachService.speak('${idea.title}. ${idea.expressionTip}');

    if (existingController != null && existingController.value.isInitialized) {
      state = state.copyWith(controller: existingController, isInitialized: true);
      _listenToStream(existingController);
    }
  }

  void _listenToStream(CameraController controller) {
    controller.startImageStream((image) async {
      if (_isDisposed || !state.isInitialized || state.idea == null) return;

      final output = await _poseTracker.processFrame(
        cameraImage: image,
        camera: controller.description,
        deviceOrientation: DeviceOrientation.portraitUp,
      );

      if (output != null) {
        _processTrackingOutput(output);
      }
    });
  }

  void _processTrackingOutput(PoseTrackerOutput output) {
    if (state.idea == null) return;
    final targets = state.idea!.people;

    // 1. Assign detected people to targets (handles spatial left/center/right swaps)
    final assignments = PersonAssigner.assignPeople(
      detectedPeople: output.detectedPeople,
      targets: targets,
    );

    // 2. Evaluate group match
    final groupResult = _poseMatcher.evaluateGroup(
      detectedPeople: output.detectedPeople,
      targetPoses: targets,
      personAssignments: assignments,
    );

    // 3. Compute best hint & voice speech
    String hint = 'Hold the pose';
    if (groupResult.personResults.isNotEmpty) {
      final worst = groupResult.personResults.reduce((a, b) => a.score < b.score ? a : b);
      if (worst.hints.isNotEmpty) {
        hint = '${worst.personPosition.toUpperCase()}: ${worst.hints.first}';
        VoiceCoachService.speak(worst.hints.first);
      }
    }

    state = state.copyWith(
      detectedPeople: output.detectedPeople,
      personAssignments: assignments,
      groupMatchResult: groupResult,
      primaryHint: hint,
    );

    // 4. Auto-capture evaluation
    _handleAutoCapture(groupResult);
  }

  void _handleAutoCapture(GroupMatchResult result) {
    final settings = _ref.read(settingsViewModelProvider);
    if (!settings.autoCaptureEnabled || state.isCapturing) return;

    final threshold = settings.autoCaptureThreshold;

    if (result.overallScore >= threshold) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_matchStartTimestamp == 0) {
        _matchStartTimestamp = now;
        HapticService.lightImpact();
      }

      final elapsed = now - _matchStartTimestamp;
      final progress = (elapsed / AppConstants.autoCaptureHoldDurationMs).clamp(0.0, 1.0);

      state = state.copyWith(autoCaptureProgress: progress);

      if (elapsed >= AppConstants.autoCaptureHoldDurationMs) {
        _resetAutoCapture();
        capture();
      }
    } else {
      _resetAutoCapture();
    }
  }

  void _resetAutoCapture() {
    _matchStartTimestamp = 0;
    if (state.autoCaptureProgress > 0) {
      state = state.copyWith(autoCaptureProgress: 0.0);
    }
  }

  void toggleBurstMode() {
    HapticService.selectionClick();
    state = state.copyWith(burstMode: !state.burstMode);
  }

  Future<void> capture() async {
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized || state.isCapturing) return;

    state = state.copyWith(isCapturing: true);
    HapticService.mediumImpact();

    final count = state.burstMode ? 3 : 1;
    final List<String> capturedPaths = [];

    for (int i = 0; i < count; i++) {
      try {
        final XFile photo = await controller.takePicture();
        HapticService.heavyImpact();

        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'posemuse_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final savedPath = '${appDir.path}/$fileName';
        await File(photo.path).copy(savedPath);
        capturedPaths.add(savedPath);

        // Record in Gallery Hive
        await _galleryRepository.savePhoto(
          CapturedPhoto(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            filePath: savedPath,
            timestamp: DateTime.now(),
            poseName: state.idea?.title ?? 'Custom Idea',
            matchScore: state.groupMatchResult.overallScore,
          ),
        );

        if (count > 1 && i < count - 1) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      } catch (_) {}
    }

    state = state.copyWith(
      isCapturing: false,
      capturedPhotoPaths: capturedPaths,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _poseTracker.dispose();
    VoiceCoachService.stop();
    super.dispose();
  }
}
