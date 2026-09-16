const { withTransaction, writeEntryRecord } = require('./repository.cjs');

function importLegacyData(db, legacy = {}, { prepareEntryAssets } = {}) {
  const entries = Array.isArray(legacy.entries) ? legacy.entries : [];
  const outbox = Array.isArray(legacy.outbox) ? legacy.outbox : [];
  const settings = legacy.settings && typeof legacy.settings === 'object' ? legacy.settings : {};
  const deviceId = typeof legacy.deviceId === 'string' && legacy.deviceId ? legacy.deviceId : 'desktop';
  const cursor = legacy.cursor === undefined || legacy.cursor === null ? '0' : String(legacy.cursor);

  return withTransaction(db, () => {
    let importedEntries = 0;
    for (const entry of entries) {
      const prepared = typeof prepareEntryAssets === 'function' ? prepareEntryAssets(entry) : { entry, assets: undefined };
      writeEntryRecord(db, prepared.entry, { deviceId, enqueue: false, assets: prepared.assets });
      importedEntries += 1;
    }
    for (const mutation of outbox) {
      if (!mutation || typeof mutation.mutationId !== 'string' || !mutation.mutationId) throw new TypeError('Legacy mutation id is required');
      const entryId = mutation.entry?.id || mutation.entryId;
      if (typeof entryId !== 'string' || !entryId) throw new TypeError('Legacy mutation entry id is required');
      const payloadJson = JSON.stringify(mutation);
      db.prepare('INSERT OR REPLACE INTO outbox(mutation_id, entry_id, payload_json, created_at) VALUES (?, ?, ?, ?)').run(mutation.mutationId, entryId, payloadJson, new Date().toISOString());
    }
    db.prepare("INSERT OR REPLACE INTO sync_state(key, value) VALUES ('cursor', ?), ('device_id', ?)").run(cursor, deviceId);
    let importedSettings = 0;
    for (const [key, value] of Object.entries(settings)) {
      const valueJson = JSON.stringify(value);
      db.prepare('INSERT OR REPLACE INTO settings(key, value_json, updated_at) VALUES (?, ?, ?)').run(key, valueJson, new Date().toISOString());
      importedSettings += 1;
    }
    const report = { entries: importedEntries, mutations: outbox.length, settings: importedSettings, skippedEntries: 0 };
    db.prepare('INSERT OR REPLACE INTO migration_reports(id, report_json, created_at) VALUES (1, ?, ?)').run(JSON.stringify(report), new Date().toISOString());
    db.prepare("INSERT OR REPLACE INTO app_meta(key, value) VALUES ('legacy_migration', 'completed')").run();
    return report;
  });
}

function readMigrationReport(db) {
  const row = db.prepare('SELECT report_json FROM migration_reports WHERE id = 1').get();
  return row ? JSON.parse(row.report_json) : null;
}

module.exports = { importLegacyData, readMigrationReport };
