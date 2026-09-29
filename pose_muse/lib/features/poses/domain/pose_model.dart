import '../../../core/utils/angle_calculator.dart';
import 'pose_category.dart';

class TargetAngles {
  final double leftElbow;
  final double rightElbow;
  final double leftShoulder;
  final double rightShoulder;
  final double leftHip;
  final double rightHip;
  final double leftKnee;
  final double rightKnee;

  const TargetAngles({
    required this.leftElbow,
    required this.rightElbow,
    required this.leftShoulder,
    required this.rightShoulder,
    required this.leftHip,
    required this.rightHip,
    required this.leftKnee,
    required this.rightKnee,
  });

  factory TargetAngles.fromJson(Map<String, dynamic> json) {
    return TargetAngles(
      leftElbow: (json['leftElbow'] as num?)?.toDouble() ?? 160.0,
      rightElbow: (json['rightElbow'] as num?)?.toDouble() ?? 160.0,
      leftShoulder: (json['leftShoulder'] as num?)?.toDouble() ?? 30.0,
      rightShoulder: (json['rightShoulder'] as num?)?.toDouble() ?? 30.0,
      leftHip: (json['leftHip'] as num?)?.toDouble() ?? 175.0,
      rightHip: (json['rightHip'] as num?)?.toDouble() ?? 175.0,
      leftKnee: (json['leftKnee'] as num?)?.toDouble() ?? 178.0,
      rightKnee: (json['rightKnee'] as num?)?.toDouble() ?? 178.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'leftElbow': leftElbow,
        'rightElbow': rightElbow,
        'leftShoulder': leftShoulder,
        'rightShoulder': rightShoulder,
        'leftHip': leftHip,
        'rightHip': rightHip,
        'leftKnee': leftKnee,
        'rightKnee': rightKnee,
      };
}

class PoseModel {
  final String id;
  final String name;
  final PoseCategory category;
  final String difficulty;
  final int peopleCount;
  final String description;
  final String thumbnail;
  final List<String> tags;
  final TargetAngles targetAngles;
  final List<Point3D> landmarks;

  const PoseModel({
    required this.id,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.peopleCount,
    required this.description,
    required this.thumbnail,
    required this.tags,
    required this.targetAngles,
    required this.landmarks,
  });

  factory PoseModel.fromJson(Map<String, dynamic> json) {
    return PoseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: PoseCategory.fromString(json['category'] as String),
      difficulty: json['difficulty'] as String? ?? 'Beginner',
      peopleCount: json['peopleCount'] as int? ?? 1,
      description: json['description'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      targetAngles: TargetAngles.fromJson(json['targetAngles'] as Map<String, dynamic>? ?? {}),
      landmarks: (json['landmarks'] as List<dynamic>?)
              ?.map((e) => Point3D.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.label,
        'difficulty': difficulty,
        'peopleCount': peopleCount,
        'description': description,
        'thumbnail': thumbnail,
        'tags': tags,
        'targetAngles': targetAngles.toJson(),
        'landmarks': landmarks.map((e) => e.toJson()).toList(),
      };
}
