import 'dart:math' as math;

class Point3D {
  final double x;
  final double y;
  final double z;
  final double visibility;

  const Point3D({
    required this.x,
    required this.y,
    this.z = 0.0,
    this.visibility = 1.0,
  });

  factory Point3D.fromJson(Map<String, dynamic> json) {
    return Point3D(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: (json['z'] as num?)?.toDouble() ?? 0.0,
      visibility: (json['visibility'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'z': z,
        'visibility': visibility,
      };

  @override
  String toString() => 'Point3D(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)})';
}

class AngleCalculator {
  /// Computes the angle in degrees [0, 180] at vertex joint `b` formed by points `a` -> `b` -> `c`.
  static double calculateAngle(Point3D a, Point3D b, Point3D c) {
    // Vector BA (from b to a)
    final double v1x = a.x - b.x;
    final double v1y = a.y - b.y;

    // Vector BC (from b to c)
    final double v2x = c.x - b.x;
    final double v2y = c.y - b.y;

    // Dot product
    final double dot = (v1x * v2x) + (v1y * v2y);

    // Magnitudes
    final double mag1 = math.sqrt((v1x * v1x) + (v1y * v1y));
    final double mag2 = math.sqrt((v2x * v2x) + (v2y * v2y));

    // Avoid division by zero
    if (mag1 < 1e-6 || mag2 < 1e-6) {
      return 0.0;
    }

    double cosTheta = dot / (mag1 * mag2);
    // Clamp to valid range [-1.0, 1.0] for acos
    if (cosTheta > 1.0) cosTheta = 1.0;
    if (cosTheta < -1.0) cosTheta = -1.0;

    final double radians = math.acos(cosTheta);
    return radians * (180.0 / math.pi);
  }

  /// Calculates the similarity score [0.0, 1.0] between an observed angle and target angle,
  /// with a configurable tolerance window in degrees (e.g. 25 degrees).
  static double computeAngleSimilarity(
    double observedAngle,
    double targetAngle, {
    double toleranceDegrees = 30.0,
  }) {
    final double diff = (observedAngle - targetAngle).abs();
    if (diff <= 5.0) return 1.0; // Near perfect match within 5 degrees
    if (diff >= toleranceDegrees) return 0.0; // Outside tolerance

    // Linear decay from 1.0 to 0.0 within tolerance
    return 1.0 - ((diff - 5.0) / (toleranceDegrees - 5.0));
  }

  /// Calculates the inclination angle of a line formed by two points relative to the horizontal axis.
  static double calculateInclination(Point3D p1, Point3D p2) {
    final double dx = p2.x - p1.x;
    final double dy = p2.y - p1.y;
    final double radians = math.atan2(dy, dx);
    double degrees = radians * (180.0 / math.pi);
    if (degrees < 0) degrees += 360.0;
    return degrees;
  }
}
