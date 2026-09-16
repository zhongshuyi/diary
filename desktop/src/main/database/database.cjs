const { DatabaseSync } = require('node:sqlite');

function openDatabase(filename) {
  const db = new DatabaseSync(filename);
  db.exec('PRAGMA foreign_keys = ON; PRAGMA busy_timeout = 5000;');
  if (filename !== ':memory:') db.exec('PRAGMA journal_mode = WAL;');
  return db;
}

function closeDatabase(db) {
  if (db && typeof db.close === 'function') db.close();
}

module.exports = { openDatabase, closeDatabase };
