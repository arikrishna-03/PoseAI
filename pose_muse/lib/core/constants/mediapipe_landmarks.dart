/// MediaPipe 33 Landmark indices for on-device pose detection
class MediaPipeLandmarks {
  static const int nose = 0;
  static const int leftEyeInner = 1;
  static const int leftEye = 2;
  static const int leftEyeOuter = 3;
  static const int rightEyeInner = 4;
  static const int rightEye = 5;
  static const int rightEyeOuter = 6;
  static const int leftEar = 7;
  static const int rightEar = 8;
  static const int mouthLeft = 9;
  static const int mouthRight = 10;
  static const int leftShoulder = 11;
  static const int rightShoulder = 12;
  static const int leftElbow = 13;
  static const int rightElbow = 14;
  static const int leftWrist = 15;
  static const int rightWrist = 16;
  static const int leftPinky = 17;
  static const int rightPinky = 18;
  static const int leftIndex = 19;
  static const int rightIndex = 20;
  static const int leftThumb = 21;
  static const int rightThumb = 22;
  static const int leftHip = 23;
  static const int rightHip = 24;
  static const int leftKnee = 25;
  static const int rightKnee = 26;
  static const int leftAnkle = 27;
  static const int rightAnkle = 28;
  static const int leftHeel = 29;
  static const int rightHeel = 30;
  static const int leftFootIndex = 31;
  static const int rightFootIndex = 32;

  /// Connections between landmarks to draw bones in skeleton overlay
  static const List<List<int>> skeletonConnections = [
    // Torso & Shoulders
    [leftShoulder, rightShoulder],
    [leftShoulder, leftHip],
    [rightShoulder, rightHip],
    [leftHip, rightHip],

    // Left Arm
    [leftShoulder, leftElbow],
    [leftElbow, leftWrist],
    [leftWrist, leftPinky],
    [leftWrist, leftIndex],
    [leftWrist, leftThumb],

    // Right Arm
    [rightShoulder, rightElbow],
    [rightElbow, rightWrist],
    [rightWrist, rightPinky],
    [rightWrist, rightIndex],
    [rightWrist, rightThumb],

    // Left Leg
    [leftHip, leftKnee],
    [leftKnee, leftAnkle],
    [leftAnkle, leftHeel],
    [leftAnkle, leftFootIndex],

    // Right Leg
    [rightHip, rightKnee],
    [rightKnee, rightAnkle],
    [rightAnkle, rightHeel],
    [rightAnkle, rightFootIndex],

    // Face / Head
    [leftEar, leftEyeOuter],
    [leftEyeOuter, leftEye],
    [leftEye, leftEyeInner],
    [leftEyeInner, nose],
    [nose, rightEyeInner],
    [rightEyeInner, rightEye],
    [rightEye, rightEyeOuter],
    [rightEyeOuter, rightEar],
    [mouthLeft, mouthRight],
  ];
}
