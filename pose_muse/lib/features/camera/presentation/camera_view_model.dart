import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/angle_calculator.dart';
import '../../../core/utils/haptic_service.dart';
import '../../gallery/data/gallery_repository.dart';
import '../../gallery/domain/captured_photo.dart';
import '../../poses/domain/pose_model.dart';
import '../../poses/presentation/pose_view_model.dart';
import '../../settings/presentation/settings_view_model.dart';
import '../data/pose_detector_service.dart';
import '../domain/match_result.dart';
import '../domain/pose_matcher.dart';

final poseDetectorServiceProvider = Provider<PoseDetectorService>((ref) {
  return PoseDetectorService();
});

final galleryRepositoryProvider = Provider<GalleryRepository>((ref) {
  return GalleryRepository();
});

final cameraViewModelProvider = StateNotifierProvider.autoDispose<CameraViewModel, CameraViewState>((ref) {
  final detector = ref.watch(poseDetectorServiceProvider);
  final gallery = ref.watch(galleryRepositoryProvider);
  return CameraViewModel(ref, detector, gallery);
});

class CameraViewState {
  final CameraController? controller;
  final bool isInitialized;
  final bool isStreaming;
  final bool isFrontCamera;
  final FlashMode flashMode;
  final int timerSeconds;
  final int activeTimerCountdown; // for 3s/10s timer
  final bool showGrid;
  final List<Point3D> detectedLandmarks;
  final OverallMatchResult matchResult;
  final double autoCaptureProgress; // 0.0 to 1.0 (for 1s hold)
  final bool isCapturing;
  final String? lastCapturedImagePath;
  final String? errorMessage;

  const CameraViewState({
    this.controller,
    this.isInitialized = false,
    this.isStreaming = false,
    this.isFrontCamera = true,
    this.flashMode = FlashMode.off,
    this.timerSeconds = 0,
    this.activeTimerCountdown = 0,
    this.showGrid = false,
    this.detectedLandmarks = const [],
    this.matchResult = OverallMatchResult.empty,
    this.autoCaptureProgress = 0.0,
    this.isCapturing = false,
    this.lastCapturedImagePath,
    this.errorMessage,
  });

  CameraViewState copyWith({
    CameraController? controller,
    bool? isInitialized,
    bool? isStreaming,
    bool? isFrontCamera,
    FlashMode? flashMode,
    int? timerSeconds,
    int? activeTimerCountdown,
    bool? showGrid,
    List<Point3D>? detectedLandmarks,
    OverallMatchResult? matchResult,
    double? autoCaptureProgress,
    bool? isCapturing,
    String? lastCapturedImagePath,
    String? errorMessage,
  }) {
    return CameraViewState(
      controller: controller ?? this.controller,
      isInitialized: isInitialized ?? this.isInitialized,
      isStreaming: isStreaming ?? this.isStreaming,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      flashMode: flashMode ?? this.flashMode,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      activeTimerCountdown: activeTimerCountdown ?? this.activeTimerCountdown,
      showGrid: showGrid ?? this.showGrid,
      detectedLandmarks: detectedLandmarks ?? this.detectedLandmarks,
      matchResult: matchResult ?? this.matchResult,
      autoCaptureProgress: autoCaptureProgress ?? this.autoCaptureProgress,
      isCapturing: isCapturing ?? this.isCapturing,
      lastCapturedImagePath: lastCapturedImagePath ?? this.lastCapturedImagePath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CameraViewModel extends StateNotifier<CameraViewState> {
  final Ref _ref;
  final PoseDetectorService _detectorService;
  final GalleryRepository _galleryRepository;
  final PoseMatcher _poseMatcher = const PoseMatcher();

  List<CameraDescription> _availableCameras = [];
  Timer? _autoCaptureTimer;
  int _matchStartTimestamp = 0;
  bool _isDisposed = false;

  CameraViewModel(this._ref, this._detectorService, this._galleryRepository)
      : super(const CameraViewState()) {
    _init();
  }

  Future<void> _init() async {
    await _galleryRepository.init();
    await _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        state = state.copyWith(errorMessage: 'No camera found on device');
        return;
      }

      // Default to front selfie camera for interactive posing
      CameraDescription selectedCam = _availableCameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _availableCameras.first,
      );

      await _initializeController(selectedCam);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Camera error: $e');
    }
  }

