import crypto from 'crypto';
import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { GenerateIdeasRequestSchema, MAX_DECODED_IMAGE_BYTES } from './schema';
import { verifyAuthToken } from './auth';
import { checkAndIncrementUserDailyLimit, checkIpRateLimit } from './rateLimit';
import { AiService, hashUid } from './ai';
import { AppError } from './errors';

// Secret definition for Firebase Secret Manager
export const anthropicApiKey = defineSecret('ANTHROPIC_API_KEY');

export const generateIdeas = onRequest(
  {
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 60,
    maxInstances: 50,
    secrets: [anthropicApiKey]
  },
  async (req, res): Promise<void> => {
    const requestId = crypto.randomUUID();
    const startTime = Date.now();
    let currentUid = 'anonymous';

    try {
      // 1. Method check: POST only
      if (req.method !== 'POST') {
        throw AppError.invalidRequest('Method not allowed. Use POST /generateIdeas');
      }

      // 2. IP-level rate limiting
      const clientIp = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() || req.ip || '127.0.0.1';
      checkIpRateLimit(clientIp);

      // 3. Body size guard (Raw request body limit: 3 MB)
      const contentLength = parseInt(req.headers['content-length'] || '0', 10);
      if (contentLength > 3 * 1024 * 1024) {
        throw AppError.imageTooLarge('Request payload exceeds maximum allowed size of 3 MB');
      }

      // 4. Firebase Authentication verification
      currentUid = await verifyAuthToken(req);

      // 5. Parse and validate request schema with Zod
      const parseResult = GenerateIdeasRequestSchema.safeParse(req.body);
      if (!parseResult.success) {
        const issues = parseResult.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join(', ');
        throw AppError.invalidRequest(`Invalid request body: ${issues}`);
      }
      const requestData = parseResult.data;

      // 6. Decode Base64 and validate JPEG binary format & size limits
      let imageBuffer: Buffer;
      try {
        imageBuffer = Buffer.from(requestData.image_base64, 'base64');
      } catch (_) {
        throw AppError.invalidRequest('Failed to decode base64 image data');
      }

      // Check max 1.5 MB decoded
      if (imageBuffer.length > MAX_DECODED_IMAGE_BYTES) {
        throw AppError.imageTooLarge(
          `Decoded image size of ${(imageBuffer.length / (1024 * 1024)).toFixed(2)} MB exceeds maximum allowed limit of 1.5 MB`
        );
      }

      // Verify JPEG magic bytes (FF D8 FF)
      if (
        imageBuffer.length < 3 ||
        imageBuffer[0] !== 0xff ||
        imageBuffer[1] !== 0xd8 ||
        imageBuffer[2] !== 0xff
      ) {
        throw AppError.invalidRequest('Invalid image format. Only JPEG format (magic bytes FF D8 FF) is accepted');
      }

      // 7. Atomic user daily rate limiting in Firestore
      const rateLimitResult = await checkAndIncrementUserDailyLimit(currentUid);
      res.setHeader('X-RateLimit-Remaining', rateLimitResult.remaining.toString());
      res.setHeader('X-RateLimit-Reset', rateLimitResult.resetTime);

      // 8. Call Anthropic Claude Vision API
      const apiKey = anthropicApiKey.value() || process.env.ANTHROPIC_API_KEY;
      if (!apiKey) {
        console.error('Missing ANTHROPIC_API_KEY secret');
        throw AppError.aiInvalidResponse('AI service configuration error');
      }

      const aiService = new AiService(apiKey);
      const response = await aiService.generateIdeasWithRetry(requestData, {
        requestId,
        uid: currentUid
      });

      const totalDurationMs = Date.now() - startTime;
      console.log(
        JSON.stringify({
          event: 'request_completed',
          requestId,
          uidHash: hashUid(currentUid),
          totalDurationMs,
          ideasReturned: response.ideas.length
        })
      );

      res.status(200).json(response);
    } catch (err: any) {
      const totalDurationMs = Date.now() - startTime;
      const appError: AppError =
        err instanceof AppError
          ? err
          : AppError.aiInvalidResponse(err.message || 'An unexpected error occurred');

      console.error(
        JSON.stringify({
          event: 'request_error',
          requestId,
          uidHash: hashUid(currentUid),
          statusCode: appError.statusCode,
          errorCode: appError.code,
          errorMessage: appError.message,
          totalDurationMs
        })
      );

      res.status(appError.statusCode).json(appError.toResponseBody());
    }
  }
);
