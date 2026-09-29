import 'package:flutter_test/flutter_test.dart';
import 'package:pose_muse/core/utils/angle_calculator.dart';
import 'package:pose_muse/features/camera/domain/pose_matcher.dart';
import 'package:pose_muse/features/poses/domain/pose_category.dart';
import 'package:pose_muse/features/poses/domain/pose_model.dart';

void main() {
  group('PoseMatcher Tests', () {
    late PoseMatcher matcher;
    late PoseModel sampleTargetPose;

    setUp(() {
      matcher = const PoseMatcher(toleranceDegrees: 30.0);

      // Create a test pose with known target angles:
      // Left elbow: 90 deg, Right elbow: 90 deg, Shoulders: 45 deg, Hips: 180 deg, Knees: 180 deg
      sampleTargetPose = const PoseModel(
        id: 'test_pose_01',
        name: 'Right Angle Stance',
        category: PoseCategory.standing,
        difficulty: 'Beginner',
        peopleCount: 1,
        description: 'Test pose for unit evaluation',
        thumbnail: '',
        tags: ['test'],
        targetAngles: TargetAngles(
          leftElbow: 90.0,
          rightElbow: 90.0,
          leftShoulder: 45.0,
          rightShoulder: 45.0,
          leftHip: 180.0,
          rightHip: 180.0,
          leftKnee: 180.0,
          rightKnee: 180.0,
        ),
        landmarks: [],
      );
    });

    List<Point3D> createTestLandmarks({
      double lWristX = 0.60,
      double lWristY = 0.50,
      double scale = 1.0,
    }) {
      // 33 dummy points with key joints positioned
      final list = List<Point3D>.generate(33, (_) => const Point3D(x: 0.5, y: 0.5));

      // Shoulders: 11 (Left), 12 (Right)
      list[11] = Point3D(x: 0.60 * scale, y: 0.30 * scale);
      list[12] = Point3D(x: 0.40 * scale, y: 0.30 * scale);

      // Elbows: 13 (Left), 14 (Right)
      list[13] = Point3D(x: 0.75 * scale, y: 0.30 * scale);
      list[14] = Point3D(x: 0.25 * scale, y: 0.30 * scale);

      // Wrists: 15 (Left), 16 (Right)
      // For left elbow: Shoulder(0.60, 0.30) -> Elbow(0.75, 0.30) -> Wrist(0.75, 0.45) = 90 degrees
      list[15] = Point3D(x: (lWristX != 0.60 ? lWristX : 0.75) * scale, y: (lWristY != 0.50 ? lWristY : 0.45) * scale);
      list[16] = Point3D(x: 0.25 * scale, y: 0.45 * scale);

      // Hips: 23 (Left), 24 (Right)
      list[23] = Point3D(x: 0.58 * scale, y: 0.55 * scale);
      list[24] = Point3D(x: 0.42 * scale, y: 0.55 * scale);

      // Knees: 25 (Left), 26 (Right)
      list[25] = Point3D(x: 0.58 * scale, y: 0.75 * scale);
      list[26] = Point3D(x: 0.42 * scale, y: 0.75 * scale);

      // Ankles: 27 (Left), 28 (Right)
      list[27] = Point3D(x: 0.58 * scale, y: 0.95 * scale);
      list[28] = Point3D(x: 0.42 * scale, y: 0.95 * scale);

      return list;
    }

    test('evaluateMatch returns high score and target reached when aligned', () {
      final landmarks = createTestLandmarks();
      final result = matcher.evaluateMatch(
        detectedLandmarks: landmarks,
        targetPose: sampleTargetPose,
      );

      expect(result.score, greaterThanOrEqualTo(0.85));
      expect(result.isTargetReached, isTrue);
    });

    test('evaluateMatch is scale invariant (distance tolerant)', () {
      final normalLandmarks = createTestLandmarks(scale: 1.0);
      final scaledLandmarks = createTestLandmarks(scale: 1.8); // Person much closer to camera

      final result1 = matcher.evaluateMatch(
        detectedLandmarks: normalLandmarks,
        targetPose: sampleTargetPose,
      );

      final result2 = matcher.evaluateMatch(
        detectedLandmarks: scaledLandmarks,
        targetPose: sampleTargetPose,
      );

      // Angle based similarity must be identical regardless of distance
      expect(result1.score, closeTo(result2.score, 0.001));
    });

    test('evaluateMatch generates actionable hints when joint is mismatched', () {
      // Modify left wrist position so elbow angle is 180 deg (straight) instead of target 90 deg
      final mismatchedLandmarks = createTestLandmarks(lWristX: 0.90, lWristY: 0.30);

      final result = matcher.evaluateMatch(
        detectedLandmarks: mismatchedLandmarks,
        targetPose: sampleTargetPose,
      );

      expect(result.guidanceHints, isNotEmpty);
      expect(
        result.guidanceHints.any((h) => h.contains('left arm') || h.contains('left elbow')),
        isTrue,
      );
    });

    test('evaluateMatch returns empty result for insufficient landmarks', () {
      final result = matcher.evaluateMatch(
        detectedLandmarks: const [],
        targetPose: sampleTargetPose,
      );

      expect(result.score, equals(0.0));
      expect(result.isTargetReached, isFalse);
      expect(result.guidanceHints.first, contains('view'));
    });
  });
}
