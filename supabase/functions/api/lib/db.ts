// Postgres access for the api function.
//
// Connects with SUPABASE_DB_URL (injected by the Edge Runtime). Authorization
// is enforced in the route handlers — exactly where the old Express backend
// enforced it — and RLS remains active for every direct client connection.
import postgres from "npm:postgres@3.4.5";

const dbUrl = Deno.env.get("SUPABASE_DB_URL");
if (!dbUrl) throw new Error("SUPABASE_DB_URL is not available");

export const sql = postgres(dbUrl, {
  prepare: false, // required for the transaction-mode pooler
  max: 4,
  idle_timeout: 20,
  connect_timeout: 10,
  // Return numbers, not strings, for bigint (count(*)) and numeric columns —
  // the Flutter client casts these with `as num` / `as double`.
  types: {
    bigint: { to: 20, from: [20], serialize: (x: unknown) => String(x), parse: (x: string) => Number(x) },
    numeric: { to: 1700, from: [1700], serialize: (x: unknown) => String(x), parse: (x: string) => Number(x) },
    // keep DATE columns as plain 'YYYY-MM-DD' strings (no timezone shifting)
    date: { to: 1082, from: [1082], serialize: (x: unknown) => String(x), parse: (x: string) => x },
  },
});

export type Row = Record<string, any>;
type Executor = { unsafe: typeof sql.unsafe };

/** Run a parameterised query ($1, $2 …) and return plain row objects. */
export async function q(text: string, params: unknown[] = [], ex: Executor = sql): Promise<Row[]> {
  const rows = await ex.unsafe(text, params as any[]);
  return Array.from(rows as unknown as Row[]);
}

/** First row or null. */
export async function q1(text: string, params: unknown[] = [], ex: Executor = sql): Promise<Row | null> {
  const rows = await q(text, params, ex);
  return rows[0] ?? null;
}

/** Number of rows touched by an UPDATE/DELETE. */
export async function exec(text: string, params: unknown[] = [], ex: Executor = sql): Promise<number> {
  const res = await ex.unsafe(text, params as any[]);
  return (res as unknown as { count: number }).count ?? 0;
}

export function tx<T>(fn: (t: Executor) => Promise<T>): Promise<T> {
  return sql.begin((t) => fn(t as unknown as Executor)) as Promise<T>;
}

/** Postgres unique_violation */
export const isUniqueViolation = (e: unknown) => (e as { code?: string })?.code === "23505";
/** Postgres foreign_key_violation */
export const isFkViolation = (e: unknown) => (e as { code?: string })?.code === "23503";
