import 'package:flutter_test/flutter_test.dart';
import 'package:pose_muse/core/utils/angle_calculator.dart';
import 'package:pose_muse/features/coaching/domain/pose_matcher.dart';
import 'package:pose_muse/features/ideas/domain/photo_idea.dart';

void main() {
  group('COCO 17 PoseMatcher Tests', () {
    late PoseMatcher matcher;
    late TargetPersonPose sampleTarget;

    setUp(() {
      matcher = const PoseMatcher(toleranceDegrees: 30.0);

      // Create a 17-point COCO target pose
      // 0: nose, 1: l_eye, 2: r_eye, 3: l_ear, 4: r_ear
      // 5: l_shoulder, 6: r_shoulder, 7: l_elbow, 8: r_elbow, 9: l_wrist, 10: r_wrist
      // 11: l_hip, 12: r_hip, 13: l_knee, 14: r_knee, 15: l_ankle, 16: r_ankle
      final points = List.generate(17, (_) => const Keypoint(x: 0.5, y: 0.5));
      points[5] = const Keypoint(x: 0.60, y: 0.30); // Left Shoulder
      points[6] = const Keypoint(x: 0.40, y: 0.30); // Right Shoulder
      points[7] = const Keypoint(x: 0.75, y: 0.30); // Left Elbow
      points[8] = const Keypoint(x: 0.25, y: 0.30); // Right Elbow
      points[9] = const Keypoint(x: 0.75, y: 0.45); // Left Wrist (90 deg at elbow)
      points[10] = const Keypoint(x: 0.25, y: 0.45); // Right Wrist (90 deg at elbow)
      points[11] = const Keypoint(x: 0.58, y: 0.55); // Left Hip
      points[12] = const Keypoint(x: 0.42, y: 0.55); // Right Hip
      points[13] = const Keypoint(x: 0.58, y: 0.75); // Left Knee
      points[14] = const Keypoint(x: 0.42, y: 0.75); // Right Knee
      points[15] = const Keypoint(x: 0.58, y: 0.95); // Left Ankle
      points[16] = const Keypoint(x: 0.42, y: 0.95); // Right Ankle

      sampleTarget = TargetPersonPose(
        position: 'center',
        description: 'Standing arms bent at right angles',
        keypoints: points,
      );
    });

    List<Point3D> createTestLandmarks({
      double lWristX = 0.75,
      double lWristY = 0.45,
      double scale = 1.0,
    }) {
      final list = List.generate(17, (_) => const Point3D(x: 0.5, y: 0.5));
      list[5] = Point3D(x: 0.60 * scale, y: 0.30 * scale);
      list[6] = Point3D(x: 0.40 * scale, y: 0.30 * scale);
      list[7] = Point3D(x: 0.75 * scale, y: 0.30 * scale);
      list[8] = Point3D(x: 0.25 * scale, y: 0.30 * scale);
      list[9] = Point3D(x: lWristX * scale, y: lWristY * scale);
      list[10] = Point3D(x: 0.25 * scale, y: 0.45 * scale);
      list[11] = Point3D(x: 0.58 * scale, y: 0.55 * scale);
      list[12] = Point3D(x: 0.42 * scale, y: 0.55 * scale);
      list[13] = Point3D(x: 0.58 * scale, y: 0.75 * scale);
      list[14] = Point3D(x: 0.42 * scale, y: 0.75 * scale);
      list[15] = Point3D(x: 0.58 * scale, y: 0.95 * scale);
      list[16] = Point3D(x: 0.42 * scale, y: 0.95 * scale);
      return list;
    }

    test('evaluateSinglePerson returns high score and target reached when aligned', () {
      final detected = createTestLandmarks();
      final result = matcher.evaluateSinglePerson(
        detected: detected,
        targetPose: sampleTarget,
      );

      expect(result.score, greaterThanOrEqualTo(0.85));
      expect(result.isTargetReached, isTrue);
    });

    test('evaluateSinglePerson is scale invariant (tolerant to camera distance)', () {
      final normal = createTestLandmarks(scale: 1.0);
      final scaled = createTestLandmarks(scale: 1.6); // Person 60% closer to camera

      final result1 = matcher.evaluateSinglePerson(detected: normal, targetPose: sampleTarget);
      final result2 = matcher.evaluateSinglePerson(detected: scaled, targetPose: sampleTarget);

      expect(result1.score, closeTo(result2.score, 0.001));
    });

    test('evaluateSinglePerson generates directional hint when arm is misplaced', () {
      // Move left wrist so left elbow is straight (180 deg) instead of 90 deg
      final misplaced = createTestLandmarks(lWristX: 0.90, lWristY: 0.30);

      final result = matcher.evaluateSinglePerson(detected: misplaced, targetPose: sampleTarget);

      expect(result.hints, isNotEmpty);
      expect(result.hints.any((h) => h.contains('left arm') || h.contains('left elbow')), isTrue);
    });

    test('evaluateGroup computes overall average across multiple subjects', () {
      final p1 = createTestLandmarks();
      final p2 = createTestLandmarks();

      final group = matcher.evaluateGroup(
        detectedPeople: [p1, p2],
        targetPoses: [sampleTarget, sampleTarget],
        personAssignments: [0, 1],
      );

      expect(group.overallScore, greaterThanOrEqualTo(0.85));
      expect(group.allTargetsReached, isTrue);
    });
  });
}
