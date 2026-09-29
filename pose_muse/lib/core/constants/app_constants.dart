class AppConstants {
  static const String appName = 'PoseMuse';
  static const String appTagline = 'AI On-Device Photo Pose Director';

  // Hive Box Names
  static const String settingsBox = 'settings_box';
  static const String favoritesBox = 'favorites_box';
  static const String recentsBox = 'recents_box';
  static const String galleryBox = 'gallery_box';

  // Detection & Thresholds
  static const double autoCaptureThresholdDefault = 0.85; // 85%
  static const int autoCaptureHoldDurationMs = 1000; // 1 second hold
  static const int detectionThrottleMs = 66; // ~15 FPS
  static const int minLandmarksForDetection = 11; // Must see at least upper body
}
