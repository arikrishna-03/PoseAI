import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/angle_calculator.dart';
import '../../../core/utils/image_converter.dart';

class DetectionFrameOutput {
  final List<Point3D> primaryPersonLandmarks;
  final int peopleCount;
  final Size imageSize;
  final InputImageRotation rotation;

  const DetectionFrameOutput({
    required this.primaryPersonLandmarks,
    required this.peopleCount,
    required this.imageSize,
    required this.rotation,
  });

  static const empty = DetectionFrameOutput(
    primaryPersonLandmarks: [],
    peopleCount: 0,
    imageSize: Size.zero,
    rotation: InputImageRotation.rotation0deg,
  );
}

class PoseDetectorService {
  late final PoseDetector _poseDetector;
  bool _isProcessing = false;
  int _lastProcessTimestamp = 0;

  PoseDetectorService() {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    );
    _poseDetector = PoseDetector(options: options);
  }

  /// Processes a live camera frame, throttling to ~15 FPS.
  Future<DetectionFrameOutput?> processCameraImage({
    required CameraImage cameraImage,
    required CameraDescription camera,
    required DeviceOrientation deviceOrientation,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_isProcessing || (now - _lastProcessTimestamp < AppConstants.detectionThrottleMs)) {
      return null; // Throttle or drop frame if busy
    }

    _isProcessing = true;
    _lastProcessTimestamp = now;

    try {
      final inputImage = ImageConverter.inputImageFromCameraImage(
        image: cameraImage,
        camera: camera,
        deviceOrientation: deviceOrientation,
      );

      if (inputImage == null || inputImage.metadata == null) {
        _isProcessing = false;
        return null;
      }

      final List<Pose> detectedPoses = await _poseDetector.processImage(inputImage);

      if (detectedPoses.isEmpty) {
        _isProcessing = false;
        return DetectionFrameOutput(
          primaryPersonLandmarks: [],
          peopleCount: 0,
          imageSize: inputImage.metadata!.size,
          rotation: inputImage.metadata!.rotation,
        );
      }

      // Multi-person handling: Select the primary person (largest bounding box / highest landmark count)
      Pose primaryPose = detectedPoses.first;
      if (detectedPoses.length > 1) {
        double maxArea = -1;
        for (final pose in detectedPoses) {
          final box = _calculateBoundingBox(pose);
          final area = box.width * box.height;
          if (area > maxArea) {
            maxArea = area;
            primaryPose = pose;
          }
        }
      }

      // Normalize landmarks to [0.0, 1.0] relative to image dimensions
      final imgW = inputImage.metadata!.size.width;
      final imgH = inputImage.metadata!.size.height;

      final List<Point3D> normalizedLandmarks = List.generate(33, (index) {
        final landmarkType = PoseLandmarkType.values[index];
        final lm = primaryPose.landmarks[landmarkType];
        if (lm == null) {
          return const Point3D(x: 0, y: 0, z: 0, visibility: 0);
        }
        return Point3D(
          x: (lm.x / imgW).clamp(0.0, 1.0),
          y: (lm.y / imgH).clamp(0.0, 1.0),
          z: lm.z / imgW,
          visibility: lm.likelihood,
        );
      });

      _isProcessing = false;
      return DetectionFrameOutput(
        primaryPersonLandmarks: normalizedLandmarks,
        peopleCount: detectedPoses.length,
        imageSize: inputImage.metadata!.size,
        rotation: inputImage.metadata!.rotation,
      );
    } catch (e) {
      _isProcessing = false;
      return null;
    }
  }

  Rect _calculateBoundingBox(Pose pose) {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final lm in pose.landmarks.values) {
      if (lm.x < minX) minX = lm.x;
      if (lm.y < minY) minY = lm.y;
      if (lm.x > maxX) maxX = lm.x;
      if (lm.y > maxY) maxY = lm.y;
    }

    if (minX == double.infinity) return Rect.zero;
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Future<void> dispose() async {
    await _poseDetector.close();
  }
}
