import { z } from 'zod';

export const KeypointSchema = z.object({
  x: z.number().min(0).max(1),
  y: z.number().min(0).max(1),
  score: z.number().min(0).max(1).optional()
});

export const PersonPoseSchema = z.object({
  position: z.enum(['left', 'center', 'right']),
  description: z.string().min(5),
  keypoints: z.array(KeypointSchema).length(17)
});

export const IdeaSchema = z.object({
  title: z.string().min(3),
  why_it_works: z.string().min(10),
  style: z.string(),
  difficulty: z.enum(['easy', 'medium', 'hard']),
  camera_tips: z.object({
    height: z.string(),
    angle: z.string(),
    distance: z.string(),
    orientation: z.enum(['portrait', 'landscape'])
  }),
  expression_tip: z.string(),
  people: z.array(PersonPoseSchema).min(1)
});

export const GenerateIdeasResponseSchema = z.object({
  scene_analysis: z.object({
    location_type: z.string(),
    lighting: z.string(),
    detected_props: z.array(z.string()),
    outfit_summary: z.string()
  }),
  ideas: z.array(IdeaSchema).min(4).max(6)
});

export type GenerateIdeasResponse = z.infer<typeof GenerateIdeasResponseSchema>;

/**
 * Validates anatomical bone proportions for COCO 17 landmarks:
 * 0: nose, 1: left_eye, 2: right_eye, 3: left_ear, 4: right_ear,
 * 5: left_shoulder, 6: right_shoulder, 7: left_elbow, 8: right_elbow,
 * 9: left_wrist, 10: right_wrist, 11: left_hip, 12: right_hip,
 * 13: left_knee, 14: right_knee, 15: left_ankle, 16: right_ankle
 */
export function sanitizeAndCheckSkeleton(keypoints: Array<{ x: number; y: number }>): {
  isValid: boolean;
  sanitized: Array<{ x: number; y: number }>;
  reason?: string;
} {
  if (keypoints.length !== 17) {
    return { isValid: false, sanitized: keypoints, reason: 'Expected exactly 17 COCO landmarks' };
  }

  // 1. Clamp all points to [0, 1]
  const sanitized = keypoints.map((pt) => ({
    x: Math.max(0, Math.min(1, pt.x)),
    y: Math.max(0, Math.min(1, pt.y))
  }));

  const dist = (i1: number, i2: number) => {
    const dx = sanitized[i1].x - sanitized[i2].x;
    const dy = sanitized[i1].y - sanitized[i2].y;
    return Math.sqrt(dx * dx + dy * dy);
  };

  // Shoulder width (5 to 6)
  const shoulderWidth = dist(5, 6);
  if (shoulderWidth < 0.02 || shoulderWidth > 0.8) {
    return { isValid: false, sanitized, reason: 'Unrealistic shoulder span' };
  }

  // Upper arm (shoulder to elbow) vs Forearm (elbow to wrist)
  // Left arm: 5->7 and 7->9
  const lUpperArm = dist(5, 7);
  const lForearm = dist(7, 9);
  if (lUpperArm > 0.01 && lForearm > 0.01) {
    const ratio = lUpperArm / lForearm;
    if (ratio < 0.4 || ratio > 2.5) {
      // Auto-correct forearm length to match upper arm proportionally
      sanitized[9] = {
        x: Math.max(0, Math.min(1, sanitized[7].x + (sanitized[9].x - sanitized[7].x) * (lUpperArm / lForearm))),
        y: Math.max(0, Math.min(1, sanitized[7].y + (sanitized[9].y - sanitized[7].y) * (lUpperArm / lForearm)))
      };
    }
  }

  // Right arm: 6->8 and 8->10
  const rUpperArm = dist(6, 8);
  const rForearm = dist(8, 10);
  if (rUpperArm > 0.01 && rForearm > 0.01) {
    const ratio = rUpperArm / rForearm;
    if (ratio < 0.4 || ratio > 2.5) {
      sanitized[10] = {
        x: Math.max(0, Math.min(1, sanitized[8].x + (sanitized[10].x - sanitized[8].x) * (rUpperArm / rForearm))),
        y: Math.max(0, Math.min(1, sanitized[8].y + (sanitized[10].y - sanitized[8].y) * (rUpperArm / rForearm)))
      };
    }
  }

  return { isValid: true, sanitized };
}
