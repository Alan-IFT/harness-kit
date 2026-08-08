/**
 * memory-sink — the storage boundary, and its default SQLite implementation.
 *
 * ## Why there is an interface here at all
 *
 * The record shape belongs to harness-kit; the backend does not. `rohitg00/agentmemory` was
 * surveyed as a candidate and cannot hold these records without loss: its `AGENT_ID` is
 * process-level (one process, one role) while this project runs one MCP process across seven
 * subagent roles; a `subagent_stop` observation carries an empty narrative and is dropped
 * outright when the search index is rebuilt; and there is no single write that carries a
 * verdict plus a constraint list plus evidence. So the schema is defined here and the backend
 * is a sink. `SqliteSink` is the default and is zero-dependency. Whether a second
 * implementation is ever worth its four resident ports is a question for after this baseline
 * produces numbers — not before.
 *
 * ## Freshness
 *
 * `search` and `recent` return only the highest-`seq` row of each `id` family. Older rows stay
 * in the table — auditable — and never reach a reader. The comparison is SQL `MAX`, for the
 * reason set out at length in `memory-seed.ts`'s `computeSeq`: no model is asked, ever, which
 * of two records is newer.
 *
 * ## Where the database lives
 *
 * `HARNESS_MEMORY_DB` → `$CLAUDE_PLUGIN_DATA/memory.db` → `<root>/.harness/state/memory.db`.
 * Never under `$CLAUDE_PLUGIN_ROOT`: that directory is version-scoped
 * (`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`) and a plugin update silently
 * moves it, taking the seeded memory with it. `resolveDbPath` refuses that path outright
 * rather than trusting the caller not to pass it.
 */

import * as fs from 'fs';
import * as path from 'path';
import { SeedKind, SeedRecord, estimateTokens } from './memory-seed';

export interface UpsertResult {
  inserted: number;
  updated: number;
  skipped: number;
}

export interface SearchOptions {
  limit?: number;
  kinds?: readonly SeedKind[];
  tokenBudget?: number;
}

export interface SearchResult {
  records: SeedRecord[];
  tokensUsed: number;
  tokensBudget: number;
  /** True when a record matched but did not fit the budget or the limit. */
  truncated: boolean;
}

export interface SinkStats {
  total: number;
  current: number;
  byKind: Record<string, number>;
}

export interface MemorySink {
  upsert(records: readonly SeedRecord[]): UpsertResult;
  search(query: string, opts?: SearchOptions): SearchResult;
  recent(kind: SeedKind | null, limit?: number): SeedRecord[];
  stats(): SinkStats;
  /** Drop rows whose id is absent from `keepIds`. Returns the number removed. */
  prune(keepIds: ReadonlySet<string>): number;
  close(): void;
}

export const DEFAULT_LIMIT = 10;
export const DEFAULT_TOKEN_BUDGET = 2000;

// ── node:sqlite, typed just enough ───────────────────────────────────────────
// @types/node@22 predates the module. Declaring the surface used here beats loosening the
// project's `strict` settings for one import.

interface SqliteStatement {
  run(...params: unknown[]): { changes: number | bigint; lastInsertRowid: number | bigint };
  get(...params: unknown[]): Record<string, unknown> | undefined;
  all(...params: unknown[]): Array<Record<string, unknown>>;
}
interface SqliteDatabase {
  exec(sql: string): void;
  prepare(sql: string): SqliteStatement;
  close(): void;
}
type SqliteCtor = new (location: string) => SqliteDatabase;

function loadSqlite(): SqliteCtor {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const mod = require('node:sqlite') as { DatabaseSync: SqliteCtor };
  return mod.DatabaseSync;
}

// ── db location ──────────────────────────────────────────────────────────────

export class MemoryDbPathError extends Error {}

export function resolveDbPath(root: string, env: NodeJS.ProcessEnv = process.env): string {
  const explicit = env['HARNESS_MEMORY_DB'];
  const data = env['CLAUDE_PLUGIN_DATA'];
  const chosen =
    explicit !== undefined && explicit !== ''
      ? path.resolve(explicit)
      : data !== undefined && data !== ''
        ? path.resolve(data, 'memory.db')
        : path.resolve(root, '.harness/state/memory.db');

  const pluginRoot = env['CLAUDE_PLUGIN_ROOT'];
  if (pluginRoot !== undefined && pluginRoot !== '') {
    const pr = path.resolve(pluginRoot);
    const rel = path.relative(pr, chosen);
    if (rel !== '' && !rel.startsWith('..') && !path.isAbsolute(rel)) {
      throw new MemoryDbPathError(
        `refusing to put memory.db inside CLAUDE_PLUGIN_ROOT (${pr}) — that directory is ` +
          `version-scoped and a plugin update discards it. Set HARNESS_MEMORY_DB or CLAUDE_PLUGIN_DATA.`,
      );
    }
  }
  return chosen;
}

