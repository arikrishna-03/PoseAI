import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/haptic_service.dart';
import '../domain/settings_state.dart';

final settingsViewModelProvider = StateNotifierProvider<SettingsViewModel, SettingsState>((ref) {
  return SettingsViewModel();
});

class SettingsViewModel extends StateNotifier<SettingsState> {
  Box? _settingsBox;

  SettingsViewModel() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
    final raw = _settingsBox?.get('user_settings');
    if (raw != null) {
      final map = Map<String, dynamic>.from(raw as Map);
      state = SettingsState.fromJson(map);
      HapticService.enabled = state.hapticsEnabled;
    }
  }

  Future<void> _saveSettings() async {
    await _settingsBox?.put('user_settings', state.toJson());
  }

  void toggleDarkMode(bool value) {
    state = state.copyWith(isDarkMode: value);
    _saveSettings();
  }

  void toggleMirrorFrontCamera(bool value) {
    state = state.copyWith(mirrorFrontCamera: value);
    _saveSettings();
  }

  void toggleGridLines(bool value) {
    state = state.copyWith(showGridLines: value);
    _saveSettings();
  }

  void toggleHaptics(bool value) {
    state = state.copyWith(hapticsEnabled: value);
    HapticService.enabled = value;
    _saveSettings();
  }

  void toggleAutoCapture(bool value) {
    state = state.copyWith(autoCaptureEnabled: value);
    _saveSettings();
  }

  void setAutoCaptureThreshold(double value) {
    state = state.copyWith(autoCaptureThreshold: value);
    _saveSettings();
  }
}
