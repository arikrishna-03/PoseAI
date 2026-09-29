class SettingsState {
  final bool isDarkMode;
  final bool mirrorFrontCamera;
  final bool showGridLines;
  final bool hapticsEnabled;
  final bool autoCaptureEnabled;
  final double autoCaptureThreshold; // 0.70 to 0.95

  const SettingsState({
    this.isDarkMode = true,
    this.mirrorFrontCamera = true,
    this.showGridLines = false,
    this.hapticsEnabled = true,
    this.autoCaptureEnabled = true,
    this.autoCaptureThreshold = 0.85,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    bool? mirrorFrontCamera,
    bool? showGridLines,
    bool? hapticsEnabled,
    bool? autoCaptureEnabled,
    double? autoCaptureThreshold,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      mirrorFrontCamera: mirrorFrontCamera ?? this.mirrorFrontCamera,
      showGridLines: showGridLines ?? this.showGridLines,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      autoCaptureEnabled: autoCaptureEnabled ?? this.autoCaptureEnabled,
      autoCaptureThreshold: autoCaptureThreshold ?? this.autoCaptureThreshold,
    );
  }

  Map<String, dynamic> toJson() => {
        'isDarkMode': isDarkMode,
        'mirrorFrontCamera': mirrorFrontCamera,
        'showGridLines': showGridLines,
        'hapticsEnabled': hapticsEnabled,
        'autoCaptureEnabled': autoCaptureEnabled,
        'autoCaptureThreshold': autoCaptureThreshold,
      };

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      isDarkMode: json['isDarkMode'] as bool? ?? true,
      mirrorFrontCamera: json['mirrorFrontCamera'] as bool? ?? true,
      showGridLines: json['showGridLines'] as bool? ?? false,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      autoCaptureEnabled: json['autoCaptureEnabled'] as bool? ?? true,
      autoCaptureThreshold: (json['autoCaptureThreshold'] as num?)?.toDouble() ?? 0.85,
    );
  }
}
