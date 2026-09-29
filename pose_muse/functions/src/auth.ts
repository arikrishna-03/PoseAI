import { Request } from 'express';
import * as admin from 'firebase-admin';
import { AppError } from './errors';

// Initialize firebase-admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Extracts and verifies the Firebase ID token from the Authorization header.
 * Returns the authenticated user ID (uid).
 * Throws AppError(401, 'unauthorized') if missing, malformed, or invalid.
 */
export async function verifyAuthToken(req: Request): Promise<string> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw AppError.unauthorized('Missing or malformed Authorization header. Expected Bearer <token>');
  }

  const idToken = authHeader.split('Bearer ')[1]?.trim();
  if (!idToken) {
    throw AppError.unauthorized('Bearer token is empty');
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    return decodedToken.uid;
  } catch (err: any) {
    throw AppError.unauthorized(`Invalid or expired token: ${err.message || 'Verification failed'}`);
  }
}
