import { GenerateIdeasResponse, GenerateIdeasResponseSchema, Idea, Keypoint, PersonPose } from './schema';
import { AppError } from './errors';

export interface ValidationOutcome {
  success: boolean;
  data?: GenerateIdeasResponse;
  needsRetry: boolean;
  error?: AppError;
}

const POSE_EXCEPTION_REGEX = /\b(sit|sitting|sat|lie|lying|crouch|crouching|lean|leaning|jump|jumping)\b/i;

function distance(p1: { x: number; y: number }, p2: { x: number; y: number }): number {
  const dx = p1.x - p2.x;
  const dy = p1.y - p2.y;
  return Math.sqrt(dx * dx + dy * dy);
}

/**
 * Validates and clamps an individual person's 17 COCO keypoints.
 * Clamps coordinates within [-0.05, 1.05] to [0, 1]. Rejects if outside that range.
 * Checks anatomical plausibility.
 */
export function validateAndSanitizePersonPose(person: PersonPose): {
  isValid: boolean;
  sanitized?: PersonPose;
  reason?: string;
} {
  const points = person.keypoints;
  if (!points || points.length !== 17) {
    return { isValid: false, reason: 'Expected exactly 17 COCO keypoints' };
  }

  // 1. Clamp tiny overshoots up to 0.05, reject beyond
  const clampedPoints: Keypoint[] = [];
  for (let i = 0; i < 17; i++) {
    const pt = points[i];
    if (pt.x < -0.05 || pt.x > 1.05 || pt.y < -0.05 || pt.y > 1.05) {
      return { isValid: false, reason: `Keypoint ${i} (${pt.x}, ${pt.y}) is out of bounds [0, 1]` };
    }
    clampedPoints.push({
      x: Math.max(0, Math.min(1, pt.x)),
      y: Math.max(0, Math.min(1, pt.y))
    });
  }

  // COCO landmarks:
  // 5: L shoulder, 6: R shoulder, 7: L elbow, 8: R elbow, 9: L wrist, 10: R wrist
  // 11: L hip, 12: R hip, 13: L knee, 14: R knee, 15: L ankle, 16: R ankle
  const lShoulder = clampedPoints[5];
  const rShoulder = clampedPoints[6];
  const lElbow = clampedPoints[7];
  const rElbow = clampedPoints[8];
  const lWrist = clampedPoints[9];
  const rWrist = clampedPoints[10];
  const lHip = clampedPoints[11];
  const rHip = clampedPoints[12];
  const lKnee = clampedPoints[13];
  const rKnee = clampedPoints[14];
  const lAnkle = clampedPoints[15];
  const rAnkle = clampedPoints[16];

  // 2. Left and right shoulders are not identical points
  const shoulderSpan = distance(lShoulder, rShoulder);
  if (shoulderSpan < 0.01) {
    return { isValid: false, reason: 'Left and right shoulders are identical points' };
  }

  // 3. Vertical alignment (shoulders above hips, hips above knees, knees above ankles)
  const isException = POSE_EXCEPTION_REGEX.test(person.description);
  if (!isException) {
    const avgShoulderY = (lShoulder.y + rShoulder.y) / 2;
    const avgHipY = (lHip.y + rHip.y) / 2;
    const avgKneeY = (lKnee.y + rKnee.y) / 2;
    const avgAnkleY = (lAnkle.y + rAnkle.y) / 2;

    // In normalized coords, y increases downward. Shoulders above hips means shoulder Y < hip Y.
    // Allow a small 0.03 margin of error for tilt.
    if (avgShoulderY > avgHipY + 0.03) {
      return { isValid: false, reason: 'Shoulders are below hips in an upright pose' };
    }
    if (avgHipY > avgKneeY + 0.03) {
      return { isValid: false, reason: 'Hips are below knees in an upright pose' };
    }
    if (avgKneeY > avgAnkleY + 0.03) {
      return { isValid: false, reason: 'Knees are below ankles in an upright pose' };
    }
  }

  // 4. Plausible bone length ratios (within 0.5x to 2x)
  // Left Arm (upper arm: 5->7 vs forearm: 7->9)
  const lUpperArm = distance(lShoulder, lElbow);
  const lForearm = distance(lElbow, lWrist);
  if (lUpperArm > 0.02 && lForearm > 0.02) {
    const ratio = lUpperArm / lForearm;
    if (ratio < 0.45 || ratio > 2.2) {
      return { isValid: false, reason: `Unrealistic left arm bone ratio: ${ratio.toFixed(2)}` };
    }
  }

  // Right Arm (upper arm: 6->8 vs forearm: 8->10)
  const rUpperArm = distance(rShoulder, rElbow);
  const rForearm = distance(rElbow, rWrist);
  if (rUpperArm > 0.02 && rForearm > 0.02) {
    const ratio = rUpperArm / rForearm;
    if (ratio < 0.45 || ratio > 2.2) {
      return { isValid: false, reason: `Unrealistic right arm bone ratio: ${ratio.toFixed(2)}` };
    }
  }

  // Left Leg (thigh: 11->13 vs shin: 13->15)
  const lThigh = distance(lHip, lKnee);
  const lShin = distance(lKnee, lAnkle);
  if (lThigh > 0.02 && lShin > 0.02) {
    const ratio = lThigh / lShin;
    if (ratio < 0.45 || ratio > 2.2) {
      return { isValid: false, reason: `Unrealistic left leg bone ratio: ${ratio.toFixed(2)}` };
    }
  }

  // Right Leg (thigh: 12->14 vs shin: 14->16)
  const rThigh = distance(rHip, rKnee);
  const rShin = distance(rKnee, rAnkle);
  if (rThigh > 0.02 && rShin > 0.02) {
    const ratio = rThigh / rShin;
    if (ratio < 0.45 || ratio > 2.2) {
      return { isValid: false, reason: `Unrealistic right leg bone ratio: ${ratio.toFixed(2)}` };
    }
  }

  // Torso vs shoulder span ratio
  const midShoulder = { x: (lShoulder.x + rShoulder.x) / 2, y: (lShoulder.y + rShoulder.y) / 2 };
  const midHip = { x: (lHip.x + rHip.x) / 2, y: (lHip.y + rHip.y) / 2 };
  const torsoLength = distance(midShoulder, midHip);
  if (shoulderSpan > 0.02 && torsoLength > 0.02) {
    const torsoRatio = torsoLength / shoulderSpan;
    if (torsoRatio < 0.5 || torsoRatio > 3.5) {
      return { isValid: false, reason: `Unrealistic torso-to-shoulder ratio: ${torsoRatio.toFixed(2)}` };
    }
  }

  return {
    isValid: true,
    sanitized: {
      ...person,
      keypoints: clampedPoints
    }
  };
}

