// Notifications + realtime fan-out (replaces global.io.emit from the Express server).
import { q, sql } from "./db.ts";

/**
 * Broadcast an event to a private Realtime topic.
 * Topics mirror the old Socket.io rooms:
 *   user:<id>, group:<id>, group-tracking:<id>, emergency:admin, broadcast:all
 * Authorization for subscribers is enforced by RLS on realtime.messages.
 */
export async function emit(topic: string, event: string, payload: unknown): Promise<void> {
  try {
    await sql.unsafe(`select realtime.send($1::text::jsonb, $2, $3, true)`, [
      JSON.stringify(payload ?? {}), event, topic,
    ]);
  } catch (e) {
    console.error(`[realtime] emit ${event} → ${topic} failed:`, (e as Error).message);
  }
}

/** Insert an in-app notification and push it live to the user. */
export async function notify(
  userId: number,
  title: string,
  message: string,
  type: string,
  actionUrl: string | null = null,
): Promise<void> {
  try {
    await q(
      `insert into public.notifications (user_id, title, message, type, action_url)
       values ($1, $2, $3, $4, $5)`,
      [userId, title, message, type, actionUrl],
    );
  } catch (e) {
    console.error("[notification] insert failed:", (e as Error).message);
  }
  await emit(`user:${userId}`, "notification:new", { title, message, type });
}

/** Run work after the response has been sent (fire-and-forget, like the old backend). */
export function background(p: Promise<unknown>) {
  const guarded = p.catch((e) => console.error("[background]", (e as Error)?.message ?? e));
  // deno-lint-ignore no-explicit-any
  const rt = (globalThis as any).EdgeRuntime;
  if (rt?.waitUntil) rt.waitUntil(guarded);
}
