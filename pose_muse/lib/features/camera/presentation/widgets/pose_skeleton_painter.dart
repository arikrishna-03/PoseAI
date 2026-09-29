import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/mediapipe_landmarks.dart';
import '../../../../core/utils/angle_calculator.dart';
import '../../../poses/domain/pose_model.dart';

class PoseSkeletonPainter extends CustomPainter {
  final List<Point3D>? detectedLandmarks;
  final PoseModel? targetPose;
  final double matchScore; // 0.0 to 1.0
  final bool isFrontCamera;

  PoseSkeletonPainter({
    required this.detectedLandmarks,
    required this.targetPose,
    required this.matchScore,
    required this.isFrontCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Target Ghost Skeleton first (behind user)
    if (targetPose != null && targetPose!.landmarks.isNotEmpty) {
      _drawGhostSkeleton(canvas, size, targetPose!.landmarks);
    }

    // 2. Draw Detected User Skeleton (on top)
    if (detectedLandmarks != null && detectedLandmarks!.isNotEmpty) {
      _drawDetectedSkeleton(canvas, size, detectedLandmarks!);
    }
  }

  void _drawGhostSkeleton(Canvas canvas, Size size, List<Point3D> landmarks) {
    final bonePaint = Paint()
      ..color = AppColors.ghostSkeletonBone
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final jointPaint = Paint()
      ..color = AppColors.ghostSkeletonJoint
      ..style = PaintingStyle.fill;

    // Draw bones
    for (final connection in MediaPipeLandmarks.skeletonConnections) {
      final idx1 = connection[0];
      final idx2 = connection[1];
      if (idx1 < landmarks.length && idx2 < landmarks.length) {
        final p1 = _mapPoint(landmarks[idx1], size);
        final p2 = _mapPoint(landmarks[idx2], size);
        canvas.drawLine(p1, p2, bonePaint);
      }
    }

    // Draw joint nodes
    for (int i = 0; i < landmarks.length; i++) {
      if (i > 10 && i < 29) {
        // focus on major body joints
        final p = _mapPoint(landmarks[i], size);
        canvas.drawCircle(p, 5.0, jointPaint);
      }
    }
  }

  void _drawDetectedSkeleton(Canvas canvas, Size size, List<Point3D> landmarks) {
    final dynamicColor = AppColors.matchColor(matchScore);

    // Glow effect paint for high matches
    final glowPaint = Paint()
      ..color = dynamicColor.withOpacity(0.35)
      ..strokeWidth = 9.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final bonePaint = Paint()
      ..color = dynamicColor
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final jointFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final jointRingPaint = Paint()
      ..color = dynamicColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Draw bones
    for (final connection in MediaPipeLandmarks.skeletonConnections) {
      final idx1 = connection[0];
      final idx2 = connection[1];
      if (idx1 < landmarks.length && idx2 < landmarks.length) {
        final lm1 = landmarks[idx1];
        final lm2 = landmarks[idx2];

        // Draw only if confidence is reasonable
        if (lm1.visibility > 0.4 && lm2.visibility > 0.4) {
          final p1 = _mapPoint(lm1, size);
          final p2 = _mapPoint(lm2, size);

          if (matchScore >= 0.85) {
            canvas.drawLine(p1, p2, glowPaint);
          }
          canvas.drawLine(p1, p2, bonePaint);
        }
      }
    }

    // Draw joint dots
    for (int i = 0; i < landmarks.length; i++) {
      final lm = landmarks[i];
      if (lm.visibility > 0.4 && i > 10 && i < 29) {
        final p = _mapPoint(lm, size);
        canvas.drawCircle(p, 6.0, jointFillPaint);
        canvas.drawCircle(p, 6.0, jointRingPaint);
      }
    }
  }

  Offset _mapPoint(Point3D point, Size size) {
    double x = point.x * size.width;
    double y = point.y * size.height;

    if (isFrontCamera) {
      // Mirror horizontal axis for front selfie camera
      x = size.width - x;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant PoseSkeletonPainter oldDelegate) {
    return oldDelegate.detectedLandmarks != detectedLandmarks ||
        oldDelegate.targetPose != targetPose ||
        oldDelegate.matchScore != matchScore ||
        oldDelegate.isFrontCamera != isFrontCamera;
  }
}