// ── SQLite + FTS5 ────────────────────────────────────────────────────────────

/** Bump whenever `SCHEMA` changes in a way an existing database cannot silently carry. */
const SCHEMA_VERSION = 2;

const SCHEMA = `
CREATE TABLE IF NOT EXISTS records (
  rowid        INTEGER PRIMARY KEY,
  id           TEXT NOT NULL,
  seq          INTEGER NOT NULL,
  kind         TEXT NOT NULL,
  title        TEXT NOT NULL,
  body         TEXT NOT NULL,
  date         TEXT NOT NULL,
  source_task  TEXT NOT NULL,
  evidence     TEXT NOT NULL,
  tags         TEXT NOT NULL,
  content_hash TEXT NOT NULL,
  supersedes   TEXT,
  UNIQUE (id, seq)
);
CREATE INDEX IF NOT EXISTS records_seq  ON records (seq DESC);
CREATE INDEX IF NOT EXISTS records_kind ON records (kind);
CREATE INDEX IF NOT EXISTS records_hash ON records (content_hash);

-- Porter stemming is not optional here. Without it the code reviewer's opening question --
-- "which mistakes recur in this codebase reviews" -- returns ZERO rows against a corpus full
-- of "review", "recurring" and "mistake", because FTS5's default tokenizer matches whole words
-- only. Measured: one of the seven role questions in the S3 table found nothing at all.
CREATE VIRTUAL TABLE IF NOT EXISTS records_fts
  USING fts5 (title, body, tags, content='records', content_rowid='rowid',
              tokenize = 'porter unicode61');

CREATE TRIGGER IF NOT EXISTS records_ai AFTER INSERT ON records BEGIN
  INSERT INTO records_fts (rowid, title, body, tags)
  VALUES (new.rowid, new.title, new.body, new.tags);
END;
CREATE TRIGGER IF NOT EXISTS records_ad AFTER DELETE ON records BEGIN
  INSERT INTO records_fts (records_fts, rowid, title, body, tags)
  VALUES ('delete', old.rowid, old.title, old.body, old.tags);
END;
CREATE TRIGGER IF NOT EXISTS records_au AFTER UPDATE ON records BEGIN
  INSERT INTO records_fts (records_fts, rowid, title, body, tags)
  VALUES ('delete', old.rowid, old.title, old.body, old.tags);
  INSERT INTO records_fts (rowid, title, body, tags)
  VALUES (new.rowid, new.title, new.body, new.tags);
END;
`;

/** Only the newest row of each `id` family is visible to a reader. */
const CURRENT = 'r.seq = (SELECT MAX(r2.seq) FROM records r2 WHERE r2.id = r.id)';

const COLS = 'r.id, r.seq, r.kind, r.title, r.body, r.date, r.source_task, r.evidence, r.tags, r.content_hash, r.supersedes';

function rowToRecord(row: Record<string, unknown>): SeedRecord {
  const rec: SeedRecord = {
    id: String(row['id']),
    kind: String(row['kind']) as SeedKind,
    title: String(row['title']),
    body: String(row['body']),
    seq: Number(row['seq']),
    date: String(row['date']),
    sourceTask: String(row['source_task']),
    evidence: JSON.parse(String(row['evidence'] ?? '[]')) as string[],
    tags: JSON.parse(String(row['tags'] ?? '[]')) as string[],
    contentHash: String(row['content_hash']),
  };
  const sup = row['supersedes'];
  if (sup !== null && sup !== undefined) rec.supersedes = String(sup);
  return rec;
}

/**
 * Turn a natural-language question into an FTS5 MATCH expression.
 *
 * Terms are OR-ed, not AND-ed. An agent's opening question ("what did we decide about the
 * destructive-command guard?") shares few exact tokens with a record written months earlier;
 * AND returns nothing at all, while OR returns candidates that bm25 then ranks by how many
 * terms they carry. Every token is double-quoted so punctuation in the question cannot be
 * read as FTS5 syntax.
 */
