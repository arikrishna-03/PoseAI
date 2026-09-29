import { describe, it } from 'node:test';
import assert from 'node:assert';
import { GenerateIdeasResponseSchema, sanitizeAndCheckSkeleton } from './validator';

describe('Backend Validator Tests', () => {
  it('validates a correct GenerateIdeas response against schema', () => {
    const validSample = {
      scene_analysis: {
        location_type: 'Cafe Patio',
        lighting: 'Warm afternoon sidelight',
        detected_props: ['Coffee cup', 'Cast iron table'],
        outfit_summary: 'Casual trench coat'
      },
      ideas: [
        {
          title: 'The Steaming Cup Sip',
          why_it_works: 'Takes advantage of the rustic cast iron table and soft afternoon light.',
          style: 'candid',
          difficulty: 'easy',
          camera_tips: {
            height: 'eye-level',
            angle: '45-degree',
            distance: 'medium',
            orientation: 'portrait'
          },
          expression_tip: 'Subtle warm smile looking down at the cup.',
          people: [
            {
              position: 'center',
              description: 'Seated leaning forward slightly with hands cupped around mug.',
              keypoints: Array.from({ length: 17 }, () => ({ x: 0.5, y: 0.5 }))
            }
          ]
        },
        {
          title: 'Looking Over the Mug',
          why_it_works: 'Frames the subject through the steam for an intimate portrait.',
          style: 'editorial',
          difficulty: 'medium',
          camera_tips: {
            height: 'eye-level',
            angle: 'straight-on',
            distance: 'close-up',
            orientation: 'portrait'
          },
          expression_tip: 'Direct gaze into camera over the rim.',
          people: [
            {
              position: 'center',
              description: 'Resting elbows on table, holding cup with both hands.',
              keypoints: Array.from({ length: 17 }, () => ({ x: 0.5, y: 0.5 }))
            }
          ]
        },
        {
          title: 'Laughing at the Menu',
          why_it_works: 'Natural candid moment catching spontaneous amusement.',
          style: 'fun',
          difficulty: 'easy',
          camera_tips: {
            height: 'waist-level',
            angle: '45-degree',
            distance: 'medium',
            orientation: 'portrait'
          },
          expression_tip: 'Open laugh, eyes squinting naturally.',
          people: [
            {
              position: 'center',
              description: 'Body turned sideways, glancing back towards photographer.',
              keypoints: Array.from({ length: 17 }, () => ({ x: 0.5, y: 0.5 }))
            }
          ]
        },
        {
          title: 'The Solitary Reader',
          why_it_works: 'High contrast shadows create a moody cinematic frame.',
          style: 'cinematic',
          difficulty: 'hard',
          camera_tips: {
            height: 'low-angle',
            angle: 'profile',
            distance: 'full-body',
            orientation: 'landscape'
          },
          expression_tip: 'Contemplative calm face.',
          people: [
            {
              position: 'center',
              description: 'Legs crossed, book propped against knee.',
              keypoints: Array.from({ length: 17 }, () => ({ x: 0.5, y: 0.5 }))
            }
          ]
        }
      ]
    };

    const parsed = GenerateIdeasResponseSchema.parse(validSample);
    assert.strictEqual(parsed.ideas.length, 4);
  });

  it('sanitizes and clamps keypoints outside [0, 1]', () => {
    const rawPoints = Array.from({ length: 17 }, () => ({ x: 0.5, y: 0.5 }));
    rawPoints[0] = { x: -0.2, y: 1.4 }; // out of bounds

    const result = sanitizeAndCheckSkeleton(rawPoints);
    assert.strictEqual(result.sanitized[0].x, 0.0);
    assert.strictEqual(result.sanitized[0].y, 1.0);
  });
});
