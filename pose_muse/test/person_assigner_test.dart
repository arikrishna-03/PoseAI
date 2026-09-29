import 'package:flutter_test/flutter_test.dart';
import 'package:pose_muse/core/utils/angle_calculator.dart';
import 'package:pose_muse/features/coaching/domain/person_assigner.dart';
import 'package:pose_muse/features/ideas/domain/photo_idea.dart';

void main() {
  group('PersonAssigner Multi-Person Tests', () {
    test('assigns left and right detected people to corresponding target positions', () {
      // Detected person 0 on the left (x = 0.25)
      final pLeft = [const Point3D(x: 0.25, y: 0.5)];
      // Detected person 1 on the right (x = 0.75)
      final pRight = [const Point3D(x: 0.75, y: 0.5)];

      // Targets: Target 0 (left), Target 1 (right)
      final targetLeft = TargetPersonPose(
        position: 'left',
        description: 'Left person pose',
        keypoints: [const Keypoint(x: 0.25, y: 0.5)],
      );
      final targetRight = TargetPersonPose(
        position: 'right',
        description: 'Right person pose',
        keypoints: [const Keypoint(x: 0.75, y: 0.5)],
      );

      final assignments = PersonAssigner.assignPeople(
        detectedPeople: [pLeft, pRight],
        targets: [targetLeft, targetRight],
      );

      // Target 0 (left) should map to detected 0 (left)
      expect(assignments[0], equals(0));
      // Target 1 (right) should map to detected 1 (right)
      expect(assignments[1], equals(1));
    });

    test('re-assigns automatically when people swap places', () {
      // Detected person 0 is now on the RIGHT (x = 0.8)
      final pNowRight = [const Point3D(x: 0.80, y: 0.5)];
      // Detected person 1 is now on the LEFT (x = 0.20)
      final pNowLeft = [const Point3D(x: 0.20, y: 0.5)];

      // Targets: Target 0 (left), Target 1 (right)
      final targetLeft = TargetPersonPose(
        position: 'left',
        description: 'Left pose',
        keypoints: [const Keypoint(x: 0.25, y: 0.5)],
      );
      final targetRight = TargetPersonPose(
        position: 'right',
        description: 'Right pose',
        keypoints: [const Keypoint(x: 0.75, y: 0.5)],
      );

      final assignments = PersonAssigner.assignPeople(
        detectedPeople: [pNowRight, pNowLeft],
        targets: [targetLeft, targetRight],
      );

      // Target 0 (left) should now map to detected 1 (which is at x = 0.20)
      expect(assignments[0], equals(1));
      // Target 1 (right) should now map to detected 0 (which is at x = 0.80)
      expect(assignments[1], equals(0));
    });

    test('handles fewer detected people than targets gracefully', () {
      // Only 1 person detected (center)
      final pCenter = [const Point3D(x: 0.50, y: 0.5)];

      // Targets: 2 people
      final targetLeft = TargetPersonPose(
        position: 'left',
        description: 'Left pose',
        keypoints: [const Keypoint(x: 0.25, y: 0.5)],
      );
      final targetRight = TargetPersonPose(
        position: 'right',
        description: 'Right pose',
        keypoints: [const Keypoint(x: 0.75, y: 0.5)],
      );

      final assignments = PersonAssigner.assignPeople(
        detectedPeople: [pCenter],
        targets: [targetLeft, targetRight],
      );

      // Exactly one target gets assigned, the other is -1
      expect(assignments.contains(0), isTrue);
      expect(assignments.contains(-1), isTrue);
    });
  });
}
