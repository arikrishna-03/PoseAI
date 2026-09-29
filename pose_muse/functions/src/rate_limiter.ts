interface RateLimitRecord {
  count: number;
  resetTime: number;
}

export class RateLimiter {
  private static records = new Map<string, RateLimitRecord>();
  private static readonly MAX_SCANS_PER_DAY = 30;
  private static readonly WINDOW_MS = 24 * 60 * 60 * 1000; // 24 hours

  static checkLimit(userId: string): { allowed: boolean; remaining: number; resetTime: number } {
    const now = Date.now();
    const record = this.records.get(userId);

    if (!record || now > record.resetTime) {
      const newRecord: RateLimitRecord = {
        count: 1,
        resetTime: now + this.WINDOW_MS
      };
      this.records.set(userId, newRecord);
      return {
        allowed: true,
        remaining: this.MAX_SCANS_PER_DAY - 1,
        resetTime: newRecord.resetTime
      };
    }

    if (record.count >= this.MAX_SCANS_PER_DAY) {
      return {
        allowed: false,
        remaining: 0,
        resetTime: record.resetTime
      };
    }

    record.count += 1;
    return {
      allowed: true,
      remaining: this.MAX_SCANS_PER_DAY - record.count,
      resetTime: record.resetTime
    };
  }
}
