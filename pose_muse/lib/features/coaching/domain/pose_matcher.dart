import '../../../core/constants/coco_landmarks.dart';
import '../../../core/utils/angle_calculator.dart';
import '../../ideas/domain/photo_idea.dart';

class CocoJointMatch {
  final String jointName;
  final double observedAngle;
  final double targetAngle;
  final double similarity; // 0.0 to 1.0
  final String? hint;

  const CocoJointMatch({
    required this.jointName,
    required this.observedAngle,
    required this.targetAngle,
    required this.similarity,
    this.hint,
  });

  bool get isMatched => similarity >= 0.85;
}

class PersonMatchResult {
  final String personPosition; // left | center | right
  final double score; // 0.0 to 1.0
  final List<CocoJointMatch> jointMatches;
  final List<String> hints;
  final bool isTargetReached; // >= 0.85

  const PersonMatchResult({
    required this.personPosition,
    required this.score,
    required this.jointMatches,
    required this.hints,
    required this.isTargetReached,
  });

  static const empty = PersonMatchResult(
    personPosition: 'center',
    score: 0.0,
    jointMatches: [],
    hints: ['Step into frame'],
    isTargetReached: false,
  );

  String get primaryHint => hints.isNotEmpty ? hints.first : (isTargetReached ? 'Hold steady! Capturing...' : 'Align pose');
}

class GroupMatchResult {
  final double overallScore; // Average across all targeted people
  final List<PersonMatchResult> personResults;
  final bool allTargetsReached;

  const GroupMatchResult({
    required this.overallScore,
    required this.personResults,
    required this.allTargetsReached,
  });

  static const empty = GroupMatchResult(
    overallScore: 0.0,
    personResults: [],
    allTargetsReached: false,
  );
}

class PoseMatcher {
  final double toleranceDegrees;

  const PoseMatcher({this.toleranceDegrees = 32.0});

