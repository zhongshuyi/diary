const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { performance } = require('node:perf_hooks');

const { openDatabase, closeDatabase } = require('../src/main/database/database.cjs');
const { initializeDatabase } = require('../src/main/database/migrations.cjs');
const { listEntries, searchEntries } = require('../src/main/database/repository.cjs');

const root = fs.mkdtempSync(path.join(os.tmpdir(), 'diary-db-benchmark-'));
const db = openDatabase(path.join(root, 'benchmark.sqlite'));

try {
  initializeDatabase(db);
  db.exec('BEGIN IMMEDIATE;');
  const insertEntry = db.prepare(`INSERT INTO entries(id, created_at, occurred_at, updated_at, title, content, content_text, category, tags_json, image_paths_json, audio_paths_json, video_paths_json, weather_json, positions_json) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`);
  const insertSearch = db.prepare('INSERT INTO entry_search(id, body) VALUES (?, ?)');
  for (let index = 0; index < 10000; index += 1) {
    const day = String(index % 28 + 1).padStart(2, '0');
    const id = `benchmark-${index}`;
    const content = index % 2 === 0 ? `工作记录 ${index}：今天看到了一段值得保存的句子` : `生活记录 ${index}：晚饭后散步和阅读`;
    const timestamp = `2026-09-${day}T08:00:00.000Z`;
    insertEntry.run(id, timestamp, timestamp, timestamp, '', content, content, index % 2 === 0 ? '工作' : '生活', '[]', '[]', '[]', '[]', '[]', '[]');
    insertSearch.run(id, content);
  }
  db.exec('COMMIT;');

  const listStart = performance.now();
  const page = listEntries(db, { limit: 50 });
  const listMs = performance.now() - listStart;
  const searchStart = performance.now();
  const results = searchEntries(db, '值得保存');
  const searchMs = performance.now() - searchStart;
  console.log(JSON.stringify({ entries: 10000, pageSize: page.length, searchResults: results.length, listMs: Number(listMs.toFixed(2)), searchMs: Number(searchMs.toFixed(2)) }, null, 2));
} finally {
  closeDatabase(db);
  fs.rmSync(root, { recursive: true, force: true });
}
