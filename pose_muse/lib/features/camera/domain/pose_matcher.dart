import '../../../core/constants/mediapipe_landmarks.dart';
import '../../../core/utils/angle_calculator.dart';
import '../../poses/domain/pose_model.dart';
import 'match_result.dart';

class PoseMatcher {
  final double toleranceDegrees;

  const PoseMatcher({this.toleranceDegrees = 32.0});

  /// Evaluates how closely a list of detected 33 landmarks matches a target [PoseModel].
  OverallMatchResult evaluateMatch({
    required List<Point3D> detectedLandmarks,
    required PoseModel targetPose,
  }) {
    if (detectedLandmarks.length < 33) {
      return const OverallMatchResult(
        score: 0.0,
        jointMatches: [],
        guidanceHints: ['Step back into full camera view'],
        isTargetReached: false,
      );
    }

    final target = targetPose.targetAngles;
    final List<JointAngleMatch> matches = [];
    final List<String> hints = [];

    // Joint 1: Left Elbow (Shoulder 11 -> Elbow 13 -> Wrist 15)
    final lElbowAngle = AngleCalculator.calculateAngle(
      detectedLandmarks[MediaPipeLandmarks.leftShoulder],
      detectedLandmarks[MediaPipeLandmarks.leftElbow],
      detectedLandmarks[MediaPipeLandmarks.leftWrist],
    );
    final lElbowSim = AngleCalculator.computeAngleSimilarity(
      lElbowAngle,
      target.leftElbow,
      toleranceDegrees: toleranceDegrees,
    );
    String? lElbowHint;
    if (lElbowSim < 0.85) {
      lElbowHint = (lElbowAngle < target.leftElbow)
          ? 'Straighten your left arm'
          : 'Bend your left elbow more';
      hints.add(lElbowHint);
    }
    matches.add(JointAngleMatch(
      jointName: 'Left Elbow',
      observedAngle: lElbowAngle,
      targetAngle: target.leftElbow,
      similarity: lElbowSim,
      hint: lElbowHint,
    ));

    // Joint 2: Right Elbow (Shoulder 12 -> Elbow 14 -> Wrist 16)
    final rElbowAngle = AngleCalculator.calculateAngle(
      detectedLandmarks[MediaPipeLandmarks.rightShoulder],
      detectedLandmarks[MediaPipeLandmarks.rightElbow],
      detectedLandmarks[MediaPipeLandmarks.rightWrist],
    );
    final rElbowSim = AngleCalculator.computeAngleSimilarity(
      rElbowAngle,
      target.rightElbow,
      toleranceDegrees: toleranceDegrees,
    );
    String? rElbowHint;
    if (rElbowSim < 0.85) {
      rElbowHint = (rElbowAngle < target.rightElbow)
          ? 'Straighten your right arm'
          : 'Bend your right elbow more';
      hints.add(rElbowHint);
    }
    matches.add(JointAngleMatch(
      jointName: 'Right Elbow',
      observedAngle: rElbowAngle,
      targetAngle: target.rightElbow,
      similarity: rElbowSim,
      hint: rElbowHint,
    ));

    // Joint 3: Left Shoulder (Elbow 13 -> Shoulder 11 -> Hip 23)
    final lShoulderAngle = AngleCalculator.calculateAngle(
      detectedLandmarks[MediaPipeLandmarks.leftElbow],
      detectedLandmarks[MediaPipeLandmarks.leftShoulder],
      detectedLandmarks[MediaPipeLandmarks.leftHip],
    );
    final lShoulderSim = AngleCalculator.computeAngleSimilarity(
      lShoulderAngle,
      target.leftShoulder,
      toleranceDegrees: toleranceDegrees,
    );
    String? lShoulderHint;
    if (lShoulderSim < 0.85) {
      lShoulderHint = (lShoulderAngle < target.leftShoulder)
          ? 'Raise your left arm / elbow'
          : 'Lower your left arm closer to torso';
      hints.add(lShoulderHint);
    }
    matches.add(JointAngleMatch(
      jointName: 'Left Shoulder',
      observedAngle: lShoulderAngle,
      targetAngle: target.leftShoulder,
      similarity: lShoulderSim,
      hint: lShoulderHint,
    ));

    // Joint 4: Right Shoulder (Elbow 14 -> Shoulder 12 -> Hip 24)
    final rShoulderAngle = AngleCalculator.calculateAngle(
      detectedLandmarks[MediaPipeLandmarks.rightElbow],
      detectedLandmarks[MediaPipeLandmarks.rightShoulder],
      detectedLandmarks[MediaPipeLandmarks.rightHip],
    );
    final rShoulderSim = AngleCalculator.computeAngleSimilarity(
      rShoulderAngle,
      target.rightShoulder,
      toleranceDegrees: toleranceDegrees,
    );
    String? rShoulderHint;
    if (rShoulderSim < 0.85) {
      rShoulderHint = (rShoulderAngle < target.rightShoulder)
          ? 'Raise your right arm / elbow'
          : 'Lower your right arm closer to torso';
      hints.add(rShoulderHint);
    }
    matches.add(JointAngleMatch(
      jointName: 'Right Shoulder',
      observedAngle: rShoulderAngle,
      targetAngle: target.rightShoulder,
      similarity: rShoulderSim,
      hint: rShoulderHint,
    ));

    // Joint 5: Left Hip (Shoulder 11 -> Hip 23 -> Knee 25)
    final lHipAngle = AngleCalculator.calculateAngle(
      detectedLandmarks[MediaPipeLandmarks.leftShoulder],
      detectedLandmarks[MediaPipeLandmarks.leftHip],
      detectedLandmarks[MediaPipeLandmarks.leftKnee],
    );
    final lHipSim = AngleCalculator.computeAngleSimilarity(
      lHipAngle,
      target.leftHip,
      toleranceDegrees: toleranceDegrees + 8.0, // extra leniency on torso posture
    );
    String? lHipHint;
    if (lHipSim < 0.85 && lHipAngle < 140 && target.leftHip > 160) {
      lHipHint = 'Stand up a bit straighter';
      hints.add(lHipHint);
    }
    matches.add(JointAngleMatch(
      jointName: 'Left Hip',
      observedAngle: lHipAngle,
      targetAngle: target.leftHip,
      similarity: lHipSim,
      hint: lHipHint,
    ));

    // Joint 6: Right Hip (Shoulder 12 -> Hip 24 -> Knee 26)
    final rHipAngle = AngleCalculator.calculateAngle(
      detectedLandmarks[MediaPipeLandmarks.rightShoulder],
      detectedLandmarks[MediaPipeLandmarks.rightHip],
      detectedLandmarks[MediaPipeLandmarks.rightKnee],
    );
    final rHipSim = AngleCalculator.computeAngleSimilarity(
      rHipAngle,
      target.rightHip,
      toleranceDegrees: toleranceDegrees + 8.0,
    );
    String? rHipHint;
    if (rHipSim < 0.85 && rHipAngle < 140 && target.rightHip > 160) {
      rHipHint = 'Straighten posture';
      hints.add(rHipHint);
    }
    matches.add(JointAngleMatch(
      jointName: 'Right Hip',
      observedAngle: rHipAngle,
      targetAngle: target.rightHip,
      similarity: rHipSim,
      hint: rHipHint,
    ));

    // Joint 7: Left Knee (Hip 23 -> Knee 25 -> Ankle 27)
    final lKneeAngle = AngleCalculator.calculateAngle(
      detectedLandmarks[MediaPipeLandmarks.leftHip],
      detectedLandmarks[MediaPipeLandmarks.leftKnee],
      detectedLandmarks[MediaPipeLandmarks.leftAnkle],
    );
    final lKneeSim = AngleCalculator.computeAngleSimilarity(
      lKneeAngle,
      target.leftKnee,
      toleranceDegrees: toleranceDegrees,
    );
    String? lKneeHint;
    if (lKneeSim < 0.85) {
      lKneeHint = (lKneeAngle < target.leftKnee)
          ? 'Straighten your left leg'
          : 'Bend your left knee slightly';
      hints.add(lKneeHint);
    }
    matches.add(JointAngleMatch(
      jointName: 'Left Knee',
      observedAngle: lKneeAngle,
      targetAngle: target.leftKnee,
      similarity: lKneeSim,
      hint: lKneeHint,
    ));

    // Joint 8: Right Knee (Hip 24 -> Knee 26 -> Ankle 28)
    final rKneeAngle = AngleCalculator.calculateAngle(
      detectedLandmarks[MediaPipeLandmarks.rightHip],
      detectedLandmarks[MediaPipeLandmarks.rightKnee],
      detectedLandmarks[MediaPipeLandmarks.rightAnkle],
    );
    final rKneeSim = AngleCalculator.computeAngleSimilarity(
      rKneeAngle,
      target.rightKnee,
      toleranceDegrees: toleranceDegrees,
    );
    String? rKneeHint;
    if (rKneeSim < 0.85) {
      rKneeHint = (rKneeAngle < target.rightKnee)
          ? 'Straighten your right leg'
          : 'Bend your right knee slightly';
      hints.add(rKneeHint);
    }
    matches.add(JointAngleMatch(
      jointName: 'Right Knee',
      observedAngle: rKneeAngle,
      targetAngle: target.rightKnee,
      similarity: rKneeSim,
      hint: rKneeHint,
    ));

    // Weighted average: Arms (elbows & shoulders) carry 60% of pose expressiveness, legs & torso 40%
    final double upperBodyScore = (lElbowSim + rElbowSim + lShoulderSim + rShoulderSim) / 4.0;
    final double lowerBodyScore = (lHipSim + rHipSim + lKneeSim + rKneeSim) / 4.0;
    final double overallScore = (upperBodyScore * 0.60) + (lowerBodyScore * 0.40);

    return OverallMatchResult(
      score: overallScore.clamp(0.0, 1.0),
      jointMatches: matches,
      guidanceHints: hints,
      isTargetReached: overallScore >= 0.85,
    );
  }
}
