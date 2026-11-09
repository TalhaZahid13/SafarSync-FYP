// Supabase Auth JWT verification + mapping to the integer SafarSync user id.
import { q1, type Row } from "./db.ts";
import { fail } from "./http.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

export interface AuthUser {
  id: string;
  email?: string;
  email_confirmed_at?: string | null;
  app_metadata?: Record<string, any>;
  user_metadata?: Record<string, any>;
}

export interface AdminInfo {
  adminId: number;
  adminName: string;
  email: string;
  role: string; // 'super_admin' | 'moderator' | 'admin'
}

export interface AuthCtx {
  authUser: AuthUser;
  token: string;
  userId: number;
  email: string;
  name: string;
  role: string;
  isAdmin: boolean;
  user: Row;
  admin: AdminInfo | null; // resolved lazily for admin routes
}

// Short-lived cache of verified tokens (per isolate) so a burst of requests
// does not re-verify the same JWT against the Auth server every time.
const cache = new Map<string, { user: AuthUser; until: number }>();

async function verifyToken(token: string): Promise<AuthUser | null> {
  const hit = cache.get(token);
  if (hit && hit.until > Date.now()) return hit.user;
  const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: { Authorization: `Bearer ${token}`, apikey: ANON_KEY },
  });
  if (!res.ok) return null;
  const user = (await res.json()) as AuthUser;
  if (!user?.id) return null;
  if (cache.size > 500) cache.clear();
  cache.set(token, { user, until: Date.now() + 60_000 });
  return user;
}

const providerOf = (u: AuthUser) => {
  const p = String(u.app_metadata?.provider ?? "email").toLowerCase();
  return p === "google" ? "GOOGLE" : p === "apple" ? "APPLE" : p === "facebook" ? "FACEBOOK" : "EMAIL";
};

const USER_COLS = `user_id, email, full_name, is_admin, is_blocked, role, auth_provider,
                   profile_picture_url, suspended_at`;

/** Resolve the caller. Returns null when there is no (valid) bearer token. */
export async function authenticate(req: Request): Promise<AuthCtx | null> {
  const header = req.headers.get("authorization") ?? "";
  const token = header.toLowerCase().startsWith("bearer ") ? header.slice(7).trim() : "";
  // The publishable/anon key is not a user session.
  if (!token || token.split(".").length !== 3) return null;

  const authUser = await verifyToken(token);
  if (!authUser) return null;

  let user = await q1(`select ${USER_COLS} from public.users where auth_user_id = $1`, [authUser.id]);
  if (!user) {
    // Profile row should have been created by the auth trigger; self-heal if not.
    const meta = authUser.user_metadata ?? {};
    const email = String(authUser.email ?? `${authUser.id}@users.safarsync.app`).toLowerCase();
    user = await q1(
      `insert into public.users (auth_user_id, email, full_name, phone_number, blood_group,
                                 profile_picture_url, auth_provider, last_login_at)
       values ($1, $2, $3, $4, $5, $6, $7, now())
       on conflict (email) do update set auth_user_id = excluded.auth_user_id
         where public.users.auth_user_id is null
       returning ${USER_COLS}`,
      [authUser.id, email, meta.full_name || meta.name || email.split("@")[0],
       meta.phone_number ?? null, meta.blood_group ?? null,
       meta.avatar_url ?? meta.picture ?? null, providerOf(authUser)],
    );
    if (!user) fail(409, "This email is already linked to another account");
  }
  if (user!.is_blocked) fail(403, "Your account has been blocked. Please contact support.");

  return {
    authUser,
    token,
    userId: user!.user_id,
    email: user!.email,
    name: user!.full_name,
    role: user!.role ?? "user",
    isAdmin: !!user!.is_admin,
    user: user!,
    admin: null,
  };
}

/**
 * Admin resolution (replaces the old separate admin JWT):
 *   1. an active row in public.admins linked to this auth user, or
 *   2. a users row with is_admin = true (role 'admin'), or
 *   3. a not-yet-linked admins row whose email matches this *verified* account.
 */
export async function resolveAdmin(ctx: AuthCtx): Promise<AdminInfo | null> {
  if (ctx.admin) return ctx.admin;
  let a = await q1(
    `select admin_id, full_name, email, role from public.admins where auth_user_id = $1 and is_active`,
    [ctx.authUser.id],
  );
  if (!a && ctx.authUser.email && ctx.authUser.email_confirmed_at) {
    a = await q1(
      `update public.admins set auth_user_id = $1
        where lower(email) = lower($2) and auth_user_id is null and is_active
        returning admin_id, full_name, email, role`,
      [ctx.authUser.id, ctx.authUser.email],
    );
  }
  if (a) {
    ctx.admin = { adminId: a.admin_id, adminName: a.full_name, email: a.email, role: a.role };
  } else if (ctx.isAdmin) {
    ctx.admin = { adminId: ctx.userId, adminName: ctx.name, email: ctx.email, role: ctx.role || "admin" };
  }
  return ctx.admin;
}
