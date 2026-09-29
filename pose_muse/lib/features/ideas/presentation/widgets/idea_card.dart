import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/coco_landmarks.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/photo_idea.dart';

class IdeaCard extends StatelessWidget {
  final PhotoIdea idea;
  final VoidCallback onTap;
  final Function(bool isLiked) onRate;

  const IdeaCard({
    super.key,
    required this.idea,
    required this.onTap,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(24),
        backgroundColor: AppColors.darkCard.withOpacity(0.9),
        borderColor: AppColors.glassBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: Style tag, difficulty & rating thumbs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNeon.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryNeon.withOpacity(0.4)),
                      ),
                      child: Text(
                        idea.style.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryNeon,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${idea.people.length} ${idea.people.length > 1 ? 'People' : 'Person'}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
                // Like / Dislike buttons
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        idea.isLiked == true ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                        size: 18,
                        color: idea.isLiked == true ? AppColors.primaryNeon : Colors.white60,
                      ),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      onPressed: () => onRate(true),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        idea.isLiked == false ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
                        size: 18,
                        color: idea.isLiked == false ? AppColors.errorRed : Colors.white60,
                      ),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      onPressed: () => onRate(false),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Content row: Skeleton thumbnail & description
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mini Skeleton Preview
                Container(
                  width: 72,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CustomPaint(
                      painter: _MiniSkeletonPainter(people: idea.people),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title & "Why it works"
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        idea.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        idea.whyItWorks,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            // Bottom quick badges: Camera tips + Coach Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.videocam_outlined, color: AppColors.primaryCyan, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${idea.cameraTips.height} • ${idea.cameraTips.angle}',
                      style: const TextStyle(color: AppColors.primaryCyan, fontSize: 11.5),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNeon,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Coach', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniSkeletonPainter extends CustomPainter {
  final List<TargetPersonPose> people;

  _MiniSkeletonPainter({required this.people});

  @override
  void paint(Canvas canvas, Size size) {
    final bonePaint = Paint()
      ..color = AppColors.primaryNeon.withOpacity(0.8)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final jointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final person in people) {
      if (person.keypoints.length < 17) continue;

      // Draw bones
      for (final conn in CocoLandmarks.skeletonConnections) {
        final pt1 = person.keypoints[conn[0]];
        final pt2 = person.keypoints[conn[1]];
        final p1 = Offset(pt1.x * size.width, pt1.y * size.height);
        final p2 = Offset(pt2.x * size.width, pt2.y * size.height);
        canvas.drawLine(p1, p2, bonePaint);
      }

      // Draw joints
      for (final pt in person.keypoints) {
        final p = Offset(pt.x * size.width, pt.y * size.height);
        canvas.drawCircle(p, 2.0, jointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniSkeletonPainter oldDelegate) => false;
}
