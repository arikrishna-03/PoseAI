import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/coco_landmarks.dart';
import '../../domain/photo_idea.dart';

class IdeaDetailSheet extends StatelessWidget {
  final PhotoIdea idea;
  final VoidCallback onStartCoaching;

  const IdeaDetailSheet({
    super.key,
    required this.idea,
    required this.onStartCoaching,
  });

  static Future<void> show(BuildContext context, PhotoIdea idea, VoidCallback onStartCoaching) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IdeaDetailSheet(idea: idea, onStartCoaching: onStartCoaching),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
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
            margin: const EdgeInsets.only(top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                // Title and Style
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        idea.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNeon.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryNeon.withOpacity(0.4)),
                      ),
                      child: Text(
                        idea.difficulty.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryNeon,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Large Skeleton Preview Stage
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomPaint(
                      painter: _LargeSkeletonPainter(people: idea.people),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // "Why it works here" Section
                _buildSectionHeader('WHY THIS WORKS HERE'),
                Text(
                  idea.whyItWorks,
                  style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.45),
                ),
                const SizedBox(height: 20),

                // Camera Direction Tips
                _buildSectionHeader('PHOTOGRAPHER CAMERA TIPS'),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Column(
                    children: [
                      _buildTipRow(Icons.height_rounded, 'Camera Height', idea.cameraTips.height),
                      const Divider(color: AppColors.glassBorder, height: 16),
                      _buildTipRow(Icons.rotate_90_degrees_cw_rounded, 'Angle', idea.cameraTips.angle),
                      const Divider(color: AppColors.glassBorder, height: 16),
                      _buildTipRow(Icons.straighten_rounded, 'Distance', idea.cameraTips.distance),
                      const Divider(color: AppColors.glassBorder, height: 16),
                      _buildTipRow(Icons.crop_portrait_rounded, 'Orientation', idea.cameraTips.orientation),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Expression Tip
                _buildSectionHeader('EXPRESSION & MOOD'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mood_rounded, color: AppColors.primaryCyan, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          idea.expressionTip,
                          style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // People Roles
                _buildSectionHeader('SUBJECT POSITIONS'),
                ...idea.people.map(
                  (person) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Text(
                            person.position.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primaryNeon,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            person.description,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // Bottom Action Button: Start Live Coaching
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onStartCoaching();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNeon,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                  elevation: 6,
                  shadowColor: AppColors.primaryNeon.withOpacity(0.4),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_run_rounded, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Start Live Coaching',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryCyan, size: 18),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

class _LargeSkeletonPainter extends CustomPainter {
  final List<TargetPersonPose> people;
  _LargeSkeletonPainter({required this.people});

  @override
  void paint(Canvas canvas, Size size) {
    final bonePaint = Paint()
      ..color = AppColors.primaryNeon
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final jointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final person in people) {
      if (person.keypoints.length < 17) continue;

      for (final conn in CocoLandmarks.skeletonConnections) {
        final pt1 = person.keypoints[conn[0]];
        final pt2 = person.keypoints[conn[1]];
        final p1 = Offset(pt1.x * size.width, pt1.y * size.height);
        final p2 = Offset(pt2.x * size.width, pt2.y * size.height);
        canvas.drawLine(p1, p2, bonePaint);
      }

      for (final pt in person.keypoints) {
        final p = Offset(pt.x * size.width, pt.y * size.height);
        canvas.drawCircle(p, 4.5, jointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LargeSkeletonPainter oldDelegate) => false;
}
