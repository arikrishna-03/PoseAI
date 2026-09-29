import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:pose_muse/core/utils/angle_calculator.dart';

void main() {
  group('AngleCalculator Tests', () {
    test('calculateAngle returns 90 degrees for right angle triangle', () {
      const a = Point3D(x: 0, y: 1); // Up
      const b = Point3D(x: 0, y: 0); // Vertex
      const c = Point3D(x: 1, y: 0); // Right

      final angle = AngleCalculator.calculateAngle(a, b, c);
      expect(angle, closeTo(90.0, 0.001));
    });

    test('calculateAngle returns 180 degrees for straight line', () {
      const a = Point3D(x: -1, y: 0); // Left
      const b = Point3D(x: 0, y: 0);  // Vertex
      const c = Point3D(x: 1, y: 0);  // Right

      final angle = AngleCalculator.calculateAngle(a, b, c);
      expect(angle, closeTo(180.0, 0.001));
    });

    test('calculateAngle returns 0 or acute angle for acute vectors', () {
      const a = Point3D(x: 1, y: 1);
      const b = Point3D(x: 0, y: 0);
      const c = Point3D(x: 1, y: 0);

      final angle = AngleCalculator.calculateAngle(a, b, c);
      expect(angle, closeTo(45.0, 0.001));
    });

    test('calculateAngle handles zero distance gracefully without crashing', () {
      const a = Point3D(x: 0, y: 0);
      const b = Point3D(x: 0, y: 0);
      const c = Point3D(x: 1, y: 0);

      final angle = AngleCalculator.calculateAngle(a, b, c);
      expect(angle, equals(0.0));
    });

    test('computeAngleSimilarity returns 1.0 within 5 degrees difference', () {
      final sim = AngleCalculator.computeAngleSimilarity(90.0, 93.0);
      expect(sim, equals(1.0));
    });

    test('computeAngleSimilarity returns 0.0 when exceeding tolerance', () {
      final sim = AngleCalculator.computeAngleSimilarity(90.0, 130.0, toleranceDegrees: 30.0);
      expect(sim, equals(0.0));
    });

    test('computeAngleSimilarity smoothly decays between 5 degrees and tolerance', () {
      final sim = AngleCalculator.computeAngleSimilarity(90.0, 105.0, toleranceDegrees: 30.0);
      expect(sim, greaterThan(0.0));
      expect(sim, lessThan(1.0));
      expect(sim, closeTo(0.6, 0.05));
    });
  });
}
