const CURRENT_SCHEMA_VERSION = 2;

const BASE_SCHEMA = `
  CREATE TABLE IF NOT EXISTS app_meta (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS entries (
    id TEXT PRIMARY KEY,
    schema_version INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    occurred_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,
    title TEXT NOT NULL DEFAULT '',
    content TEXT NOT NULL DEFAULT '',
    content_text TEXT NOT NULL DEFAULT '',
    editor_type TEXT NOT NULL DEFAULT 'plain_text',
    mood REAL,
    mood_set INTEGER NOT NULL DEFAULT 0 CHECK (mood_set IN (0, 1)),
    category TEXT NOT NULL DEFAULT '生活',
    tags_json TEXT NOT NULL DEFAULT '[]',
    image_paths_json TEXT NOT NULL DEFAULT '[]',
    audio_paths_json TEXT NOT NULL DEFAULT '[]',
    video_paths_json TEXT NOT NULL DEFAULT '[]',
    weather_json TEXT NOT NULL DEFAULT '[]',
    positions_json TEXT NOT NULL DEFAULT '[]',
    latitude REAL,
    longitude REAL,
    color_value INTEGER NOT NULL DEFAULT 14869485,
    is_favorite INTEGER NOT NULL DEFAULT 0,
    revision INTEGER NOT NULL DEFAULT 1
  );

  CREATE INDEX IF NOT EXISTS idx_entries_occurred_at ON entries(occurred_at DESC);
  CREATE INDEX IF NOT EXISTS idx_entries_updated_at ON entries(updated_at DESC);
  CREATE INDEX IF NOT EXISTS idx_entries_deleted_at ON entries(deleted_at);
  CREATE INDEX IF NOT EXISTS idx_entries_category ON entries(category);

  CREATE TABLE IF NOT EXISTS attachments (
    id TEXT PRIMARY KEY,
    sha256 TEXT NOT NULL,
    kind TEXT NOT NULL,
    mime_type TEXT NOT NULL DEFAULT 'application/octet-stream',
    byte_size INTEGER NOT NULL DEFAULT 0,
    original_name TEXT NOT NULL DEFAULT '',
    relative_path TEXT NOT NULL,
    created_at TEXT NOT NULL,
    state TEXT NOT NULL DEFAULT 'ready' CHECK (state IN ('ready', 'missing', 'orphaned'))
  );
  CREATE UNIQUE INDEX IF NOT EXISTS idx_attachments_sha256 ON attachments(sha256);
  CREATE INDEX IF NOT EXISTS idx_attachments_state ON attachments(state);

  CREATE TABLE IF NOT EXISTS entry_attachments (
    entry_id TEXT NOT NULL,
    attachment_id TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    caption TEXT NOT NULL DEFAULT '',
    PRIMARY KEY (entry_id, attachment_id),
    FOREIGN KEY (entry_id) REFERENCES entries(id) ON DELETE CASCADE,
    FOREIGN KEY (attachment_id) REFERENCES attachments(id) ON DELETE RESTRICT
  );
  CREATE INDEX IF NOT EXISTS idx_entry_attachments_attachment ON entry_attachments(attachment_id);

  CREATE VIRTUAL TABLE IF NOT EXISTS entry_search USING fts5(
    id UNINDEXED,
    body,
    tokenize = 'trigram'
  );

  CREATE TABLE IF NOT EXISTS drafts (
    id TEXT PRIMARY KEY,
    entry_id TEXT,
    payload_json TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS outbox (
    mutation_id TEXT PRIMARY KEY,
    entry_id TEXT NOT NULL,
    payload_json TEXT NOT NULL,
    created_at TEXT NOT NULL,
    retry_count INTEGER NOT NULL DEFAULT 0,
    next_retry_at TEXT
  );
  CREATE INDEX IF NOT EXISTS idx_outbox_next_retry ON outbox(next_retry_at, created_at);

  CREATE TABLE IF NOT EXISTS sync_state (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value_json TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS migration_reports (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    report_json TEXT NOT NULL,
    created_at TEXT NOT NULL
  );
`;

function initializeDatabase(db) {
  db.exec('BEGIN IMMEDIATE;');
  try {
    db.exec(BASE_SCHEMA);
    const current = db.prepare("SELECT value FROM app_meta WHERE key = 'schema_version'").get();
    if (!current) {
      db.prepare("INSERT INTO app_meta(key, value) VALUES ('schema_version', ?)").run(String(CURRENT_SCHEMA_VERSION));
    } else if (Number(current.value) > CURRENT_SCHEMA_VERSION) {
      throw new Error(`Database schema ${current.value} is newer than supported schema ${CURRENT_SCHEMA_VERSION}`);
    } else if (Number(current.value) < CURRENT_SCHEMA_VERSION) {
      db.prepare("UPDATE app_meta SET value = ? WHERE key = 'schema_version'").run(String(CURRENT_SCHEMA_VERSION));
    }
    db.exec('COMMIT;');
  } catch (error) {
    try { db.exec('ROLLBACK;'); } catch { /* preserve the original migration error */ }
    throw error;
  }
  return CURRENT_SCHEMA_VERSION;
}

module.exports = { CURRENT_SCHEMA_VERSION, initializeDatabase };
