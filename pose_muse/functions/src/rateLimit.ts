import * as admin from 'firebase-admin';
import { AppError } from './errors';

// In-memory sliding window IP rate limiter (second defense layer)
interface IpWindow {
  count: number;
  resetAt: number;
}
const ipBuckets = new Map<string, IpWindow>();
const IP_WINDOW_MS = 60 * 1000; // 1 minute
const MAX_REQUESTS_PER_IP_MINUTE = 60;

/**
 * Checks in-memory rate limit by IP address.
 */
export function checkIpRateLimit(ip: string): void {
  const now = Date.now();
  const bucket = ipBuckets.get(ip);

  if (!bucket || now > bucket.resetAt) {
    ipBuckets.set(ip, { count: 1, resetAt: now + IP_WINDOW_MS });
    return;
  }

  if (bucket.count >= MAX_REQUESTS_PER_IP_MINUTE) {
    const resetTime = new Date(bucket.resetAt).toISOString();
    throw AppError.rateLimited(resetTime, 'Too many requests from this IP address. Please slow down.');
  }

  bucket.count += 1;
}

/**
 * Atomic Firestore transaction checking and incrementing daily scans for a user.
 * Document: usage/{uid}_{YYYY-MM-DD}
 */
export async function checkAndIncrementUserDailyLimit(uid: string): Promise<{ remaining: number; resetTime: string }> {
  const dailyLimit = parseInt(process.env.DAILY_LIMIT || '30', 10);

  const now = new Date();
  const yyyy = now.getUTCFullYear();
  const mm = String(now.getUTCMonth() + 1).padStart(2, '0');
  const dd = String(now.getUTCDate()).padStart(2, '0');
  const dateKey = `${yyyy}-${mm}-${dd}`;
  const docId = `${uid}_${dateKey}`;

  // Next reset time is midnight UTC
  const resetDate = new Date(Date.UTC(yyyy, now.getUTCMonth(), now.getUTCDate() + 1, 0, 0, 0));
  const resetTimeIso = resetDate.toISOString();

  const db = admin.firestore();
  const usageRef = db.collection('usage').doc(docId);

  return await db.runTransaction(async (transaction) => {
    const doc = await transaction.get(usageRef);
    let currentCount = 0;

    if (doc.exists) {
      currentCount = doc.data()?.count || 0;
    }

    if (currentCount >= dailyLimit) {
      throw AppError.rateLimited(
        resetTimeIso,
        `Daily scan limit of ${dailyLimit} reached. Resets at ${resetTimeIso}`
      );
    }

    const nextCount = currentCount + 1;
    transaction.set(
      usageRef,
      {
        uid,
        date: dateKey,
        count: nextCount,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      },
      { merge: true }
    );

    return {
      remaining: Math.max(0, dailyLimit - nextCount),
      resetTime: resetTimeIso
    };
  });
}
