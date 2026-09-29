/// COCO / MoveNet 17 keypoints standard used by MoveNet and PoseMuse AI
class CocoLandmarks {
  static const int nose = 0;
  static const int leftEye = 1;
  static const int rightEye = 2;
  static const int leftEar = 3;
  static const int rightEar = 4;
  static const int leftShoulder = 5;
  static const int rightShoulder = 6;
  static const int leftElbow = 7;
  static const int rightElbow = 8;
  static const int leftWrist = 9;
  static const int rightWrist = 10;
  static const int leftHip = 11;
  static const int rightHip = 12;
  static const int leftKnee = 13;
  static const int rightKnee = 14;
  static const int leftAnkle = 15;
  static const int rightAnkle = 16;

  /// Bone connections for drawing COCO 17-point skeletons
  static const List<List<int>> skeletonConnections = [
    // Head
    [nose, leftEye],
    [nose, rightEye],
    [leftEye, leftEar],
    [rightEye, rightEar],

    // Torso
    [leftShoulder, rightShoulder],
    [leftShoulder, leftHip],
    [rightShoulder, rightHip],
    [leftHip, rightHip],

    // Arms
    [leftShoulder, leftElbow],
    [leftElbow, leftWrist],
    [rightShoulder, rightElbow],
    [rightElbow, rightWrist],

    // Legs
    [leftHip, leftKnee],
    [leftKnee, leftAnkle],
    [rightHip, rightKnee],
    [rightKnee, rightAnkle],
  ];

  static const List<String> names = [
    'Nose',
    'Left Eye',
    'Right Eye',
    'Left Ear',
    'Right Ear',
    'Left Shoulder',
    'Right Shoulder',
    'Left Elbow',
    'Right Elbow',
    'Left Wrist',
    'Right Wrist',
    'Left Hip',
    'Right Hip',
    'Left Knee',
    'Right Knee',
    'Left Ankle',
    'Right Ankle',
  ];
}
