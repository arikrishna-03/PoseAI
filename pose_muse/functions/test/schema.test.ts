import { describe, it, expect } from 'vitest';
import { GenerateIdeasRequestSchema, GenerateIdeasResponseSchema } from '../src/schema';

describe('Schema Unit Tests', () => {
  it('validates a valid GenerateIdeasRequest', () => {
    const validReq = {
      image_base64: Buffer.from([0xff, 0xd8, 0xff, 0xe0]).toString('base64'),
      people_count_hint: 2,
      style_preference: 'candid',
      liked_titles: ['Sunset Lean', 'Coffee Walk'],
      disliked_titles: ['Stiff Corporate'],
      language: 'en'
    };

    const parsed = GenerateIdeasRequestSchema.safeParse(validReq);
    expect(parsed.success).toBe(true);
  });

  it('rejects image_base64 with data: prefix', () => {
    const invalidReq = {
      image_base64: 'data:image/jpeg;base64,/9j/4AAQSkZJRg==',
      people_count_hint: 1
    };

    const parsed = GenerateIdeasRequestSchema.safeParse(invalidReq);
    expect(parsed.success).toBe(false);
  });

  it('rejects people_count_hint outside 0-10', () => {
    const invalidReq = {
      image_base64: 'dGVzdA==',
      people_count_hint: 15
    };

    const parsed = GenerateIdeasRequestSchema.safeParse(invalidReq);
    expect(parsed.success).toBe(false);
  });

  it('rejects liked_titles exceeding 10 items', () => {
    const invalidReq = {
      image_base64: 'dGVzdA==',
      liked_titles: Array.from({ length: 11 }, (_, i) => `Idea ${i}`)
    };

    const parsed = GenerateIdeasRequestSchema.safeParse(invalidReq);
    expect(parsed.success).toBe(false);
  });

  it('validates GenerateIdeasResponseSchema when people count matches scene', () => {
    const validPoints = Array.from({ length: 17 }, () => ({ x: 0.5, y: 0.5 }));
    const sampleResponse = {
      scene: {
        location_type: 'Park Pathway',
        lighting: 'Golden Hour Backlight',
        people_count: 1,
        outfit_summary: 'Casual denim jacket',
        props: ['Benches', 'Trees']
      },
      ideas: Array.from({ length: 5 }, (_, i) => ({
        title: `Dynamic Park Idea ${i}`,
        why_it_works: 'Takes advantage of the sun flare through the trees.',
        style: 'candid',
        difficulty: 'easy',
        camera_tips: {
          height: 'waist-level',
          angle: '45-degree',
          distance: 'full-body',
          orientation: 'portrait'
        },
        expression_tip: 'Natural walking glance back.',
        people: [
          {
            position: 'center',
            description: 'Mid-step stroll walking away then looking back.',
            keypoints: validPoints
          }
        ]
      }))
    };

    const parsed = GenerateIdeasResponseSchema.safeParse(sampleResponse);
    expect(parsed.success).toBe(true);
  });

  it('rejects GenerateIdeasResponseSchema when people count does not match idea people array length', () => {
    const validPoints = Array.from({ length: 17 }, () => ({ x: 0.5, y: 0.5 }));
    const mismatchedResponse = {
      scene: {
        location_type: 'Park Pathway',
        lighting: 'Golden Hour Backlight',
        people_count: 2, // Scene specifies 2 people
        outfit_summary: 'Casual denim jacket',
        props: ['Benches']
      },
      ideas: Array.from({ length: 5 }, (_, i) => ({
        title: `Mismatched Idea ${i}`,
        why_it_works: 'Test idea description referencing scene.',
        style: 'candid',
        difficulty: 'easy',
        camera_tips: {
          height: 'eye-level',
          angle: 'straight-on',
          distance: 'medium',
          orientation: 'portrait'
        },
        expression_tip: 'Smile',
        people: [
          // But only 1 person is provided!
          {
            position: 'center',
            description: 'Solo person pose',
            keypoints: validPoints
          }
        ]
      }))
    };

    const parsed = GenerateIdeasResponseSchema.safeParse(mismatchedResponse);
    expect(parsed.success).toBe(false);
  });
});