export function toMatchQuery(query: string): string {
  const stop = new Set([
    'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'do', 'does', 'did', 'of', 'to', 'in',
    'on', 'for', 'and', 'or', 'it', 'this', 'that', 'what', 'which', 'who', 'how', 'why', 'we',
    'i', 'you', 'about', 'with', 'have', 'has', 'had', 'ever', 'any', 'been', 'before', 'here',
  ]);
  const tokens = (query.toLowerCase().match(/[a-z0-9_][a-z0-9_-]{1,}/g) ?? [])
    .filter((t) => !stop.has(t))
    .filter((t, i, a) => a.indexOf(t) === i)
    .slice(0, 12);
  if (tokens.length === 0) return '';
  return tokens.map((t) => `"${t}"`).join(' OR ');
}

export class SqliteSink implements MemorySink {
  private readonly db: SqliteDatabase;

  constructor(readonly dbPath: string) {
    if (dbPath !== ':memory:') {
      const dir = path.dirname(dbPath);
      fs.mkdirSync(dir, { recursive: true });
      // Self-ignoring state directory. `harness-init` ships no `.gitignore`, so without this a
      // seeded project gains a half-megabyte binary in `git status` that nothing told it to
      // expect. Written only when absent, so a project that ignores the path its own way keeps
      // its arrangement.
      const ignore = path.join(dir, '.gitignore');
      if (!fs.existsSync(ignore)) {
        try {
          fs.writeFileSync(ignore, '# Local agent state — derived, never committed.\n*\n', 'utf8');
        } catch {
          /* a read-only checkout is not a reason to fail the query */
        }
      }
    }
    const Ctor = loadSqlite();
    this.db = new Ctor(dbPath);
    this.db.exec('PRAGMA journal_mode = WAL;');
    this.db.exec(SCHEMA);
    this.migrate();
  }

  /**
   * `CREATE VIRTUAL TABLE IF NOT EXISTS` is a no-op against a database built by an older
   * version, so a tokenizer change would leave every existing install searching through the
   * old index while reporting success. The version stamp forces the rebuild.
   */
  private migrate(): void {
    const have = Number(this.db.prepare('PRAGMA user_version').get()?.['user_version'] ?? 0);
    if (have === SCHEMA_VERSION) return;
    this.db.exec('DROP TABLE IF EXISTS records_fts;');
    this.db.exec(SCHEMA);
    this.db.exec(
      `INSERT INTO records_fts (rowid, title, body, tags) SELECT rowid, title, body, tags FROM records;`,
    );
    this.db.exec(`PRAGMA user_version = ${SCHEMA_VERSION};`);
  }

