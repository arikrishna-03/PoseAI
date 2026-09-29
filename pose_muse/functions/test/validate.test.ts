import { describe, it, expect } from 'vitest';
import { validateAndSanitizePersonPose, validateAiResponse } from '../src/validate';
import { PersonPose } from '../src/schema';

describe('Skeleton & Response Validation Tests', () => {
  function createStandardStandingKeypoints(): Array<{ x: number; y: number }> {
    const pts = Array.from({ length: 17 }, () => ({ x: 0.5, y: 0.5 }));
    // 0: nose
    pts[0] = { x: 0.50, y: 0.15 };
    // 1, 2: eyes
    pts[1] = { x: 0.52, y: 0.13 };
    pts[2] = { x: 0.48, y: 0.13 };
    // 3, 4: ears
    pts[3] = { x: 0.54, y: 0.15 };
    pts[4] = { x: 0.46, y: 0.15 };
    // 5, 6: shoulders (span ~0.20)
    pts[5] = { x: 0.60, y: 0.28 };
    pts[6] = { x: 0.40, y: 0.28 };
    // 7, 8: elbows
    pts[7] = { x: 0.68, y: 0.42 };
    pts[8] = { x: 0.32, y: 0.42 };
    // 9, 10: wrists
    pts[9] = { x: 0.68, y: 0.56 };
    pts[10] = { x: 0.32, y: 0.56 };
    // 11, 12: hips
    pts[11] = { x: 0.57, y: 0.58 };
    pts[12] = { x: 0.43, y: 0.58 };
    // 13, 14: knees
    pts[13] = { x: 0.57, y: 0.77 };
    pts[14] = { x: 0.43, y: 0.77 };
    // 15, 16: ankles
    pts[15] = { x: 0.57, y: 0.95 };
    pts[16] = { x: 0.43, y: 0.95 };
    return pts;
  }

  it('passes a realistic, anatomically valid standing skeleton', () => {
    const person: PersonPose = {
      position: 'center',
      description: 'Standing upright with arms resting naturally at sides.',
      keypoints: createStandardStandingKeypoints()
    };

    const result = validateAndSanitizePersonPose(person);
    expect(result.isValid).toBe(true);
    expect(result.sanitized).toBeDefined();
    expect(result.sanitized?.keypoints.length).toBe(17);
  });

  it('rejects an upside-down standing skeleton (shoulders below hips)', () => {
    const pts = createStandardStandingKeypoints();
    // Invert shoulders and hips: put shoulders at y=0.8 and hips at y=0.3
    pts[5] = { x: 0.60, y: 0.80 };
    pts[6] = { x: 0.40, y: 0.80 };
    pts[11] = { x: 0.57, y: 0.30 };
    pts[12] = { x: 0.43, y: 0.30 };

    const person: PersonPose = {
      position: 'center',
      description: 'Standing tall',
      keypoints: pts
    };

    const result = validateAndSanitizePersonPose(person);
    expect(result.isValid).toBe(false);
    expect(result.reason).toContain('Shoulders are below hips');
  });

  it('allows unconventional vertical alignment if description contains exception keywords (e.g. "lying")', () => {
    const pts = createStandardStandingKeypoints();
    // Shift entire upper body downward so shoulders are below hips, but arms remain proportional
    pts[5] = { x: 0.60, y: 0.70 }; // L shoulder
    pts[6] = { x: 0.40, y: 0.70 }; // R shoulder
    pts[7] = { x: 0.68, y: 0.82 }; // L elbow
    pts[8] = { x: 0.32, y: 0.82 }; // R elbow
    pts[9] = { x: 0.68, y: 0.94 }; // L wrist
    pts[10] = { x: 0.32, y: 0.94 }; // R wrist
    pts[11] = { x: 0.57, y: 0.50 }; // L hip (above shoulders in lying pose)
    pts[12] = { x: 0.43, y: 0.50 }; // R hip

    const person: PersonPose = {
      position: 'center',
      description: 'Lying on the picnic blanket gazing at stars',
      keypoints: pts
    };

    const result = validateAndSanitizePersonPose(person);
    expect(result.isValid).toBe(true);
  });

  it('clamps minor coordinate overshoots within [-0.05, 1.05] to [0, 1]', () => {
    const pts = createStandardStandingKeypoints();
    pts[0] = { x: 1.03, y: -0.02 }; // tiny overshoots

    const person: PersonPose = {
      position: 'center',
      description: 'Standing upright',
      keypoints: pts
    };

    const result = validateAndSanitizePersonPose(person);
    expect(result.isValid).toBe(true);
    expect(result.sanitized?.keypoints[0].x).toBe(1.0);
    expect(result.sanitized?.keypoints[0].y).toBe(0.0);
  });

  it('rejects out-of-range points exceeding 1.05 or below -0.05', () => {
    const pts = createStandardStandingKeypoints();
    pts[9] = { x: 1.50, y: 0.5 }; // grossly out of bounds

    const person: PersonPose = {
      position: 'center',
      description: 'Standing upright',
      keypoints: pts
    };

    const result = validateAndSanitizePersonPose(person);
    expect(result.isValid).toBe(false);
    expect(result.reason).toContain('out of bounds');
  });

  it('rejects identical shoulder points', () => {
    const pts = createStandardStandingKeypoints();
    pts[6] = { ...pts[5] }; // identical shoulder coordinates

    const person: PersonPose = {
      position: 'center',
      description: 'Standing upright',
      keypoints: pts
    };

    const result = validateAndSanitizePersonPose(person);
    expect(result.isValid).toBe(false);
    expect(result.reason).toContain('identical points');
  });

  it('handles no_people_found response with code 422', () => {
    const outcome = validateAiResponse({ error: 'no_people_found' });
    expect(outcome.success).toBe(false);
    expect(outcome.error?.statusCode).toBe(422);
    expect(outcome.error?.code).toBe('no_people_found');
  });

  it('deduplicates ideas with identical titles', () => {
    const validPts = createStandardStandingKeypoints();
    const mockResponse = {
      scene: {
        location_type: 'Cafe',
        lighting: 'Soft',
        people_count: 1,
        outfit_summary: 'Coat',
        props: ['Chair']
      },
      ideas: [
        {
          title: 'The Thinker',
          why_it_works: 'Uses the cafe chair comfortably.',
          style: 'candid',
          difficulty: 'easy',
          camera_tips: { height: 'eye', angle: '45', distance: 'med', orientation: 'portrait' },
          expression_tip: 'Smile',
          people: [{ position: 'center', description: 'Sitting on chair', keypoints: validPts }]
        },
        {
          title: 'the thinker', // duplicate title
          why_it_works: 'Duplicate idea that should be filtered out.',
          style: 'candid',
          difficulty: 'easy',
          camera_tips: { height: 'eye', angle: '45', distance: 'med', orientation: 'portrait' },
          expression_tip: 'Smile',
          people: [{ position: 'center', description: 'Sitting on chair', keypoints: validPts }]
        },
        {
          title: 'Looking Out Window',
          why_it_works: 'Takes advantage of natural window light.',
          style: 'editorial',
          difficulty: 'medium',
          camera_tips: { height: 'eye', angle: 'side', distance: 'med', orientation: 'portrait' },
          expression_tip: 'Calm gaze',
          people: [{ position: 'center', description: 'Sitting turning toward window', keypoints: validPts }]
        },
        {
          title: 'Holding the Warm Mug',
          why_it_works: 'Emphasizes warm ambient steam.',
          style: 'casual',
          difficulty: 'easy',
          camera_tips: { height: 'table', angle: 'straight', distance: 'close', orientation: 'portrait' },
          expression_tip: 'Soft expression',
          people: [{ position: 'center', description: 'Sitting with mug', keypoints: validPts }]
        },
        {
          title: 'Laughing Over Coffee',
          why_it_works: 'Captures dynamic table laughter.',
          style: 'funny',
          difficulty: 'easy',
          camera_tips: { height: 'eye', angle: '45', distance: 'med', orientation: 'portrait' },
          expression_tip: 'Laughing',
          people: [{ position: 'center', description: 'Sitting leaning back laughing', keypoints: validPts }]
        }
      ]
    };

    const outcome = validateAiResponse(mockResponse);
    expect(outcome.success).toBe(true);
    // 5 submitted, 1 duplicate removed -> 4 valid unique ideas remain
    expect(outcome.data?.ideas.length).toBe(4);
  });
});
