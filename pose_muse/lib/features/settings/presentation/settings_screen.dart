import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import 'settings_view_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsViewModelProvider);
    final viewModel = ref.read(settingsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildSectionHeader('CAMERA & VIEW'),
          _buildCard([
            SwitchListTile.adaptive(
              title: const Text('Mirror Front Camera'),
              subtitle: const Text('Flip front camera view horizontally'),
              value: settings.mirrorFrontCamera,
              activeColor: AppColors.primaryNeon,
              onChanged: viewModel.toggleMirrorFrontCamera,
            ),
            const Divider(height: 1, color: AppColors.glassBorder),
            SwitchListTile.adaptive(
              title: const Text('Show Grid Lines'),
              subtitle: const Text('Rule of thirds guidelines for framing'),
              value: settings.showGridLines,
              activeColor: AppColors.primaryNeon,
              onChanged: viewModel.toggleGridLines,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('AI AUTO-CAPTURE'),
          _buildCard([
            SwitchListTile.adaptive(
              title: const Text('Auto-Capture When Ready'),
              subtitle: const Text('Snaps photo after holding matched pose for 1 second'),
              value: settings.autoCaptureEnabled,
              activeColor: AppColors.primaryNeon,
              onChanged: viewModel.toggleAutoCapture,
            ),
            if (settings.autoCaptureEnabled) ...[
              const Divider(height: 1, color: AppColors.glassBorder),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Match Threshold',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${(settings.autoCaptureThreshold * 100).toInt()}%',
                          style: const TextStyle(
                            color: AppColors.primaryNeon,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider.adaptive(
                      value: settings.autoCaptureThreshold,
                      min: 0.70,
                      max: 0.95,
                      divisions: 5,
                      activeColor: AppColors.primaryNeon,
                      inactiveColor: Colors.white24,
                      onChanged: viewModel.setAutoCaptureThreshold,
                    ),
                  ],
                ),
              ),
            ],
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('PREFERENCES'),
          _buildCard([
            SwitchListTile.adaptive(
              title: const Text('Haptic Feedback'),
              subtitle: const Text('Vibrate upon pose alignment milestones'),
              value: settings.hapticsEnabled,
              activeColor: AppColors.primaryNeon,
              onChanged: viewModel.toggleHaptics,
            ),
            const Divider(height: 1, color: AppColors.glassBorder),
            SwitchListTile.adaptive(
              title: const Text('Dark Mode'),
              subtitle: const Text('Optimized for photography & low glare'),
              value: settings.isDarkMode,
              activeColor: AppColors.primaryNeon,
              onChanged: viewModel.toggleDarkMode,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionHeader('ABOUT'),
          _buildCard([
            ListTile(
              title: const Text(AppConstants.appName),
              subtitle: const Text('${AppConstants.appTagline} • v1.0.0'),
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
                'PoseMuse processes all pose landmark calculations 100% locally on-device using MediaPipe Pose ML. No photos or biometric data ever leave your phone.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary, height: 1.4),
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