  upsert(records: readonly SeedRecord[]): UpsertResult {
    let inserted = 0;
    let updated = 0;
    let skipped = 0;

    const existing = this.db.prepare(
      'SELECT rowid, seq, content_hash FROM records WHERE id = ? ORDER BY seq DESC',
    );
    const insert = this.db.prepare(
      `INSERT INTO records (id, seq, kind, title, body, date, source_task, evidence, tags, content_hash, supersedes)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    );
    const update = this.db.prepare(
      `UPDATE records SET kind = ?, title = ?, body = ?, date = ?, source_task = ?, evidence = ?,
                          tags = ?, content_hash = ?, supersedes = ? WHERE rowid = ?`,
    );

    this.db.exec('BEGIN');
    try {
      for (const rec of records) {
        const rows = existing.all(rec.id);
        if (rows.some((r) => String(r['content_hash']) === rec.contentHash)) {
          skipped += 1;
          continue;
        }
        const sameSeq = rows.find((r) => Number(r['seq']) === rec.seq);
        if (sameSeq !== undefined) {
          update.run(
            rec.kind, rec.title, rec.body, rec.date, rec.sourceTask,
            JSON.stringify(rec.evidence), JSON.stringify(rec.tags), rec.contentHash,
            rec.supersedes ?? null, Number(sameSeq['rowid']),
          );
          updated += 1;
          continue;
        }
        // A new seq for an id that already has rows supersedes the previous newest. Recorded
        // on the incoming row; the old row is left in place and simply stops being current.
        const prior = rows[0];
        const supersedes =
          rec.supersedes ?? (prior !== undefined && Number(prior['seq']) < rec.seq ? `${rec.id}@${Number(prior['seq'])}` : null);
        insert.run(
          rec.id, rec.seq, rec.kind, rec.title, rec.body, rec.date, rec.sourceTask,
          JSON.stringify(rec.evidence), JSON.stringify(rec.tags), rec.contentHash, supersedes,
        );
        inserted += 1;
      }
      this.db.exec('COMMIT');
    } catch (err) {
      this.db.exec('ROLLBACK');
      throw err;
    }

    return { inserted, updated, skipped };
  }

  search(query: string, opts: SearchOptions = {}): SearchResult {
    const limit = opts.limit ?? DEFAULT_LIMIT;
    const budget = opts.tokenBudget ?? DEFAULT_TOKEN_BUDGET;
    const match = toMatchQuery(query);
    if (match === '') return { records: [], tokensUsed: 0, tokensBudget: budget, truncated: false };

    const kinds = opts.kinds ?? [];
    const kindClause = kinds.length > 0 ? ` AND r.kind IN (${kinds.map(() => '?').join(',')})` : '';
    // Over-fetch so the budget packer has candidates to drop, and so `truncated` is honest.
    const sql =
      `SELECT ${COLS} FROM records_fts f JOIN records r ON r.rowid = f.rowid ` +
      `WHERE records_fts MATCH ? AND ${CURRENT}${kindClause} ` +
      `ORDER BY bm25(records_fts, 4.0, 1.0, 2.0), r.seq DESC LIMIT ?`;
    const rows = this.db.prepare(sql).all(match, ...kinds, limit * 4);

    const records: SeedRecord[] = [];
    let tokensUsed = 0;
    let truncated = false;
    for (const row of rows) {
      const rec = rowToRecord(row);
      const cost = estimateTokens(rec);
      // Whole records only. A half-record is worse than a missing one: it reads as complete.
      if (records.length >= limit || tokensUsed + cost > budget) {
        truncated = true;
        break;
      }
      records.push(rec);
      tokensUsed += cost;
    }
    if (rows.length > records.length) truncated = true;
    return { records, tokensUsed, tokensBudget: budget, truncated };
  }

  recent(kind: SeedKind | null, limit = DEFAULT_LIMIT): SeedRecord[] {
    const where = kind === null ? '' : ' AND r.kind = ?';
    const params: unknown[] = kind === null ? [] : [kind];
    const sql = `SELECT ${COLS} FROM records r WHERE ${CURRENT}${where} ORDER BY r.seq DESC, r.id LIMIT ?`;
    return this.db.prepare(sql).all(...params, limit).map(rowToRecord);
  }

  /**
   * Remove rows the harvester no longer produces.
   *
   * A re-seed after a parser change is otherwise additive: the records it stopped emitting stay
   * in the index and keep answering queries. That is how the very duplicate this project fixed
   * by near-dup collapse survived its own fix — the merged pair was gone from the harvest and
   * still in the database.
   *
   * Scoped to a caller-supplied keep-set rather than "everything not in this batch", so a later
   * writer of non-seed records (handoff cards) can prune its own rows without touching these.
   */
  prune(keepIds: ReadonlySet<string>): number {
    const ids = this.db.prepare('SELECT DISTINCT id FROM records').all().map((r) => String(r['id']));
    const gone = ids.filter((id) => !keepIds.has(id));
    if (gone.length === 0) return 0;
    const del = this.db.prepare('DELETE FROM records WHERE id = ?');
    this.db.exec('BEGIN');
    try {
      for (const id of gone) del.run(id);
      this.db.exec('COMMIT');
    } catch (err) {
      this.db.exec('ROLLBACK');
      throw err;
    }
    return gone.length;
  }

  stats(): SinkStats {
    const total = Number(this.db.prepare('SELECT COUNT(*) AS n FROM records').get()?.['n'] ?? 0);
    const current = Number(
      this.db.prepare(`SELECT COUNT(*) AS n FROM records r WHERE ${CURRENT}`).get()?.['n'] ?? 0,
    );
    const byKind: Record<string, number> = {};
    for (const row of this.db.prepare(
      `SELECT r.kind AS k, COUNT(*) AS n FROM records r WHERE ${CURRENT} GROUP BY r.kind ORDER BY r.kind`,
    ).all()) {
      byKind[String(row['k'])] = Number(row['n']);
    }
    return { total, current, byKind };
  }

  close(): void {
    // Fold the WAL back into the main file before releasing it. Without this a freshly seeded
    // database `stat`s at a few KB while the records sit in `memory.db-wal`, so every size
    // figure reported right after a seed is wrong by two orders of magnitude.
    try {
      this.db.exec('PRAGMA wal_checkpoint(TRUNCATE);');
    } catch {
      /* a read-only or in-memory database has nothing to checkpoint */
    }
    this.db.close();
  }
}