/**
 * Validates the raw JSON output from the AI model.
 * Executes Zod validation, skeleton sanity checks, and title deduplication.
 */
export function validateAiResponse(rawJson: unknown): ValidationOutcome {
  // Check for {"error": "no_people_found"}
  if (
    rawJson &&
    typeof rawJson === 'object' &&
    'error' in rawJson &&
    (rawJson as any).error === 'no_people_found'
  ) {
    return {
      success: false,
      needsRetry: false,
      error: AppError.noPeopleFound()
    };
  }

  // 1. Zod schema validation
  const parsed = GenerateIdeasResponseSchema.safeParse(rawJson);
  if (!parsed.success) {
    return {
      success: false,
      needsRetry: true,
      error: AppError.aiInvalidResponse(`Schema validation failed: ${parsed.error.message}`)
    };
  }

  const { scene, ideas } = parsed.data;

  // 2. Sanity-check each idea's skeletons and ensure unique titles
  const validIdeas: Idea[] = [];
  const seenTitles = new Set<string>();

  for (const idea of ideas) {
    // Unique title check
    const normalizedTitle = idea.title.trim().toLowerCase();
    if (seenTitles.has(normalizedTitle)) {
      continue; // Skip duplicate title
    }

    let ideaIsValid = true;
    const sanitizedPeople: PersonPose[] = [];

    for (const person of idea.people) {
      const check = validateAndSanitizePersonPose(person);
      if (!check.isValid || !check.sanitized) {
        ideaIsValid = false;
        break;
      }
      sanitizedPeople.push(check.sanitized);
    }

    if (ideaIsValid) {
      seenTitles.add(normalizedTitle);
      validIdeas.push({
        ...idea,
        people: sanitizedPeople
      });
    }
  }

  // If fewer than 3 ideas remain, trigger retry or fail
  if (validIdeas.length < 3) {
    return {
      success: false,
      needsRetry: true,
      error: AppError.aiInvalidResponse(
        `Too many ideas failed anatomical validation (${validIdeas.length} valid ideas remaining, minimum 3 required)`
      )
    };
  }

  return {
    success: true,
    needsRetry: false,
    data: {
      scene,
      ideas: validIdeas
    }
  };
}
