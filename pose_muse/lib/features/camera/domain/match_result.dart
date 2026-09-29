import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class JointAngleMatch {
  final String jointName;
  final double observedAngle;
  final double targetAngle;
  final double similarity; // 0.0 to 1.0
  final String? hint;

  const JointAngleMatch({
    required this.jointName,
    required this.observedAngle,
    required this.targetAngle,
    required this.similarity,
    this.hint,
  });

  bool get isMatched => similarity >= 0.85;
}

class OverallMatchResult {
  final double score; // 0.0 to 1.0
  final List<JointAngleMatch> jointMatches;
  final List<String> guidanceHints;
  final bool isTargetReached; // >= 0.85

  const OverallMatchResult({
    required this.score,
    required this.jointMatches,
    required this.guidanceHints,
    required this.isTargetReached,
  });

  static const empty = OverallMatchResult(
    score: 0.0,
    jointMatches: [],
    guidanceHints: ['Position your body in camera view'],
    isTargetReached: false,
  );

  Color get feedbackColor => AppColors.matchColor(score);

  String get primaryHint {
    if (guidanceHints.isEmpty) {
      if (isTargetReached) return 'Hold steady! Capturing...';
      return 'Great alignment! Hold pose';
    }
    return guidanceHints.first;
  }
}
