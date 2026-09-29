import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { ClaudeVisionService } from './claude_service';
import { RateLimiter } from './rate_limiter';

dotenv.config();

const app = express();
const port = process.env.PORT || 8080;

// Middleware
app.use(cors({ origin: true }));
// Limit request size to 6MB for base64 images
app.use(express.json({ limit: '6mb' }));

const claudeService = new ClaudeVisionService();

// Health check
app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok', service: 'PoseMuse Vision AI Backend' });
});

/**
 * POST /generate-ideas
 * Body: { image_base64, people_count_hint, user_preferences, language }
 */
app.post('/generate-ideas', async (req: Request, res: Response): Promise<void> => {
  try {
    // 1. Client identification & Anonymous Auth
    const authHeader = req.headers.authorization;
    const clientId = (authHeader ? authHeader.replace('Bearer ', '') : req.ip) || 'anonymous-user';

    // 2. Rate limiting check (30 scans per day)
    const rateCheck = RateLimiter.checkLimit(clientId);
    res.setHeader('X-RateLimit-Remaining', rateCheck.remaining);

    if (!rateCheck.allowed) {
      res.status(429).json({
        error: 'Rate limit reached',
        message: 'You have reached your limit of 30 scans per day. Resets in 24 hours.'
      });
      return;
    }

    // 3. Request payload validation
    const { image_base64, people_count_hint, user_preferences, language } = req.body;
    if (!image_base64 || typeof image_base64 !== 'string') {
      res.status(400).json({ error: 'Missing or invalid image_base64 parameter' });
      return;
    }

    // 4. Generate ideas via Claude Vision AI
    const result = await claudeService.generateIdeas({
      image_base64,
      people_count_hint,
      user_preferences,
      language
    });

    res.json(result);
  } catch (err: any) {
    console.error('Error generating ideas:', err);
    if (err.name === 'AbortError') {
      res.status(504).json({ error: 'Vision AI request timed out. Please try again.' });
      return;
    }
    res.status(500).json({
      error: 'Failed to generate ideas',
      message: err.message || 'Unknown server error'
    });
  }
});

app.listen(port, () => {
  console.log(`PoseMuse Backend running on port ${port}`);
});

export default app;
