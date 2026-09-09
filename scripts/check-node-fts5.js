try {
  const { DatabaseSync } = require('node:sqlite');
  const db = new DatabaseSync(':memory:');
  db.exec('CREATE VIRTUAL TABLE codegraph_fts5_check USING fts5(content)');
  db.close();
} catch {
  process.exit(1);
}
