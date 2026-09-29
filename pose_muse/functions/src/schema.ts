import { z } from 'zod';

export const MAX_DECODED_IMAGE_BYTES = 1.5 * 1024 * 1024; // 1.5 MB

/**
 * Validates request body for POST /generateIdeas
 */
export const GenerateIdeasRequestSchema = z.object({
  image_base64: z
    .string({ required_error: 'image_base64 is required' })
    .refine((val) => !val.startsWith('data:'), {
      message: 'image_base64 must not contain data URL prefix (e.g. data:image/jpeg;base64,)'
    })
    .refine((val) => /^[A-Za-z0-9+/=]+$/.test(val.replace(/\s+/g, '')), {
      message: 'image_base64 contains invalid base64 characters'
    }),
  people_count_hint: z
    .number()
    .int()
    .min(0, 'people_count_hint must be between 0 and 10')
    .max(10, 'people_count_hint must be between 0 and 10')
    .default(0),
  style_preference: z
    .enum(['any', 'candid', 'fashion', 'romantic', 'fun'])
    .default('any'),
  liked_titles: z
    .array(z.string().max(100))
    .max(10, 'liked_titles cannot exceed 10 items')
    .default([]),
  disliked_titles: z
    .array(z.string().max(100))
    .max(10, 'disliked_titles cannot exceed 10 items')
    .default([]),
  language: z
    .string()
    .min(2)
    .max(10)
    .default('en')
});

export type GenerateIdeasRequest = z.infer<typeof GenerateIdeasRequestSchema>;

/**
 * Single 2D normalized keypoint in frame (0 to 1, y increases downward)
 */
export const KeypointSchema = z.object({
  x: z.number().min(0).max(1),
  y: z.number().min(0).max(1)
});

export type Keypoint = z.infer<typeof KeypointSchema>;

/**
 * Person target pose in COCO / MoveNet 17 keypoint order
 */
export const PersonPoseSchema = z.object({
  position: z.enum(['left', 'center', 'right']),
  description: z.string().min(1, 'description cannot be empty'),
  keypoints: z
    .array(KeypointSchema)
    .length(17, 'keypoints must contain exactly 17 COCO landmarks')
});

export type PersonPose = z.infer<typeof PersonPoseSchema>;

export const CameraTipsSchema = z.object({
  height: z.string(),
  angle: z.string(),
  distance: z.string(),
  orientation: z.enum(['portrait', 'landscape'])
});

export type CameraTips = z.infer<typeof CameraTipsSchema>;

/**
 * Individual Photo Idea Schema
 */
export const IdeaSchema = z.object({
  title: z
    .string()
    .min(1, 'Title cannot be empty')
    .max(60, 'Title cannot exceed 60 characters'),
  why_it_works: z
    .string()
    .min(5, 'why_it_works must reference scene elements')
    .max(200, 'why_it_works cannot exceed 200 characters'),
  style: z.enum(['candid', 'editorial', 'romantic', 'funny', 'dramatic', 'casual']),
  difficulty: z.enum(['easy', 'medium', 'hard']),
  camera_tips: CameraTipsSchema,
  expression_tip: z.string().min(1, 'expression_tip cannot be empty'),
  people: z.array(PersonPoseSchema).min(1, 'At least one person pose required')
});

export type Idea = z.infer<typeof IdeaSchema>;

/**
 * Scene Analysis Schema
 */
export const SceneSchema = z.object({
  location_type: z.string().min(1),
  lighting: z.string().min(1),
  people_count: z.number().int().min(0),
  outfit_summary: z.string().min(1),
  props: z.array(z.string())
});

export type Scene = z.infer<typeof SceneSchema>;

/**
 * Complete Success Response Schema
 */
export const GenerateIdeasResponseSchema = z
  .object({
    scene: SceneSchema,
    ideas: z
      .array(IdeaSchema)
      .min(5, 'At least 5 photo ideas required')
      .max(6, 'Maximum 6 photo ideas allowed')
  })
  .refine(
    (data) => {
      // The number of entries in people must match scene.people_count for every idea
      return data.ideas.every((idea) => idea.people.length === data.scene.people_count);
    },
    {
      message: 'Every idea people array length must match scene.people_count'
    }
  );

export type GenerateIdeasResponse = z.infer<typeof GenerateIdeasResponseSchema>;
