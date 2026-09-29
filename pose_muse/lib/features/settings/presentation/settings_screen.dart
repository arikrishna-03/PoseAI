import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/voice_coach_service.dart';
import '../../ideas/presentation/ideas_view_model.dart';
import 'settings_view_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsViewModelProvider);
    final settingsNotifier = ref.read(settingsViewModelProvider.notifier);
    final ideasState = ref.watch(ideasViewModelProvider);
    final ideasNotifier = ref.read(ideasViewModelProvider.notifier);

    const availableStyles = ['candid', 'fashion', 'romantic', 'fun', 'cinematic'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Preferred Photo Styles Section
          _buildSectionHeader('AI PHOTO STYLES'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Preferred Aesthetics',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                const Text(
                  'The AI photographer will prioritize ideas matching these themes.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableStyles.map((style) {
                    final isSelected = ideasState.preferredStyles.contains(style);
                    return FilterChip(
                      label: Text(style.toUpperCase()),
                      selected: isSelected,
                      selectedColor: AppColors.primaryNeon,
                      backgroundColor: Colors.black26,
                      checkmarkColor: Colors.black,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11.5,
                      ),
                      side: BorderSide(color: isSelected ? AppColors.primaryNeon : AppColors.glassBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (selected) {
                        final current = List<String>.from(ideasState.preferredStyles);
                        if (selected) {
                          current.add(style);
                        } else {
                          current.remove(style);
                        }
                        ideasNotifier.updatePreferredStyles(current);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Coaching & Capture Section
          _buildSectionHeader('COACHING & CAPTURE'),
          _buildCard([
            SwitchListTile.adaptive(
              title: const Text('Voice Hints (Spoken Coach)'),
              subtitle: const Text('Speaks tips aloud while you pose'),
              value: VoiceCoachService.enabled,
              activeColor: AppColors.primaryNeon,
              onChanged: (val) {
                VoiceCoachService.enabled = val;
                (context as Element).markNeedsBuild();
              },
            ),
            const Divider(height: 1, color: AppColors.glassBorder),
            SwitchListTile.adaptive(
              title: const Text('Auto-Capture When Ready'),
              subtitle: const Text('Snaps photo after holding matched pose for 1 second'),
              value: settings.autoCaptureEnabled,
              activeColor: AppColors.primaryNeon,
              onChanged: settingsNotifier.toggleAutoCapture,
            ),
            const Divider(height: 1, color: AppColors.glassBorder),
            SwitchListTile.adaptive(
              title: const Text('Haptic Feedback'),
              subtitle: const Text('Tactile response on alignment milestones'),
              value: settings.hapticsEnabled,
              activeColor: AppColors.primaryNeon,
              onChanged: settingsNotifier.toggleHaptics,
            ),
          ]),
          const SizedBox(height: 24),

          // Camera View Section
          _buildSectionHeader('CAMERA & VIEW'),
          _buildCard([
            SwitchListTile.adaptive(
              title: const Text('Mirror Front Camera'),
              subtitle: const Text('Flip front camera view horizontally'),
              value: settings.mirrorFrontCamera,
              activeColor: AppColors.primaryNeon,
              onChanged: settingsNotifier.toggleMirrorFrontCamera,
            ),
            const Divider(height: 1, color: AppColors.glassBorder),
            SwitchListTile.adaptive(
              title: const Text('Rule of Thirds Grid'),
              subtitle: const Text('Viewfinder composition guidelines'),
              value: settings.showGridLines,
              activeColor: AppColors.primaryNeon,
              onChanged: settingsNotifier.toggleGridLines,
            ),
            const Divider(height: 1, color: AppColors.glassBorder),
            SwitchListTile.adaptive(
              title: const Text('Dark Mode'),
              subtitle: const Text('High-contrast photography UI'),
              value: settings.isDarkMode,
              activeColor: AppColors.primaryNeon,
              onChanged: settingsNotifier.toggleDarkMode,
            ),
          ]),
          const SizedBox(height: 24),

          // Privacy & AI Architecture Notice
          _buildSectionHeader('DATA & PRIVACY'),
          _buildCard([
            ListTile(
              title: const Text(AppConstants.appName),
              subtitle: const Text('AI Photographer Assistant • v1.0.0'),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryNeon.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryNeon, size: 24),
              ),
            ),
            const Divider(height: 1, color: AppColors.glassBorder),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Your snapshot is sent securely to AI to create ideas and is not stored.\n\nAll real-time skeleton tracking and alignment matching runs 100% on-device.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.45),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(children: children),
    );
  }
}
