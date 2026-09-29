class CapturedPhoto {
  final String id;
  final String filePath;
  final DateTime timestamp;
  final String poseName;
  final double matchScore;

  const CapturedPhoto({
    required this.id,
    required this.filePath,
    required this.timestamp,
    required this.poseName,
    required this.matchScore,
  });

  factory CapturedPhoto.fromJson(Map<String, dynamic> json) {
    return CapturedPhoto(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      poseName: json['poseName'] as String? ?? 'Custom Pose',
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'timestamp': timestamp.toIso8601String(),
        'poseName': poseName,
        'matchScore': matchScore,
      };
}
