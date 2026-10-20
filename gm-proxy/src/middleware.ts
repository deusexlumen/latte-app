/*
 * PURPOSE: Auth- (x-lobby-token) und Fixfenster-Rate-Limit-Middleware für den GM-Proxy, rein und testbar
 * ARCHITECTURE: gm-proxy/middleware
 * DEPENDENCIES: node:crypto, node:http
 * PIPELINE: runtime, test
 * LAST_VALIDATED: 2026-09-18
 */
import { timingSafeEqual } from 'node:crypto';
import type { IncomingMessage } from 'node:http';

export const AUTH_HEADER = 'x-lobby-token';

export type AuthCheck = (req: IncomingMessage) => boolean;

const safeTokenEqual = (a: string, b: string): boolean => {
  const left = Buffer.from(a, 'utf8');
  const right = Buffer.from(b, 'utf8');
  return left.length === right.length && timingSafeEqual(left, right);
};

/**
 * Token-Auth-Factory: `null` = offener Dev-Modus (kein/ leerer Token konfiguriert),
 * sonst Prüffunktion auf den `x-lobby-token`-Header (timing-sicher).
 */
export function createAuthCheck(authToken?: string): AuthCheck | null {
  const token = authToken?.trim();
  if (!token) return null;
  return (req) => {
    const header = req.headers[AUTH_HEADER];
    return typeof header === 'string' && safeTokenEqual(header, token);
  };
}

export interface RateLimitOutcome {
  allowed: boolean;
  retryAfterSeconds: number;
}

export type RateLimitCheck = (key: string) => RateLimitOutcome;

export interface RateLimiterOptions {
  /** Max. Requests pro Fenster und Schlüssel; <= 0 deaktiviert das Limit. */
  limit: number;
  /** Fensterlänge in ms (Default 60_000). */
  windowMs?: number;
  /** Uhr-Injektion für deterministische Tests (Default Date.now). */
  now?: () => number;
}

interface Bucket {
  windowStart: number;
  count: number;
}

/** Fixfenster-Rate-Limiter pro Schlüssel (session_id, Fallback Client-IP). */
export function createRateLimiter(options: RateLimiterOptions): RateLimitCheck {
  const { limit } = options;
  const windowMs = options.windowMs ?? 60_000;
  const now = options.now ?? Date.now;
  const buckets = new Map<string, Bucket>();

  if (limit <= 0) {
    return () => ({ allowed: true, retryAfterSeconds: 0 });
  }

  return (key) => {
    const current = now();
    let bucket = buckets.get(key);
    if (bucket === undefined || current - bucket.windowStart >= windowMs) {
      bucket = { windowStart: current, count: 0 };
      buckets.set(key, bucket);
    }
    bucket.count += 1;
    if (bucket.count <= limit) {
      return { allowed: true, retryAfterSeconds: 0 };
    }
    const retryAfterMs = bucket.windowStart + windowMs - current;
    return { allowed: false, retryAfterSeconds: Math.max(1, Math.ceil(retryAfterMs / 1000)) };
  };
}

/** Rate-Limit-Schlüssel: `session_id` aus dem geparsten JSON-Body, Fallback Client-IP. */
export function rateLimitKey(body: unknown, req: IncomingMessage): string {
  if (typeof body === 'object' && body !== null) {
    const sessionId = (body as Record<string, unknown>).session_id;
    if (typeof sessionId === 'string' && sessionId.length > 0) return sessionId;
  }
  return req.socket.remoteAddress ?? 'unknown';
}

/**
 * CORS für den Web-Export: Der Browser-Build läuft auf einer anderen Origin
 * (z. B. itch.zone) und schickt `x-lobby-token` und JSON, also mit Preflight.
 * `origins` leer → keine CORS-Header (wie bisher). `*` erlaubt jede Origin.
 * Liefert die Header für eine Anfrage-Origin oder null, wenn sie nicht erlaubt ist.
 */
export function corsHeaders(origins: string[], requestOrigin: string | undefined): Record<string, string> | null {
  if (origins.length === 0 || requestOrigin === undefined) return null;
  const allowed = origins.includes('*') ? '*' : origins.includes(requestOrigin) ? requestOrigin : null;
  if (allowed === null) return null;
  return {
    'Access-Control-Allow-Origin': allowed,
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': `content-type, ${AUTH_HEADER}`,
    'Access-Control-Max-Age': '600',
    ...(allowed === '*' ? {} : { Vary: 'Origin' }),
  };
}

/** GM_CORS_ORIGINS="https://a.example,https://b.example" oder "*". */
export function parseCorsOrigins(raw: string | undefined): string[] {
  return (raw ?? '').split(',').map((o) => o.trim()).filter((o) => o.length > 0);
}
