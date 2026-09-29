import 'dart:math' as math;
import '../../../core/utils/angle_calculator.dart';
import '../../ideas/domain/photo_idea.dart';

class PersonAssigner {
  /// Assigns each target pose index (0 .. targets.length-1) to the best matching detected person index.
  /// Returns a list of length `targets.length`, where `result[tIdx]` is the index of the detected person,
  /// or -1 if no person was assigned.
  static List<int> assignPeople({
    required List<List<Point3D>> detectedPeople,
    required List<TargetPersonPose> targets,
  }) {
    if (targets.isEmpty || detectedPeople.isEmpty) {
      return List.filled(targets.length, -1);
    }

    // Compute centroid (average X, Y) for each detected person
    final List<Point3D> detectedCentroids = detectedPeople.map((person) {
      if (person.isEmpty) return const Point3D(x: 0.5, y: 0.5);
      double sumX = 0;
      double sumY = 0;
      int count = 0;
      for (final pt in person) {
        if (pt.visibility > 0.3) {
          sumX += pt.x;
          sumY += pt.y;
          count++;
        }
      }
      return count > 0
          ? Point3D(x: sumX / count, y: sumY / count)
          : const Point3D(x: 0.5, y: 0.5);
    }).toList();

    // Compute centroid for each target person pose
    final List<Point3D> targetCentroids = targets.map((t) {
      if (t.keypoints.isEmpty) {
        // Fallback by position enum
        double x = 0.5;
        if (t.position == 'left') x = 0.25;
        if (t.position == 'right') x = 0.75;
        return Point3D(x: x, y: 0.5);
      }
      double sumX = 0;
      double sumY = 0;
      for (final pt in t.keypoints) {
        sumX += pt.x;
        sumY += pt.y;
      }
      return Point3D(x: sumX / t.keypoints.length, y: sumY / t.keypoints.length);
    }).toList();

    // Build cost matrix based on spatial distance (weighted horizontally)
    final numTargets = targets.length;
    final numDetected = detectedPeople.length;
    final List<List<double>> costMatrix = List.generate(
      numTargets,
      (t) => List.generate(numDetected, (d) {
        final tPt = targetCentroids[t];
        final dPt = detectedCentroids[d];
        final dx = (tPt.x - dPt.x).abs();
        final dy = (tPt.y - dPt.y).abs();
        // Weight horizontal position heavily to resolve left/center/right swaps
        return (dx * 2.0) + dy;
      }),
    );

    // Greedy bipartite matching with lowest cost first
    final List<int> assignment = List.filled(numTargets, -1);
    final Set<int> usedDetected = {};

    // Create sorted list of pairs by cost
    final List<_TargetDetectedPair> pairs = [];
    for (int t = 0; t < numTargets; t++) {
      for (int d = 0; d < numDetected; d++) {
        pairs.add(_TargetDetectedPair(t: t, d: d, cost: costMatrix[t][d]));
      }
    }
    pairs.sort((a, b) => a.cost.compareTo(b.cost));

    for (final pair in pairs) {
      if (assignment[pair.t] == -1 && !usedDetected.contains(pair.d)) {
        assignment[pair.t] = pair.d;
        usedDetected.add(pair.d);
      }
    }

    return assignment;
  }
}

class _TargetDetectedPair {
  final int t;
  final int d;
  final double cost;
  _TargetDetectedPair({required this.t, required this.d, required this.cost});
}
