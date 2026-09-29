import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/coco_landmarks.dart';
import '../../../../core/utils/angle_calculator.dart';
import '../../ideas/domain/photo_idea.dart';

class MultiPersonSkeletonPainter extends CustomPainter {
  final List<TargetPersonPose> targets;
  final List<List<Point3D>> detectedPeople;
  final List<int> personAssignments;
  final List<double> personScores; // match score for each target
  final bool isFrontCamera;

  MultiPersonSkeletonPainter({
    required this.targets,
    required this.detectedPeople,
    required this.personAssignments,
    required this.personScores,
    required this.isFrontCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Target Ghost Skeletons
    for (int tIdx = 0; tIdx < targets.length; tIdx++) {
      final target = targets[tIdx];
      if (target.keypoints.length >= 17) {
        _drawGhostSkeleton(canvas, size, target);
      }
    }

    // 2. Draw Detected User Skeletons with dynamic matching colors
    for (int tIdx = 0; tIdx < targets.length; tIdx++) {
      final dIdx = personAssignments.length > tIdx ? personAssignments[tIdx] : -1;
      if (dIdx >= 0 && dIdx < detectedPeople.length) {
        final detected = detectedPeople[dIdx];
        final score = personScores.length > tIdx ? personScores[tIdx] : 0.0;
        _drawDetectedPerson(canvas, size, detected, score, targets[tIdx].position);
      }
    }
  }

  void _drawGhostSkeleton(Canvas canvas, Size size, TargetPersonPose target) {
    final bonePaint = Paint()
      ..color = AppColors.ghostSkeletonBone
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final jointPaint = Paint()
      ..color = AppColors.ghostSkeletonJoint
      ..style = PaintingStyle.fill;

    for (final conn in CocoLandmarks.skeletonConnections) {
      final p1 = _mapOffset(target.keypoints[conn[0]].x, target.keypoints[conn[0]].y, size);
      final p2 = _mapOffset(target.keypoints[conn[1]].x, target.keypoints[conn[1]].y, size);
      canvas.drawLine(p1, p2, bonePaint);
    }

    for (final pt in target.keypoints) {
      final p = _mapOffset(pt.x, pt.y, size);
      canvas.drawCircle(p, 5.0, jointPaint);
    }
  }

  void _drawDetectedPerson(
    Canvas canvas,
    Size size,
    List<Point3D> keypoints,
    double score,
    String positionLabel,
  ) {
    final color = AppColors.matchColor(score);

    final glowPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round;

    final bonePaint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final jointFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final jointRing = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final conn in CocoLandmarks.skeletonConnections) {
      final pt1 = keypoints[conn[0]];
      final pt2 = keypoints[conn[1]];
      if (pt1.visibility > 0.3 && pt2.visibility > 0.3) {
        final p1 = _mapOffset(pt1.x, pt1.y, size);
        final p2 = _mapOffset(pt2.x, pt2.y, size);
        if (score >= 0.85) {
          canvas.drawLine(p1, p2, glowPaint);
        }
        canvas.drawLine(p1, p2, bonePaint);
      }
    }

    for (final pt in keypoints) {
      if (pt.visibility > 0.3) {
        final p = _mapOffset(pt.x, pt.y, size);
        canvas.drawCircle(p, 6.0, jointFill);
        canvas.drawCircle(p, 6.0, jointRing);
      }
    }
  }

  Offset _mapOffset(double normX, double normY, Size size) {
    double x = normX * size.width;
    double y = normY * size.height;
    if (isFrontCamera) {
      x = size.width - x;
    }
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant MultiPersonSkeletonPainter oldDelegate) {
    return true; // repaint on stream updates
  }
}