  Future<void> _initializeController(CameraDescription description) async {
    final oldController = state.controller;
    if (oldController != null) {
      if (oldController.value.isStreamingImages) {
        await oldController.stopImageStream();
      }
      await oldController.dispose();
    }

    final newController = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await newController.initialize();
      if (_isDisposed) return;

      state = state.copyWith(
        controller: newController,
        isInitialized: true,
        isFrontCamera: description.lensDirection == CameraLensDirection.front,
      );

      _startFrameProcessing(newController, description);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to init camera: $e');
    }
  }

  void _startFrameProcessing(CameraController controller, CameraDescription camera) {
    if (!controller.value.isInitialized) return;

    controller.startImageStream((image) async {
      if (_isDisposed || !state.isInitialized) return;

      final output = await _detectorService.processCameraImage(
        cameraImage: image,
        camera: camera,
        deviceOrientation: DeviceOrientation.portraitUp,
      );

      if (output != null) {
        _ref.read(poseViewModelProvider.notifier).updateDetectedPeopleCount(output.peopleCount);

        final targetPose = _ref.read(poseViewModelProvider).currentSelectedPose;
        if (targetPose != null && output.primaryPersonLandmarks.isNotEmpty) {
          final result = _poseMatcher.evaluateMatch(
            detectedLandmarks: output.primaryPersonLandmarks,
            targetPose: targetPose,
          );

          if (!_isDisposed) {
            state = state.copyWith(
              detectedLandmarks: output.primaryPersonLandmarks,
              matchResult: result,
            );
            _handleAutoCaptureLogic(result);
          }
        } else {
          if (!_isDisposed) {
            state = state.copyWith(
              detectedLandmarks: output.primaryPersonLandmarks,
              matchResult: OverallMatchResult.empty,
              autoCaptureProgress: 0.0,
            );
            _resetAutoCapture();
          }
        }
      }
    });

    state = state.copyWith(isStreaming: true);
  }

  void _handleAutoCaptureLogic(OverallMatchResult result) {
    final settings = _ref.read(settingsViewModelProvider);
    if (!settings.autoCaptureEnabled || state.isCapturing) return;

    final threshold = settings.autoCaptureThreshold;

    if (result.score >= threshold) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_matchStartTimestamp == 0) {
        _matchStartTimestamp = now;
        HapticService.lightImpact();
      }

      final elapsed = now - _matchStartTimestamp;
      final progress = (elapsed / AppConstants.autoCaptureHoldDurationMs).clamp(0.0, 1.0);

      state = state.copyWith(autoCaptureProgress: progress);

      if (elapsed >= AppConstants.autoCaptureHoldDurationMs) {
        // Trigger Auto-Capture!
        _resetAutoCapture();
        capturePhoto();
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

  Future<void> flipCamera() async {
    if (_availableCameras.length < 2) return;
    HapticService.selectionClick();

    final nextLens = state.isFrontCamera
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    final nextCam = _availableCameras.firstWhere(
      (c) => c.lensDirection == nextLens,
      orElse: () => _availableCameras.first,
    );

    await _initializeController(nextCam);
  }

  void toggleFlash() async {
    HapticService.selectionClick();
    final controller = state.controller;
    if (controller == null) return;

    FlashMode nextMode;
    switch (state.flashMode) {
      case FlashMode.off:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
      default:
        nextMode = FlashMode.off;
        break;
    }

    try {
      await controller.setFlashMode(nextMode);
      state = state.copyWith(flashMode: nextMode);
    } catch (_) {}
  }

  void toggleTimer() {
    HapticService.selectionClick();
    int nextTimer = 0;
    if (state.timerSeconds == 0) {
      nextTimer = 3;
    } else if (state.timerSeconds == 3) {
      nextTimer = 10;
    } else {
      nextTimer = 0;
    }
    state = state.copyWith(timerSeconds: nextTimer);
  }

  void toggleGrid() {
    HapticService.selectionClick();
    state = state.copyWith(showGrid: !state.showGrid);
  }

  Future<void> capturePhoto() async {
    final controller = state.controller;
    if (controller == null || !controller.value.isInitialized || state.isCapturing) return;

    state = state.copyWith(isCapturing: true);
    HapticService.mediumImpact();

    // Handle timer delay if enabled
    if (state.timerSeconds > 0) {
      for (int i = state.timerSeconds; i > 0; i--) {
        state = state.copyWith(activeTimerCountdown: i);
        HapticService.lightImpact();
        await Future.delayed(const Duration(seconds: 1));
      }
      state = state.copyWith(activeTimerCountdown: 0);
    }

    try {
      final XFile photo = await controller.takePicture();
      HapticService.heavyImpact();

      // Save to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'pose_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = '${appDir.path}/$fileName';
      await File(photo.path).copy(savedPath);

      final currentPose = _ref.read(poseViewModelProvider).currentSelectedPose;
      final capturedPhoto = CapturedPhoto(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        filePath: savedPath,
        timestamp: DateTime.now(),
        poseName: currentPose?.name ?? 'Free Pose',
        matchScore: state.matchResult.score,
      );

      await _galleryRepository.savePhoto(capturedPhoto);

      state = state.copyWith(
        isCapturing: false,
        lastCapturedImagePath: savedPath,
      );
    } catch (e) {
      state = state.copyWith(
        isCapturing: false,
        errorMessage: 'Capture failed: $e',
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _autoCaptureTimer?.cancel();
    state.controller?.dispose();
    super.dispose();
  }
}
