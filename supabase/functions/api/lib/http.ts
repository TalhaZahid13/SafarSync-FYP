// Minimal Express-style router for the api function.
import type { AuthCtx } from "./auth.ts";

export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, stripe-signature",
  "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
};

export class HttpError extends Error {
  constructor(public status: number, public body: Record<string, unknown>) {
    super(String(body.error ?? body.message ?? status));
  }
}

export const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

/** Throw a JSON error response (same `{ error }` shape the Express API used). */
export const fail = (status: number, error: string, extra: Record<string, unknown> = {}): never => {
  throw new HttpError(status, { error, ...extra });
};

export type Access = "public" | "optional" | "user" | "admin";

export interface Ctx {
  req: Request;
  params: Record<string, string>;
  query: URLSearchParams;
  body: any;
  rawBody: string;
  ip: string;
  auth: AuthCtx; // non-null for user/admin routes
  authOrNull: AuthCtx | null;
}

export type Handler = (c: Ctx) => Promise<Response> | Response;

interface Route {
  method: string;
  parts: string[];
  access: Access;
  handler: Handler;
}

export class Router {
  private routes: Route[] = [];

  add(method: string, path: string, access: Access, handler: Handler) {
    this.routes.push({ method, parts: path.split("/").filter(Boolean), access, handler });
    return this;
  }
  get(p: string, a: Access, h: Handler) { return this.add("GET", p, a, h); }
  post(p: string, a: Access, h: Handler) { return this.add("POST", p, a, h); }
  put(p: string, a: Access, h: Handler) { return this.add("PUT", p, a, h); }
  delete(p: string, a: Access, h: Handler) { return this.add("DELETE", p, a, h); }

  match(method: string, path: string): { route: Route; params: Record<string, string> } | null {
    const segs = path.split("/").filter(Boolean).map(decodeURIComponent);
    for (const route of this.routes) {
      if (route.method !== method || route.parts.length !== segs.length) continue;
      const params: Record<string, string> = {};
      let ok = true;
      for (let i = 0; i < segs.length; i++) {
        const p = route.parts[i];
        if (p.startsWith(":")) params[p.slice(1)] = segs[i];
        else if (p !== segs[i]) { ok = false; break; }
      }
      if (ok) return { route, params };
    }
    return null;
  }
}

// ── small parsing helpers ───────────────────────────────────────────────────
export const toInt = (v: unknown, fallback: number | null = null): number | null => {
  const n = parseInt(String(v ?? ""), 10);
  return Number.isFinite(n) ? n : fallback;
};
export const toNum = (v: unknown): number | null => {
  if (v === null || v === undefined || v === "") return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
};
export const idParam = (v: string | undefined): number => {
  const n = toInt(v);
  if (n === null || n <= 0) fail(400, "Invalid id");
  return n as number;
};
export const text = (v: unknown, max = 255): string | null => {
  if (typeof v !== "string") return null;
  const t = v.trim();
  return t ? t.slice(0, max) : null;
};
export const clampLimit = (v: unknown, def: number, max = 200) =>
  Math.min(Math.max(toInt(v, def) ?? def, 1), max);
