import crypto from 'crypto';
import Anthropic from '@anthropic-ai/sdk';
import { GenerateIdeasRequest, GenerateIdeasResponse } from './schema';
import { SYSTEM_PROMPT } from './prompts/systemPrompt';
import { validateAiResponse } from './validate';
import { AppError } from './errors';

export interface AiCallContext {
  requestId: string;
  uid: string;
}

export function hashUid(uid: string): string {
  return crypto.createHash('sha256').update(uid).digest('hex').substring(0, 16);
}

export class AiService {
  private client: Anthropic;
  private model: string;

  constructor(apiKey: string) {
    this.client = new Anthropic({ apiKey });
    this.model = process.env.ANTHROPIC_MODEL || 'claude-sonnet-5-5';
  }

  /**
   * Generates photo ideas using Claude Vision API.
   * Retries once on timeout or invalid JSON / schema failure.
   */
  async generateIdeasWithRetry(
    request: GenerateIdeasRequest,
    context: AiCallContext
  ): Promise<GenerateIdeasResponse> {
    const uidHash = hashUid(context.uid);
    let lastError: AppError | Error | null = null;

    for (let attempt = 1; attempt <= 2; attempt++) {
      const startTime = Date.now();
      try {
        const response = await this.callClaudeOnce(request, attempt);
        const latencyMs = Date.now() - startTime;

        // Structured logging
        console.log(
          JSON.stringify({
            event: 'ai_call_success',
            requestId: context.requestId,
            uidHash,
            attempt,
            model: this.model,
            latencyMs,
            ideasCount: response.ideas.length,
            peopleCount: response.scene.people_count
          })
        );

        return response;
      } catch (err: any) {
        const latencyMs = Date.now() - startTime;
        console.warn(
          JSON.stringify({
            event: 'ai_call_attempt_failed',
            requestId: context.requestId,
            uidHash,
            attempt,
            model: this.model,
            latencyMs,
            errorMessage: err.message
          })
        );

        lastError = err;

        // If the error was specifically no_people_found (422), do not retry
        if (err instanceof AppError && err.code === 'no_people_found') {
          throw err;
        }

        // On attempt 1, loop will retry once. On attempt 2, loop exits.
      }
    }

    // Both attempts failed
    if (lastError instanceof AppError) {
      throw lastError;
    }
    throw AppError.aiInvalidResponse(lastError?.message || 'Failed to generate valid ideas after retry');
  }

  private async callClaudeOnce(
    request: GenerateIdeasRequest,
    attempt: number
  ): Promise<GenerateIdeasResponse> {
    // 20 seconds timeout
    const controller = new AbortController();
    const timeoutHandle = setTimeout(() => controller.abort(), 20000);

    const userPromptPayload = {
      people_count_hint: request.people_count_hint,
      style_preference: request.style_preference,
      liked_titles: request.liked_titles,
      disliked_titles: request.disliked_titles,
      language: request.language,
      ...(attempt > 1
        ? { retry_directive: 'CRITICAL: The previous output failed schema or skeleton validation. Ensure 100% valid JSON with anatomically correct 17 COCO keypoints.' }
        : {})
    };

    try {
      const message = await this.client.messages.create(
        {
          model: this.model,
          max_tokens: 4000,
          temperature: 0.9,
          system: SYSTEM_PROMPT,
          messages: [
            {
              role: 'user',
              content: [
                {
                  type: 'image',
                  source: {
                    type: 'base64',
                    media_type: 'image/jpeg',
                    data: request.image_base64
                  }
                },
                {
                  type: 'text',
                  text: `Analyze the scene and generate 5 to 6 photo ideas: ${JSON.stringify(userPromptPayload)}`
                }
              ]
            }
          ]
        },
        { signal: controller.signal }
      );

      clearTimeout(timeoutHandle);

      // Log token usage
      if (message.usage) {
        console.log(
          JSON.stringify({
            event: 'token_usage',
            inputTokens: message.usage.input_tokens,
            outputTokens: message.usage.output_tokens
          })
        );
      }

      const textBlock = message.content.find((c) => c.type === 'text');
      if (!textBlock || textBlock.type !== 'text') {
        throw AppError.aiInvalidResponse('Claude response did not contain text content');
      }

      // Strip markdown fences before JSON.parse
      let rawText = textBlock.text.trim();
      if (rawText.startsWith('```json')) {
        rawText = rawText.substring(7);
      } else if (rawText.startsWith('```')) {
        rawText = rawText.substring(3);
      }
      if (rawText.endsWith('```')) {
        rawText = rawText.substring(0, rawText.length - 3);
      }
      rawText = rawText.trim();

      let parsed: unknown;
      try {
        parsed = JSON.parse(rawText);
      } catch (parseErr: any) {
        throw AppError.aiInvalidResponse(`Malformed JSON returned by AI: ${parseErr.message}`);
      }

      const validation = validateAiResponse(parsed);
      if (!validation.success) {
        throw validation.error || AppError.aiInvalidResponse();
      }

      return validation.data!;
    } catch (err: any) {
      clearTimeout(timeoutHandle);
      if (err.name === 'AbortError' || err.message?.includes('aborted')) {
        throw AppError.aiTimeout();
      }
      throw err;
    }
  }
}
