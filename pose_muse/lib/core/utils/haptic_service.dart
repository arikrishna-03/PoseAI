import 'package:flutter/services.dart';

class HapticService {
  static bool enabled = true;

  static void lightImpact() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }

  static void selectionClick() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }
}
