import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../domain/pose_category.dart';
import '../domain/pose_model.dart';
import 'pose_view_model.dart';

class PosePickerSheet extends ConsumerStatefulWidget {
  const PosePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PosePickerSheet(),
    );
  }

  @override
  ConsumerState<PosePickerSheet> createState() => _PosePickerSheetState();
}

class _PosePickerSheetState extends ConsumerState<PosePickerSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poseState = ref.watch(poseViewModelProvider);
    final viewModel = ref.read(poseViewModelProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header title & count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pose Library',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${poseState.filteredPoses.length} Poses Available',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                // People detected suggestion badge
                if (poseState.detectedPeopleCount > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryCyan.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.group_rounded, color: AppColors.primaryCyan, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${poseState.detectedPeopleCount} People Detected',
                          style: const TextStyle(
                            color: AppColors.primaryCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search poses, styles, mood...',
                  hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white60, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            viewModel.updateSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: viewModel.updateSearchQuery,
              ),
            ),
          ),

          // Category Chips Horizontal Scroll
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              scrollDirection: Axis.horizontal,
              itemCount: PoseCategory.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = PoseCategory.values[index];
                final isSelected = poseState.selectedCategory == category;

                return FilterChip(
                  label: Text(category.label),
                  selected: isSelected,
                  selectedColor: AppColors.primaryNeon,
                  backgroundColor: AppColors.darkCard,
                  checkmarkColor: Colors.black,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12.5,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryNeon : AppColors.glassBorder,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  onSelected: (_) => viewModel.selectCategory(category),
                );
              },
            ),
          ),

          // Pose Grid
          Expanded(
            child: poseState.filteredPoses.isEmpty
                ? const Center(
                    child: Text(
                      'No matching poses found',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.82,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: poseState.filteredPoses.length,
                    itemBuilder: (context, index) {
                      final pose = poseState.filteredPoses[index];
                      final isCurrent = poseState.currentSelectedPose?.id == pose.id;
                      final isFav = poseState.favoriteIds.contains(pose.id);

                      return GestureDetector(
                        onTap: () {
                          viewModel.selectPose(pose);
                          Navigator.of(context).pop();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.primaryNeon.withOpacity(0.12)
                                : AppColors.darkCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isCurrent ? AppColors.primaryNeon : AppColors.glassBorder,
                              width: isCurrent ? 2.0 : 1.0,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Visual Silhouette / Skeleton Mock Preview
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.black38,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            pose.peopleCount > 1
                                                ? Icons.groups_rounded
                                                : Icons.person_rounded,
                                            size: 48,
                                            color: isCurrent
                                                ? AppColors.primaryNeon
                                                : Colors.white54,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      pose.name,
                                      style: TextStyle(
                                        color: isCurrent ? AppColors.primaryNeon : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          pose.category.label,
                                          style: const TextStyle(
                                            color: AppColors.textTertiary,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          pose.difficulty,
                                          style: TextStyle(
                                            color: pose.difficulty == 'Beginner'
                                                ? AppColors.primaryNeon
                                                : (pose.difficulty == 'Intermediate'
                                                    ? AppColors.warningYellow
                                                    : AppColors.errorRed),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Favorite heart button
                              Positioned(
                                top: 6,
                                right: 6,
                                child: IconButton(
                                  icon: Icon(
                                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: isFav ? AppColors.errorRed : Colors.white60,
                                    size: 18,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => viewModel.toggleFavorite(pose.id),
                                ),
                              ),
                              // Active checkmark badge
                              if (isCurrent)
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryNeon,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.black,
                                      size: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
