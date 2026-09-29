class Keypoint {
  final double x;
  final double y;
  final double score;

  const Keypoint({
    required this.x,
    required this.y,
    this.score = 1.0,
  });

  factory Keypoint.fromJson(Map<String, dynamic> json) {
    return Keypoint(
      x: (json['x'] as num).toDouble().clamp(0.0, 1.0),
      y: (json['y'] as num).toDouble().clamp(0.0, 1.0),
      score: (json['score'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'score': score};
}

class TargetPersonPose {
  final String position; // left | center | right
  final String description;
  final List<Keypoint> keypoints; // 17 COCO landmarks

  const TargetPersonPose({
    required this.position,
    required this.description,
    required this.keypoints,
  });

  factory TargetPersonPose.fromJson(Map<String, dynamic> json) {
    return TargetPersonPose(
      position: json['position'] as String? ?? 'center',
      description: json['description'] as String? ?? '',
      keypoints: (json['keypoints'] as List<dynamic>?)
              ?.map((k) => Keypoint.fromJson(k as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'position': position,
        'description': description,
        'keypoints': keypoints.map((k) => k.toJson()).toList(),
      };
}

class CameraTips {
  final String height;
  final String angle;
  final String distance;
  final String orientation; // portrait | landscape

  const CameraTips({
    required this.height,
    required this.angle,
    required this.distance,
    required this.orientation,
  });

  factory CameraTips.fromJson(Map<String, dynamic> json) {
    return CameraTips(
      height: json['height'] as String? ?? 'eye-level',
      angle: json['angle'] as String? ?? 'straight-on',
      distance: json['distance'] as String? ?? 'medium',
      orientation: json['orientation'] as String? ?? 'portrait',
    );
  }

  Map<String, dynamic> toJson() => {
        'height': height,
        'angle': angle,
        'distance': distance,
        'orientation': orientation,
      };
}

class SceneAnalysis {
  final String locationType;
  final String lighting;
  final List<String> detectedProps;
  final String outfitSummary;

  const SceneAnalysis({
    required this.locationType,
    required this.lighting,
    required this.detectedProps,
    required this.outfitSummary,
  });

  factory SceneAnalysis.fromJson(Map<String, dynamic> json) {
    return SceneAnalysis(
      locationType: json['location_type'] as String? ?? 'Outdoor/Indoor',
      lighting: json['lighting'] as String? ?? 'Natural Light',
      detectedProps: (json['detected_props'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      outfitSummary: json['outfit_summary'] as String? ?? 'Casual',
    );
  }

  Map<String, dynamic> toJson() => {
        'location_type': locationType,
        'lighting': lighting,
        'detected_props': detectedProps,
        'outfit_summary': outfitSummary,
      };
}

class PhotoIdea {
  final String id;
  final String title;
  final String whyItWorks;
  final String style;
  final String difficulty;
  final CameraTips cameraTips;
  final String expressionTip;
  final List<TargetPersonPose> people;
  final bool? isLiked; // true = liked, false = disliked, null = unrated

  const PhotoIdea({
    required this.id,
    required this.title,
    required this.whyItWorks,
    required this.style,
    required this.difficulty,
    required this.cameraTips,
    required this.expressionTip,
    required this.people,
    this.isLiked,
  });

  PhotoIdea copyWith({
    bool? isLiked,
  }) {
    return PhotoIdea(
      id: id,
      title: title,
      whyItWorks: whyItWorks,
      style: style,
      difficulty: difficulty,
      cameraTips: cameraTips,
      expressionTip: expressionTip,
      people: people,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  factory PhotoIdea.fromJson(Map<String, dynamic> json, {String? id}) {
    return PhotoIdea(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Original Pose Idea',
      whyItWorks: json['why_it_works'] as String? ?? '',
      style: json['style'] as String? ?? 'Candid',
      difficulty: json['difficulty'] as String? ?? 'medium',
      cameraTips: CameraTips.fromJson(json['camera_tips'] as Map<String, dynamic>? ?? {}),
      expressionTip: json['expression_tip'] as String? ?? '',
      people: (json['people'] as List<dynamic>?)
              ?.map((p) => TargetPersonPose.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      isLiked: json['is_liked'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'why_it_works': whyItWorks,
        'style': style,
        'difficulty': difficulty,
        'camera_tips': cameraTips.toJson(),
        'expression_tip': expressionTip,
        'people': people.map((p) => p.toJson()).toList(),
        'is_liked': isLiked,
      };
}

class PhotoIdeasResponse {
  final SceneAnalysis sceneAnalysis;
  final List<PhotoIdea> ideas;

  const PhotoIdeasResponse({
    required this.sceneAnalysis,
    required this.ideas,
  });

  factory PhotoIdeasResponse.fromJson(Map<String, dynamic> json) {
    return PhotoIdeasResponse(
      sceneAnalysis: SceneAnalysis.fromJson(json['scene_analysis'] as Map<String, dynamic>? ?? {}),
      ideas: (json['ideas'] as List<dynamic>?)
              ?.map((idea) => PhotoIdea.fromJson(idea as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'scene_analysis': sceneAnalysis.toJson(),
        'ideas': ideas.map((i) => i.toJson()).toList(),
      };
}