  /// Evaluates how closely detected 17-point keypoints match a target person pose
  PersonMatchResult evaluateSinglePerson({
    required List<Point3D> detected,
    required TargetPersonPose targetPose,
  }) {
    if (detected.length < 17 || targetPose.keypoints.length < 17) {
      return PersonMatchResult(
        personPosition: targetPose.position,
        score: 0.0,
        jointMatches: const [],
        hints: const ['Step into camera view'],
        isTargetReached: false,
      );
    }

    final target = targetPose.keypoints;
    final List<CocoJointMatch> matches = [];
    final List<String> hints = [];

    // Helper to evaluate a joint triplet
    void evaluateJoint(String name, int a, int b, int c, String raiseHint, String lowerHint, {double extraTolerance = 0}) {
      final obs = AngleCalculator.calculateAngle(detected[a], detected[b], detected[c]);
      final tgtPtA = Point3D(x: target[a].x, y: target[a].y);
      final tgtPtB = Point3D(x: target[b].x, y: target[b].y);
      final tgtPtC = Point3D(x: target[c].x, y: target[c].y);
      final tgt = AngleCalculator.calculateAngle(tgtPtA, tgtPtB, tgtPtC);

      final sim = AngleCalculator.computeAngleSimilarity(obs, tgt, toleranceDegrees: toleranceDegrees + extraTolerance);
      String? hint;
      if (sim < 0.85) {
        hint = (obs < tgt) ? raiseHint : lowerHint;
        hints.add(hint);
      }
      matches.add(CocoJointMatch(
        jointName: name,
        observedAngle: obs,
        targetAngle: tgt,
        similarity: sim,
        hint: hint,
      ));
    }

    // 1. Left Elbow (5 -> 7 -> 9)
    evaluateJoint('Left Elbow', CocoLandmarks.leftShoulder, CocoLandmarks.leftElbow, CocoLandmarks.leftWrist, 'Straighten left arm', 'Bend left elbow more');

    // 2. Right Elbow (6 -> 8 -> 10)
    evaluateJoint('Right Elbow', CocoLandmarks.rightShoulder, CocoLandmarks.rightElbow, CocoLandmarks.rightWrist, 'Straighten right arm', 'Bend right elbow more');

    // 3. Left Shoulder (7 -> 5 -> 11)
    evaluateJoint('Left Shoulder', CocoLandmarks.leftElbow, CocoLandmarks.leftShoulder, CocoLandmarks.leftHip, 'Raise left arm higher', 'Lower left arm closer to body');

    // 4. Right Shoulder (8 -> 6 -> 12)
    evaluateJoint('Right Shoulder', CocoLandmarks.rightElbow, CocoLandmarks.rightShoulder, CocoLandmarks.rightHip, 'Raise right arm higher', 'Lower right arm closer to body');

    // 5. Left Hip (5 -> 11 -> 13)
    evaluateJoint('Left Hip', CocoLandmarks.leftShoulder, CocoLandmarks.leftHip, CocoLandmarks.leftKnee, 'Straighten posture', 'Bend at hips slightly', extraTolerance: 8.0);

    // 6. Right Hip (6 -> 12 -> 14)
    evaluateJoint('Right Hip', CocoLandmarks.rightShoulder, CocoLandmarks.rightHip, CocoLandmarks.rightKnee, 'Straighten posture', 'Bend at hips slightly', extraTolerance: 8.0);

    // 7. Left Knee (11 -> 13 -> 15)
    evaluateJoint('Left Knee', CocoLandmarks.leftHip, CocoLandmarks.leftKnee, CocoLandmarks.leftAnkle, 'Straighten left leg', 'Bend left knee slightly');

    // 8. Right Knee (12 -> 14 -> 16)
    evaluateJoint('Right Knee', CocoLandmarks.rightHip, CocoLandmarks.rightKnee, CocoLandmarks.rightAnkle, 'Straighten right leg', 'Bend right knee slightly');

    // Upper body (arms/shoulders) 60%, Lower body (hips/knees) 40%
    final double upper = (matches[0].similarity + matches[1].similarity + matches[2].similarity + matches[3].similarity) / 4.0;
    final double lower = (matches[4].similarity + matches[5].similarity + matches[6].similarity + matches[7].similarity) / 4.0;
    final double score = ((upper * 0.60) + (lower * 0.40)).clamp(0.0, 1.0);

    return PersonMatchResult(
      personPosition: targetPose.position,
      score: score,
      jointMatches: matches,
      hints: hints,
      isTargetReached: score >= 0.85,
    );
  }

  /// Evaluates multi-person match score across a group
  GroupMatchResult evaluateGroup({
    required List<List<Point3D>> detectedPeople,
    required List<TargetPersonPose> targetPoses,
    required List<int> personAssignments,
  }) {
    if (targetPoses.isEmpty) return GroupMatchResult.empty;

    final List<PersonMatchResult> results = [];
    double totalScore = 0.0;

    for (int tIdx = 0; tIdx < targetPoses.length; tIdx++) {
      final target = targetPoses[tIdx];
      // Check which detected person is assigned to target tIdx
      final int dIdx = personAssignments.length > tIdx ? personAssignments[tIdx] : -1;

      if (dIdx >= 0 && dIdx < detectedPeople.length) {
        final pResult = evaluateSinglePerson(
          detected: detectedPeople[dIdx],
          targetPose: target,
        );
        results.add(pResult);
        totalScore += pResult.score;
      } else {
        results.add(PersonMatchResult(
          personPosition: target.position,
          score: 0.0,
          jointMatches: const [],
          hints: ['Waiting for person (${target.position})'],
          isTargetReached: false,
        ));
      }
    }

    final double groupScore = (totalScore / targetPoses.length).clamp(0.0, 1.0);
    final bool allReached = results.every((r) => r.isTargetReached);

    return GroupMatchResult(
      overallScore: groupScore,
      personResults: results,
      allTargetsReached: allReached,
    );
  }
}
