import Anthropic from '@anthropic-ai/sdk';
import { GenerateIdeasResponse, GenerateIdeasResponseSchema, sanitizeAndCheckSkeleton } from './validator';

export interface IdeaGenerationRequest {
  image_base64: string;
  people_count_hint?: number;
  user_preferences?: {
    preferred_styles?: string[];
    liked_ideas?: string[];
    disliked_ideas?: string[];
  };
  language?: string;
}

const SYSTEM_PROMPT = `You are an award-winning editorial photographer, creative director, and posing coach.
Study the provided snapshot: location type, lighting quality and direction, background, props, free space, number of people and their placement, outfit colors and styles.
Create 5-6 distinct, creative, achievable photo ideas that use what is actually in the scene (for example, a wall to lean on, stairs to walk up, golden backlight for a silhouette).
Vary the styles across ideas (candid, editorial, romantic, funny, dramatic).
For each person in each idea, specify their target pose as 17 normalized keypoints in COCO/MoveNet order (x and y from 0 to 1 in the frame) plus a plain-language description:
0:nose, 1:left_eye, 2:right_eye, 3:left_ear, 4:right_ear, 5:left_shoulder, 6:right_shoulder, 7:left_elbow, 8:right_elbow, 9:left_wrist, 10:right_wrist, 11:left_hip, 12:right_hip, 13:left_knee, 14:right_knee, 15:left_ankle, 16:right_ankle.
Return ONLY valid raw JSON matching the required schema. No markdown formatting.`;

export class ClaudeVisionService {
  private client: Anthropic;

  constructor(apiKey?: string) {
    this.client = new Anthropic({
      apiKey: apiKey || process.env.ANTHROPIC_API_KEY || ''
    });
  }

  async generateIdeas(req: IdeaGenerationRequest): Promise<GenerateIdeasResponse> {
    // Attempt with 1 retry on format or validation error
    let lastError: Error | null = null;

    for (let attempt = 1; attempt <= 2; attempt++) {
      try {
        const result = await this.callClaudeWithTimeout(req, attempt);
        return result;
      } catch (err: any) {
        lastError = err;
        console.warn(`Attempt ${attempt} failed: ${err.message}`);
        if (attempt === 2) break;
      }
    }

    throw lastError || new Error('Failed to generate valid photo ideas after retries.');
  }

  private async callClaudeWithTimeout(req: IdeaGenerationRequest, attempt: number): Promise<GenerateIdeasResponse> {
    // Detect image media type (default jpeg)
    let mediaType: 'image/jpeg' | 'image/png' = 'image/jpeg';
    let base64Data = req.image_base64;
    if (base64Data.startsWith('data:image/png;base64,')) {
      mediaType = 'image/png';
      base64Data = base64Data.replace('data:image/png;base64,', '');
    } else if (base64Data.startsWith('data:image/jpeg;base64,')) {
      base64Data = base64Data.replace('data:image/jpeg;base64,', '');
    }

    // Build user prompt with hints
    const userPrompt = {
      people_count_hint: req.people_count_hint ?? 1,
      user_preferences: req.user_preferences ?? {},
      language: req.language ?? 'en',
      retry_note: attempt > 1 ? 'Previous output was malformed. Ensure 100% valid JSON with all 17 COCO keypoints.' : undefined
    };

    // 15 seconds timeout
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 15000);

    try {
      const response = await this.client.messages.create(
        {
          model: 'claude-3-5-sonnet-20241022',
          max_tokens: 3000,
          system: SYSTEM_PROMPT,
          messages: [
            {
              role: 'user',
              content: [
                {
                  type: 'image',
                  source: {
                    type: 'base64',
                    media_type: mediaType,
                    data: base64Data
                  }
                },
                {
                  type: 'text',
                  text: `Analyze this image and return 5-6 tailored photo ideas in JSON: ${JSON.stringify(userPrompt)}`
                }
              ]
            }
          ]
        },
        { signal: controller.signal }
      );

      clearTimeout(timeoutId);

      // Extract raw text
      const content = response.content[0];
      if (content.type !== 'text') {
        throw new Error('Claude response was not text');
      }

      // Clean JSON string if enclosed in markdown
      let text = content.text.trim();
      if (text.startsWith('```json')) {
        text = text.substring(7);
      }
      if (text.startsWith('```')) {
        text = text.substring(3);
      }
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3);
      }
      text = text.trim();

      const parsed = JSON.parse(text);
      const validated = GenerateIdeasResponseSchema.parse(parsed);

      // Sanitize skeletons across all ideas
      for (const idea of validated.ideas) {
        for (const person of idea.people) {
          const check = sanitizeAndCheckSkeleton(person.keypoints);
          person.keypoints = check.sanitized;
        }
      }

      return validated;
    } finally {
      clearTimeout(timeoutId);
    }
  }
}
