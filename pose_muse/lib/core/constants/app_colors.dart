import 'package:flutter/material.dart';

class AppColors {
  // Brand Accents
  static const Color primaryNeon = Color(0xFF00FFB2); // Electric Mint / Neon Green
  static const Color primaryCyan = Color(0xFF00E5FF); // Electric Cyan
  static const Color accentPurple = Color(0xFFB388FF); // Soft Violet
  static const Color warningYellow = Color(0xFFFFD600); // Amber Yellow for moderate match
  static const Color errorRed = Color(0xFFFF3366); // Vibrant Coral Red for low match

  // Backgrounds & Surfaces (Photo-first dark UI)
  static const Color darkBackground = Color(0xFF0A0C10);
  static const Color darkSurface = Color(0xFF14171F);
  static const Color darkCard = Color(0xFF1C212B);
  static const Color glassSurface = Color(0x331E2330);
  static const Color glassBorder = Color(0x22FFFFFF);

  // Ghost Skeleton Overlay
  static const Color ghostSkeletonBone = Color(0x66FFFFFF);
  static const Color ghostSkeletonJoint = Color(0x8800E5FF);

  // User Detected Skeleton Dynamic Colors
  static Color matchColor(double score) {
    if (score >= 0.85) {
      return primaryNeon; // Match successful
    } else if (score >= 0.55) {
      return warningYellow; // Getting close
    } else {
      return errorRed; // Off-pose
    }
  }

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9EABB8);
  static const Color textTertiary = Color(0xFF637083);
}
