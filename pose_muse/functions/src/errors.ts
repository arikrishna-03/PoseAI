export type ErrorCode =
  | 'invalid_request'
  | 'unauthorized'
  | 'image_too_large'
  | 'no_people_found'
  | 'rate_limited'
  | 'ai_invalid_response'
  | 'ai_timeout';

export interface ErrorResponseBody {
  error: {
    code: ErrorCode;
    message: string;
    reset_time?: string;
  };
}

export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code: ErrorCode;
  public readonly resetTime?: string;

  constructor(statusCode: number, code: ErrorCode, message: string, resetTime?: string) {
    super(message);
    this.name = 'AppError';
    this.statusCode = statusCode;
    this.code = code;
    this.resetTime = resetTime;
  }

  toResponseBody(): ErrorResponseBody {
    return {
      error: {
        code: this.code,
        message: this.message,
        ...(this.resetTime ? { reset_time: this.resetTime } : {})
      }
    };
  }

  static invalidRequest(message: string): AppError {
    return new AppError(400, 'invalid_request', message);
  }

  static unauthorized(message = 'Missing or invalid authentication token'): AppError {
    return new AppError(401, 'unauthorized', message);
  }

  static imageTooLarge(message = 'Image exceeds maximum allowed size of 1.5 MB decoded'): AppError {
    return new AppError(413, 'image_too_large', message);
  }

  static noPeopleFound(message = 'No people were detected in the snapshot'): AppError {
    return new AppError(422, 'no_people_found', message);
  }

  static rateLimited(resetTime: string, message = 'Daily rate limit reached. Please try again tomorrow.'): AppError {
    return new AppError(429, 'rate_limited', message, resetTime);
  }

  static aiInvalidResponse(message = 'AI vision service returned an invalid or incomplete response'): AppError {
    return new AppError(502, 'ai_invalid_response', message);
  }

  static aiTimeout(message = 'AI vision service timed out. Please try again.'): AppError {
    return new AppError(504, 'ai_timeout', message);
  }
}
