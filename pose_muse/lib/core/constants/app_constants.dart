class AppConstants {
  static const String appName = 'PoseMuse';
  static const String appTagline = 'AI Photographer & Posing Director';

  // Backend API URL (configurable; defaults to local development server)
  static const String defaultBackendUrl = 'http://10.0.2.2:8080'; // Android emulator localhost
  static const String defaultBackendUrlIos = 'http://localhost:8080';

  // Storage Box Names
  static const String settingsBox = 'settings_box';
  static const String preferencesBox = 'preferences_box';
  static const String galleryBox = 'gallery_box';
  static const String cachedIdeasBox = 'cached_ideas_box';

  // Thresholds & Limits
  static const double autoCaptureThresholdDefault = 0.85; // 85%
  static const int autoCaptureHoldDurationMs = 1000; // 1 second hold
  static const int detectionThrottleMs = 66; // ~15 FPS
  static const int maxImageLongSide = 768; // max 768px for vision AI
  static const int imageJpegQuality = 70; // ~70% JPEG compression
  static const int apiTimeoutSeconds = 15;
}
